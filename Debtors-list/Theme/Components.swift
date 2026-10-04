
import SwiftUI


struct InkBackground: View {
    var glowExpanded: Bool = true

    var body: some View {
        ZStack {
            LinearGradient(colors: [.inkTop, .inkBottom], startPoint: .top, endPoint: .bottom)

            Circle()
                .fill(Color.inkGlow.opacity(0.45))
                .frame(width: 360, height: 360)
                .blur(radius: 90)
                .scaleEffect(glowExpanded ? 1.15 : 0.85)
                .offset(x: 140, y: -260)

            Circle()
                .fill(Color.owedToMeBright.opacity(0.16))
                .frame(width: 320, height: 320)
                .blur(radius: 100)
                .scaleEffect(glowExpanded ? 1.1 : 0.8)
                .offset(x: -150, y: 320)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}


struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.05))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

struct RuledLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}


struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PrimaryButtonBody(configuration: configuration)
    }
}

private struct PrimaryButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(colors: [.brandBright, .inkGlow], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.55)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}


struct AvatarView: View {
    let name: String
    var size: CGFloat = 44

    var body: some View {
        let tint = Color.avatarTint(for: name)
        Text(verbatim: initials)
            .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.16), in: Circle())
            .accessibilityHidden(true)
    }

    private var initials: String {
        let words = name.split(separator: " ").prefix(2)
        let letters = words.compactMap { $0.first }.map { String($0).uppercased() }
        return letters.isEmpty ? "?" : letters.joined()
    }
}


struct PremiumBadge: View {
    let isPremium: Bool

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: isPremium ? "crown.fill" : "sparkles")
            if isPremium {
                Text("Premium")
            } else {
                Text("Go Premium")
            }
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(isPremium ? Color.premiumGold : Color.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isPremium ? Color.premiumGold.opacity(0.16) : Color.white.opacity(0.14), in: Capsule())
    }
}


struct AppGlyph: View {
    var size: CGFloat = 38

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
            .fill(LinearGradient(colors: [.brandBright, .inkGlow], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "list.bullet.rectangle.portrait.fill")
                    .font(.system(size: size * 0.46, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
    }
}


struct MockNotificationCard: View {
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image("3313123121")
                .resizable()
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .scaledToFit()
            
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(verbatim: "Debtors list")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("now")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
                Text(verbatim: title)
                    .font(.subheadline.weight(.semibold))
                Text(verbatim: message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(.white)
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .combine)
    }
}
