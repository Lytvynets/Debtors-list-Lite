

import SwiftUI

struct BalanceCardView: View {
    let summary: DebtSummary
    let roundTotals: Bool
    let isPremium: Bool
    let ratesUpdatedAt: Date?
    var onPremiumTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text("Net balance")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Button(action: onPremiumTap) {
                    PremiumBadge(isPremium: isPremium)
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(isPremium)
            }

            Text(verbatim: MoneyFormat.total(summary.net, rounded: roundTotals))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText(value: summary.net))
                .animation(.snappy, value: summary.net)

            BalanceBar(owedToMeShare: summary.owedToMeShare, isEmpty: summary.total == 0)

            HStack(spacing: 10) {
                stat(title: "Owed to you", value: summary.owedToMe, color: .owedToMeBright, icon: "arrow.down.left")
                stat(title: "You owe", value: summary.iOwe, color: .iOweBright, icon: "arrow.up.right")
            }

            ratesFootnote
        }
        .padding(20)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(LinearGradient(
                        colors: [.inkTop, Color(hex: 0x2B1A6E)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                Circle()
                    .fill(Color.inkGlow.opacity(0.45))
                    .frame(width: 220, height: 220)
                    .blur(radius: 70)
                    .offset(x: 120, y: -90)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .environment(\.colorScheme, .dark)
    }

    private func stat(title: LocalizedStringKey, value: Double, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: icon)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)

            Text(verbatim: MoneyFormat.total(value, rounded: roundTotals))
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText(value: value))
                .animation(.snappy, value: value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var ratesFootnote: some View {
        Group {
            if let ratesUpdatedAt {
                Text("Totals in US dollars. Rates updated \(ratesUpdatedAt.formatted(.relative(presentation: .named))).")
            } else {
                Text("Totals in US dollars at approximate rates.")
            }
        }
        .font(.caption)
        .foregroundStyle(.white.opacity(0.5))
    }
}


struct BalanceBar: View {
    let owedToMeShare: Double
    let isEmpty: Bool

    var body: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 3
            let available = max(proxy.size.width - spacing, 0)
            let greenWidth = min(max(available * owedToMeShare, 6), max(available - 6, 6))
            HStack(spacing: spacing) {
                Capsule()
                    .fill(Color.owedToMeBright)
                    .frame(width: greenWidth)
                Capsule()
                    .fill(Color.iOweBright)
            }
        }
        .frame(height: 8)
        .opacity(isEmpty ? 0.25 : 1)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: owedToMeShare)
        .accessibilityHidden(true)
    }
}
