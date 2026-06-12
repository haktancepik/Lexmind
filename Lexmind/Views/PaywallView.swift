//
//  PaywallView.swift
//  Lexmind
//
//  Sheet shown when a feature is gated behind Lexmind Pro. Loads the
//  monthly + yearly subscriptions from `EntitlementsService` and lets
//  the user purchase or restore. Until App Store Connect publishes the
//  products, `products` is empty and the sheet shows a graceful
//  "Aboneliklere şu an erişilemiyor" message — kept this way on purpose
//  so a missing App Store Connect setup doesn't crash the gate flow.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var entitlements: EntitlementsService

    @State private var selectedProductID: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    valueProps
                    planList
                    purchaseButton
                    restoreLink
                    legalLinks
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Lexmind Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
            .task { await entitlements.bootstrap() }
            .onChange(of: entitlements.isPro) { _, newValue in
                if newValue { dismiss() }
            }
            .alert("Satın alma başarısız", isPresented: .constant(entitlements.lastError != nil)) {
                Button("Tamam") { entitlements.lastError = nil }
            } message: {
                Text(entitlements.lastError ?? "")
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(colors: [.purple, .pink],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .padding(.top, 24)
            Text("Lexmind Pro")
                .font(.largeTitle.bold())
            Text("Sınırlama yok, full FSRS gücü ve cihazlar arası yedek.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var valueProps: some View {
        VStack(alignment: .leading, spacing: 12) {
            propRow(icon: "infinity", title: "Sınırsız kelime",
                    detail: "100 kelime sınırı kalkar; istediğin kadar büyüt")
            propRow(icon: "book.pages.fill", title: "Sınırsız okuma metni",
                    detail: "Günlük 1 metin sınırı yerine istediğin kadar tetikle")
            propRow(icon: "icloud.fill", title: "Cihazlar arası yedek",
                    detail: "iPad / iPhone arası senkronizasyon (Faz 2.1)")
            propRow(icon: "heart.fill", title: "Bağımsız geliştirici desteği",
                    detail: "Reklamsız, takipsiz; tek başına geliştirilen bir app'i destekle")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    private func propRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var planList: some View {
        if entitlements.products.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text("Aboneliklere şu an erişilemiyor")
                    .font(.subheadline.bold())
                Text("Bağlantı veya hesap durumunu kontrol edip tekrar dene. Aboneliği App Store'dan dilediğin zaman iptal edebilirsin.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.regularMaterial)
            )
        } else {
            VStack(spacing: 10) {
                ForEach(entitlements.products, id: \.id) { product in
                    planCard(for: product)
                }
            }
        }
    }

    private func planCard(for product: Product) -> some View {
        let isSelected = selectedProductID == product.id
        return Button {
            selectedProductID = product.id
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                    if !product.description.isEmpty {
                        Text(product.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.headline)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.14) : Color(.tertiarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(Text("\(product.displayName), \(product.displayPrice)"))
        .accessibilityHint(Text("Satın almak için bu planı seç"))
    }

    @ViewBuilder
    private var purchaseButton: some View {
        if let product = currentlySelectedProduct {
            Button {
                Task {
                    let result = await entitlements.purchase(product)
                    if case .purchased = result { dismiss() }
                }
            } label: {
                HStack(spacing: 8) {
                    if entitlements.isProcessing { ProgressView() }
                    Text(entitlements.isProcessing ? "İşleniyor…" : "Satın Al")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(entitlements.isProcessing)
            .accessibilityHint(Text("\(product.displayName) planını başlatır"))
        }
    }

    private var restoreLink: some View {
        Button("Satın alımları geri yükle") {
            Task { await entitlements.restore() }
        }
        .font(.subheadline)
        .disabled(entitlements.isProcessing)
        .accessibilityHint(Text("Daha önce başka bir cihazda alınan aboneliği bu Apple ID için aktive eder"))
    }

    private var legalLinks: some View {
        HStack(spacing: 16) {
            Link("Gizlilik", destination: URL(string: "https://haktancepik.github.io/Lexmind/privacy")!)
            Link("Koşullar", destination: URL(string: "https://haktancepik.github.io/Lexmind/terms")!)
        }
        .font(.caption)
    }

    // MARK: - Derived

    private var currentlySelectedProduct: Product? {
        guard let id = selectedProductID else {
            return entitlements.products.last  // default to yearly
        }
        return entitlements.products.first(where: { $0.id == id })
    }
}

#Preview {
    PaywallView(entitlements: EntitlementsService())
}
