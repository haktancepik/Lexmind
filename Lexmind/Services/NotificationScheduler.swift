//
//  NotificationScheduler.swift
//  Lexmind
//
//  Thin wrapper around `UNUserNotificationCenter` for the local daily
//  review reminder. Two important constraints from App Store guidelines:
//    • 5.4 / 5.5: the permission prompt must be tied to a user action,
//      not surfaced at launch. We never call `requestAuthorization()`
//      until the Settings toggle is flipped on.
//    • Notifications are only useful if they fire at the user's chosen
//      hour — we schedule a single repeating `UNCalendarNotificationTrigger`
//      and overwrite it whenever the time changes.
//

import Foundation
import UserNotifications
import os

@MainActor
enum NotificationScheduler {

    /// Stable identifier for the repeating daily reminder. Using a
    /// single ID means rescheduling automatically replaces the old
    /// pending request — no manual cancel needed before re-add.
    static let dailyReminderID = "daily-review-reminder"

    // MARK: - Authorization

    enum AuthorizationResult {
        case granted
        case denied
        case notDetermined
    }

    static func currentAuthorizationStatus() async -> AuthorizationResult {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .granted
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    /// Surfaces the system prompt if and only if the user hasn't already
    /// answered it. Returns `true` if the app may now post notifications.
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            Log.app.info("Notification authorization request — granted: \(granted)")
            return granted
        } catch {
            Log.app.error("Notification authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Scheduling

    /// Replaces any existing daily reminder with one that fires at the
    /// given hour/minute every day. The trigger repeats indefinitely
    /// until cancelled or the app is uninstalled.
    static func scheduleDailyReminder(hour: Int, minute: Int) async {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Bugünün kelime tekrarı seni bekliyor")
        content.body = String(localized: "FSRS algoritması bu kelimeleri tam şimdi tekrar etmeni öneriyor.")
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: dailyReminderID,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            Log.app.info("Daily reminder scheduled for \(hour):\(String(format: "%02d", minute))")
        } catch {
            Log.app.error("Daily reminder schedule failed: \(error.localizedDescription)")
        }
    }

    static func cancelDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyReminderID])
        Log.app.info("Daily reminder cancelled")
    }
}
