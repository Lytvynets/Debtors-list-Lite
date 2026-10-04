

import Foundation
import SwiftData
import UserNotifications

@MainActor
enum ReminderScheduler {
    nonisolated static let identifier = "Local Notification"

    nonisolated static let defaultWeekday = 2
    nonisolated static let defaultHour = 18


    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        @unknown default:
            return false
        }
    }


    static func reschedule(context: ModelContext, rates: CurrencyRateService, isPremium: Bool) async {
        let defaults = UserDefaults.standard
        guard isPremium, defaults.bool(forKey: StorageKey.remindersEnabled) else {
            cancel()
            return
        }

        let records = (try? context.fetch(FetchDescriptor<DebtRecord>())) ?? []
        let summary = DebtSummary(records: records, rates: rates.effectiveRates)
        let rounded = defaults.bool(forKey: StorageKey.roundTotals)

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Your debts")
        content.body = bodyText(for: summary, rounded: rounded)
        content.sound = .default
        content.badge = 1

        var components = DateComponents()
        components.weekday = weekday
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("⚠️ Не вдалося запланувати нагадування: \(error)")
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    static func clearBadge() async {
        try? await UNUserNotificationCenter.current().setBadgeCount(0)
    }


    static func bodyText(for summary: DebtSummary, rounded: Bool) -> String {
        let owedToMe = MoneyFormat.total(summary.owedToMe, rounded: rounded)
        let iOwe = MoneyFormat.total(summary.iOwe, rounded: rounded)
        return String(localized: "Owed to you: \(owedToMe)\nYou owe: \(iOwe)")
    }

    static var weekday: Int {
        let value = UserDefaults.standard.integer(forKey: StorageKey.reminderWeekday)
        return (1...7).contains(value) ? value : defaultWeekday
    }

    static var hour: Int {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: StorageKey.reminderHour) != nil else { return defaultHour }
        return min(max(defaults.integer(forKey: StorageKey.reminderHour), 0), 23)
    }

    static var minute: Int {
        min(max(UserDefaults.standard.integer(forKey: StorageKey.reminderMinute), 0), 59)
    }

    static var scheduleDescription: String {
        let calendar = Calendar.current
        let dayName = calendar.standaloneWeekdaySymbols[weekday - 1]
        let time = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
        return "\(dayName), \(time.formatted(date: .omitted, time: .shortened))"
    }
}
