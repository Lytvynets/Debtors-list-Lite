

import SwiftUI


struct LedgerIllustration: View {
    let isActive: Bool

    private struct Row {
        let name: String
        let amount: String
        let isPositive: Bool
        let tilt: Double
    }

    private let rows: [Row] = [
        Row(name: "Anna K.", amount: "+ ₴1 200", isPositive: true, tilt: -2.5),
        Row(name: "Max", amount: "− €40", isPositive: false, tilt: 1.5),
        Row(name: "Leo", amount: "+ $75", isPositive: true, tilt: -1)
    ]

    var body: some View {
        VStack(spacing: 14) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: 12) {
                    AvatarView(name: row.name, size: 40)
                        .environment(\.colorScheme, .dark)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: row.name)
                            .font(.headline)
                        Text("Today")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                    Text(verbatim: row.amount)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(row.isPositive ? Color.owedToMeBright : Color.iOweBright)
                }
                .padding(14)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                )
                .rotationEffect(.degrees(isActive ? row.tilt : 0))
                .offset(x: isActive ? 0 : (index.isMultiple(of: 2) ? -60 : 60))
                .opacity(isActive ? 1 : 0)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.75).delay(Double(index) * 0.08),
                    value: isActive
                )
            }
        }
        .padding(.horizontal, 40)
        .accessibilityHidden(true)
    }
}


struct CurrenciesIllustration: View {
    let isActive: Bool

    private let symbols = ["₴", "€", "£", "zł", "¥", "₣", "kr", "A$"]
    private let radius: CGFloat = 122

    var body: some View {
        ZStack {
            ZStack {
                Circle()
                    .strokeBorder(.white.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                    .frame(width: radius * 2, height: radius * 2)

                ForEach(symbols.indices, id: \.self) { index in
                    let angle = CGFloat(index) / CGFloat(symbols.count) * 2 * .pi
                    Text(verbatim: symbols[index])
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .frame(width: 50, height: 50)
                        .background(.white.opacity(0.1), in: Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.16), lineWidth: 1))
                        .offset(x: cos(angle) * radius, y: sin(angle) * radius)
                        .scaleEffect(isActive ? 1 : 0.4)
                        .opacity(isActive ? 1 : 0)
                        .animation(
                            .spring(response: 0.55, dampingFraction: 0.7).delay(Double(index) * 0.04),
                            value: isActive
                        )
                }
            }
            .rotationEffect(.degrees(isActive ? 0 : -30))
            .animation(.spring(response: 0.9, dampingFraction: 0.8), value: isActive)

            VStack(spacing: 4) {
                Text("Total")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))
                Text(verbatim: "$1,240")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [.brandBright, .inkGlow], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .shadow(color: Color.inkGlow.opacity(0.55), radius: 24, y: 10)
            .scaleEffect(isActive ? 1 : 0.8)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.15), value: isActive)
        }
        .accessibilityHidden(true)
    }
}


struct PrivacyIllustration: View {
    let isActive: Bool

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .strokeBorder(.white.opacity(0.09 - Double(ring) * 0.025), lineWidth: 1)
                    .frame(width: 150 + CGFloat(ring) * 64, height: 150 + CGFloat(ring) * 64)
                    .scaleEffect(isActive ? 1 : 0.7)
                    .animation(
                        .spring(response: 0.7, dampingFraction: 0.7).delay(Double(ring) * 0.07),
                        value: isActive
                    )
            }

            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(LinearGradient(colors: [.brandBright, .inkGlow], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 120, height: 120)
                .overlay {
                    Image(systemName: "faceid")
                        .font(.system(size: 56))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: isActive)
                }
                .shadow(color: Color.inkGlow.opacity(0.6), radius: 30, y: 12)

            chip(title: "No sign-up", systemImage: "person.crop.circle.badge.xmark")
                .offset(x: -64, y: -120)
            chip(title: "Stored on your device", systemImage: "lock.shield")
                .offset(x: 56, y: 120)
        }
        .accessibilityHidden(true)
    }

    private func chip(title: LocalizedStringKey, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.1), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.14), lineWidth: 1))
            .fixedSize()
            .opacity(isActive ? 1 : 0)
            .scaleEffect(isActive ? 1 : 0.85)
            .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.25), value: isActive)
    }
}


struct RemindersIllustration: View {
    let isActive: Bool

    private var sampleBody: String {
        let owedToMe = MoneyFormat.total(320, rounded: true)
        let iOwe = MoneyFormat.total(45, rounded: true)
        return String(localized: "Owed to you: \(owedToMe)\nYou owe: \(iOwe)")
    }

    private var scheduleText: String {
        let calendar = Calendar.current
        let monday = calendar.standaloneWeekdaySymbols[1]
        let time = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: .now) ?? .now
        return String(localized: "Weekly on \(monday) at \(time.formatted(date: .omitted, time: .shortened))")
    }

    var body: some View {
        VStack(spacing: 22) {
            ZStack(alignment: .top) {
                MockNotificationCard(title: String(localized: "Your debts"), message: sampleBody)
                    .scaleEffect(0.9)
                    .offset(y: -16)
                    .opacity(isActive ? 0.45 : 0)

                MockNotificationCard(title: String(localized: "Your debts"), message: sampleBody)
                    .offset(y: isActive ? 0 : 50)
                    .opacity(isActive ? 1 : 0)
            }
            .animation(.spring(response: 0.65, dampingFraction: 0.75), value: isActive)

            Label {
                Text(verbatim: scheduleText)
            } icon: {
                Image(systemName: "calendar")
            }
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.white.opacity(0.1), in: Capsule())
            .opacity(isActive ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.3), value: isActive)

            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(Color.premiumGold)
                Text("Premium feature")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.7))
            .opacity(isActive ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.4), value: isActive)
        }
        .padding(.horizontal, 32)
        .accessibilityHidden(true)
    }
}
