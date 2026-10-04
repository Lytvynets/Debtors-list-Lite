

import SwiftUI

struct DebtRowView: View {
    let record: DebtRecord

    private var signedAmount: Double {
        record.signedAmount
    }

    private var amountColor: Color {
        if signedAmount > 0 { return .owedToMe }
        if signedAmount < 0 { return .iOwe }
        return .secondary
    }

    private var dateText: String {
        record.legacyDateText ?? record.date.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(name: record.displayName)

            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: record.displayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(verbatim: dateText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text(verbatim: MoneyFormat.signedAmount(signedAmount, code: record.currencyCode))
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(amountColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                directionCaption
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var directionCaption: some View {
        if signedAmount > 0 {
            Text("owes you")
        } else if signedAmount < 0 {
            Text("you owe")
        } else {
            Text("settled")
        }
    }
}
