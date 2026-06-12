//
//  EntitlementsService.swift
//  Lexmind
//
//  Source of truth for whether the user has an active Lexmind Pro
//  entitlement. Wraps StoreKit 2 — products + purchase + restore +
//  Transaction.updates listener — and exposes a single `isPro` flag
//  the rest of the app can read via SwiftUI environment.
//
//  Product IDs live in `ProductIDs` so the IDs entered in App Store
//  Connect appear in exactly one place. Until those products exist
//  upstream `loadProducts()` will simply return an empty array — every
//  call site treats that as "Pro inactive, paywall stays informational".
//

import Foundation
import StoreKit
import os

/// Where StoreKit product identifiers live. Match these EXACTLY when
/// creating subscriptions in App Store Connect.
enum ProductIDs {
    static let monthlySubscription = "com.lexmind.pro.monthly"
    static let yearlySubscription = "com.lexmind.pro.yearly"

    static var all: [String] {
        [monthlySubscription, yearlySubscription]
    }
}

@MainActor
@Observable
final class EntitlementsService {

    // MARK: - Observable state

    /// True if any non-revoked, non-expired Lexmind Pro entitlement is
    /// present on the current Apple ID. Drives the paywall, feature
    /// gates, and the Settings Pro badge.
    var isPro: Bool = false

    /// Subscription products fetched from the App Store. Empty until
    /// `loadProducts()` resolves successfully — UI should handle the
    /// empty case (show "Aboneliklere şu an erişilemiyor" placeholder).
    var products: [Product] = []

    /// Most recent purchase / restore error surfaced to the user.
    var lastError: String?

    /// True while a purchase or restore call is in flight, so the
    /// paywall can show a spinner without each call site tracking it.
    var isProcessing = false

    // MARK: - Private

    private var updatesTask: Task<Void, Never>?

    // MARK: - Init / lifecycle

    init() {
        // Kick off the long-running transaction listener immediately so
        // we don't miss out-of-band entitlement changes (renewals,
        // family-sharing grants, refunds).
        updatesTask = Task { [weak self] in
            await self?.observeTransactionUpdates()
        }
    }

    // No explicit deinit cancel — the listener captures `self` weakly,
    // and the service lives for the entire app lifetime anyway.

    /// Called once from app launch — kicks off product fetch + initial
    /// entitlement check.
    func bootstrap() async {
        await loadProducts()
        await refreshEntitlements()
    }

    // MARK: - Products

    func loadProducts() async {
        do {
            let fetched = try await Product.products(for: ProductIDs.all)
            // Stable order: monthly first, then yearly.
            self.products = fetched.sorted { lhs, rhs in
                let order: [String] = [
                    ProductIDs.monthlySubscription,
                    ProductIDs.yearlySubscription
                ]
                return (order.firstIndex(of: lhs.id) ?? .max)
                    < (order.firstIndex(of: rhs.id) ?? .max)
            }
            Log.app.info("StoreKit products loaded — \(self.products.count) found")
        } catch {
            Log.app.error("StoreKit loadProducts failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Entitlements

    /// Re-scans `Transaction.currentEntitlements` and updates `isPro`.
    /// Idempotent; call after purchase, restore, or app foreground.
    func refreshEntitlements() async {
        var pro = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if ProductIDs.all.contains(transaction.productID),
               transaction.revocationDate == nil {
                pro = true
                break
            }
        }
        if pro != isPro {
            Log.app.info("Pro entitlement changed → \(pro)")
        }
        isPro = pro
    }

    private func observeTransactionUpdates() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            await transaction.finish()
            await refreshEntitlements()
        }
    }

    // MARK: - Purchase / restore

    enum PurchaseOutcome {
        case purchased
        case userCancelled
        case pending
        case failed(String)
    }

    @discardableResult
    func purchase(_ product: Product) async -> PurchaseOutcome {
        isProcessing = true
        defer { isProcessing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    lastError = "İşlem doğrulanamadı."
                    return .failed("Doğrulama başarısız")
                }
                await transaction.finish()
                await refreshEntitlements()
                return .purchased
            case .userCancelled:
                return .userCancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed("Bilinmeyen sonuç")
            }
        } catch {
            Log.app.error("StoreKit purchase failed: \(error.localizedDescription)")
            lastError = error.localizedDescription
            return .failed(error.localizedDescription)
        }
    }

    func restore() async {
        isProcessing = true
        defer { isProcessing = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            Log.app.error("StoreKit restore failed: \(error.localizedDescription)")
            lastError = error.localizedDescription
        }
    }
}

// MARK: - Free tier policy

/// Centralised tunables for what a Free user can do. Production caps —
/// reviewer-visible and copy referenced in the paywall.
enum FreeTier {
    /// Cap on words a Free user can hold before the paywall fires.
    static let maxWords: Int = 100

    /// Cap on reading passages generated per day under Free.
    static let maxReadingPassagesPerDay: Int = 1

    static func wordCapReached(currentCount: Int) -> Bool {
        currentCount >= maxWords
    }
}
