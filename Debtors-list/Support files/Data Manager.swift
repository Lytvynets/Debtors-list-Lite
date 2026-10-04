

import Foundation
import SwiftData
import RealmSwift


@MainActor
enum DataManager {
    private(set) static var isUsingFallbackStore = false

    static func makeModelContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: DebtRecord.self)
        } catch {
            print("⚠️ SwiftData: не вдалося відкрити сховище: \(error)")
            isUsingFallbackStore = true
            do {
                let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
                return try ModelContainer(for: DebtRecord.self, configurations: configuration)
            } catch {
                fatalError("SwiftData: не вдалося створити тимчасове сховище: \(error)")
            }
        }
    }
}


@MainActor
enum LegacyRealmMigrator {
    static func migrateIfNeeded(into context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: StorageKey.realmMigrated) else { return }

        let configuration = Realm.Configuration.defaultConfiguration
        guard let fileURL = configuration.fileURL,
              FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
            defaults.set(true, forKey: StorageKey.realmMigrated)
            return
        }

        do {
            let realm = try Realm(configuration: configuration)
            let legacyDebtors = realm.objects(Debtor.self)
            let now = Date()

            for (index, legacy) in legacyDebtors.enumerated() {
                let parsedDate = LegacyDateParser.parse(legacy.date)
                let orderedDate = (parsedDate ?? now).addingTimeInterval(Double(index))

                let record = DebtRecord(
                    firstName: legacy.name ?? "",
                    lastName: legacy.lastName ?? "",
                    amount: legacy.sum,
                    currencyCode: normalizedCurrency(legacy.currency),
                    isOwedToMe: legacy.givenDebt,
                    date: orderedDate,
                    legacyDateText: parsedDate == nil ? legacy.date : nil,
                    createdAt: orderedDate
                )
                context.insert(record)
            }

            try context.save()
            defaults.set(true, forKey: StorageKey.realmMigrated)
            print("✅ Перенесено записів з Realm: \(legacyDebtors.count)")
        } catch {
            context.rollback()
            print("⚠️ Перенесення з Realm не вдалося, повторимо при наступному запуску: \(error)")
        }
    }

    private static func normalizedCurrency(_ code: String?) -> String {
        let value = (code ?? "").trimmed.uppercased()
        return value.isEmpty ? CurrencyCode.usd.rawValue : value
    }
}


enum LegacyDateParser {
    static func parse(_ text: String?) -> Date? {
        guard let text = text?.trimmed, !text.isEmpty else { return nil }

        var identifiers = [Locale.current.identifier]
        identifiers += Locale.preferredLanguages
        identifiers += ["uk_UA", "en_US", "en_GB", "hi_IN", "ru_UA", "pl_PL", "de_DE"]

        var seen = Set<String>()
        let uniqueIdentifiers = identifiers.filter { seen.insert($0).inserted }

        for lenient in [false, true] {
            for identifier in uniqueIdentifiers {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: identifier)
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                formatter.isLenient = lenient
                if let date = formatter.date(from: text) {
                    return date
                }
            }
        }
        return nil
    }
}


enum SettingsMigration {
    static func runIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: StorageKey.settingsMigrated) else { return }

        if defaults.object(forKey: StorageKey.appearance) == nil,
           defaults.object(forKey: StorageKey.legacyDarkTheme) != nil {
            let mode: AppearanceMode = defaults.bool(forKey: StorageKey.legacyDarkTheme) ? .dark : .light
            defaults.set(mode.rawValue, forKey: StorageKey.appearance)
        }

        if defaults.object(forKey: StorageKey.remindersEnabled) == nil {
            let weekday = defaults.integer(forKey: StorageKey.reminderWeekday)
            let wasConfigured = defaults.bool(forKey: StorageKey.isPremium) && (1...7).contains(weekday)
            defaults.set(wasConfigured, forKey: StorageKey.remindersEnabled)
        }

        defaults.set(true, forKey: StorageKey.settingsMigrated)
    }
}
