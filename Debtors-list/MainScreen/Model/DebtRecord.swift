
import Foundation
import SwiftData

@Model
final class DebtRecord {
    var firstName: String = ""
    var lastName: String = ""
    var amount: Double = 0
    var currencyCode: String = "USD"

    var isOwedToMe: Bool = true

    var date: Date = Date()

    var legacyDateText: String?

    var createdAt: Date = Date()

    init(
        firstName: String,
        lastName: String = "",
        amount: Double,
        currencyCode: String,
        isOwedToMe: Bool,
        date: Date = .now,
        legacyDateText: String? = nil,
        createdAt: Date = .now
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.amount = amount
        self.currencyCode = currencyCode
        self.isOwedToMe = isOwedToMe
        self.date = date
        self.legacyDateText = legacyDateText
        self.createdAt = createdAt
    }

    var fullName: String {
        [firstName.trimmed, lastName.trimmed]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var displayName: String {
        fullName.isEmpty ? String(localized: "No name") : fullName
    }

    var currency: CurrencyCode {
        CurrencyCode(rawValue: currencyCode) ?? .usd
    }

    var signedAmount: Double {
        isOwedToMe ? amount : -amount
    }
}
