

import Foundation


enum StorageKey {
    static let isPremium = "isPremiumUser"
    static let legacyDarkTheme = "LightTheme"
    static let faceID = "idIsOn"
    static let roundTotals = "Round"
    static let reminderHour = "Hours"
    static let reminderMinute = "Minutes"
    static let reminderWeekday = "WeekDay"
    static let reminderDate = "saveDate"
    static let launchCount = "launchCount"

    static let appearance = "appearanceMode"
    static let remindersEnabled = "remindersEnabled"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let lastCurrency = "lastCurrency"
    static let appOpenCount = "appOpenCount"
    static let reviewRequestedVersion = "reviewRequestedVersion"
    static let settingsMigrated = "didMigrateSettings_v3"
    static let realmMigrated = "didMigrateFromRealm_v1"
    static let cachedRates = "cachedRatesToUSD"
    static let cachedRatesDate = "cachedRatesDate"
}


enum AppInfo {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    static let privacyPolicyURL = URL(string: "https://docs.google.com/document/d/11BUDsK9Spo-pKMe9JLObqZwTAj3oBscl/edit?usp=share_link&ouid=114599015370342281433&rtpof=true&sd=true")!
    static let termsOfUseURL = URL(string: "https://docs.google.com/document/d/1JyypEqk0m1lH-Gh65EcjbDYjURJK8RXA/edit?usp=share_link&ouid=114599015370342281433&rtpof=true&sd=true")!
    static let otherAppsURL = URL(string: "https://apps.apple.com/us/developer/vladyslav-lytvynets/id1660079103")!

    static let proAppStoreID = "6809227046"

    static var proAppURL: URL {
        if !proAppStoreID.isEmpty, let url = URL(string: "https://apps.apple.com/app/id\(proAppStoreID)") {
            return url
        }
        return otherAppsURL
    }
}


enum LaunchCounter {
    static func registerLaunch() {
        let defaults = UserDefaults.standard
        defaults.set(defaults.integer(forKey: StorageKey.appOpenCount) + 1, forKey: StorageKey.appOpenCount)

        let legacyCount = defaults.integer(forKey: StorageKey.launchCount)
        if legacyCount < 5 {
            defaults.set(legacyCount + 1, forKey: StorageKey.launchCount)
        }
    }

    static var appOpenCount: Int {
        UserDefaults.standard.integer(forKey: StorageKey.appOpenCount)
    }

    static var shouldRequestReview: Bool {
        let defaults = UserDefaults.standard
        guard defaults.integer(forKey: StorageKey.launchCount) >= 5 else { return false }
        return defaults.string(forKey: StorageKey.reviewRequestedVersion) != AppInfo.version
    }

    static func markReviewRequested() {
        UserDefaults.standard.set(AppInfo.version, forKey: StorageKey.reviewRequestedVersion)
    }
}


@MainActor
enum PaywallPolicy {
    static let everyNthLaunch = 3

    private static var shownThisSession = false

    static func shouldPresentThisSession() -> Bool {
        guard everyNthLaunch > 0, !shownThisSession else { return false }
        let count = LaunchCounter.appOpenCount
        return count > 1 && count % everyNthLaunch == 0
    }

    static func markShownThisSession() {
        shownThisSession = true
    }
}


enum AmountInput {
    static func sanitize(_ text: String) -> String {
        let separator = Locale.current.decimalSeparator ?? "."
        var result = ""
        var hasSeparator = false
        var fractionDigits = 0

        for character in text {
            if ("0"..."9").contains(character) {
                if hasSeparator {
                    guard fractionDigits < 2 else { continue }
                    fractionDigits += 1
                }
                result.append(character)
            } else if character == "," || character == "." {
                guard !hasSeparator else { continue }
                hasSeparator = true
                if result.isEmpty { result = "0" }
                result += separator
            }
        }
        return String(result.prefix(12))
    }

    static func value(from text: String) -> Double? {
        let normalized = text
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard let value = Double(normalized), value.isFinite else { return nil }
        return value
    }
}


enum MoneyFormat {
    static func total(_ value: Double, rounded: Bool) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(rounded ? 0 : 2)))
    }

    static func amount(_ value: Double, code: String) -> String {
        value.formatted(.currency(code: code).precision(.fractionLength(0...2)))
    }

    static func signedAmount(_ value: Double, code: String) -> String {
        let formatted = amount(abs(value), code: code)
        if value > 0 { return "+" + formatted }
        if value < 0 { return "−" + formatted }
        return formatted
    }
}


extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
