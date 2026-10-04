
import SwiftUI
import StoreKit

struct PremiumVersionPaywall: View {
    enum Source {
        case onboarding
        case main
        case settings
        case periodic
    }

    let source: Source
    var onClose: () -> Void

    @Environment(IAPManager.self) private var iap
    @Environment(\.purchase) private var purchase

    @State private var appeared = false
    @State private var showCloseButton = false
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var didUnlock = false
    @State private var errorMessage: String?
    @State private var infoMessage: String?

    var body: some View {
        ZStack {
            InkBackground()

            ScrollView {
                content
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                purchaseBar
            }
            .padding(.bottom)

            closeButton

            if didUnlock {
                unlockedOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(2)
            }
        }
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
        .sensoryFeedback(.success, trigger: didUnlock)
        .task {
            await iap.loadProduct()
        }
        .task {
            if source == .onboarding || source == .periodic {
                try? await Task.sleep(for: .seconds(1))
            }
            withAnimation(.easeOut(duration: 0.3)) { showCloseButton = true }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { appeared = true }
        }
        .onChange(of: iap.isPremium) { _, isPremium in
            if isPremium { celebrateAndClose() }
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(verbatim: errorMessage ?? "")
        }
        .alert(
            "Debtors list Lite Premium",
            isPresented: Binding(get: { infoMessage != nil }, set: { if !$0 { infoMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(verbatim: infoMessage ?? "")
        }
    }


    private var content: some View {
        VStack(spacing: 28) {
            hero

            VStack(spacing: 16) {
                FeatureRow(
                    icon: "nosign",
                    tint: .iOweBright,
                    title: "No ads",
                    subtitle: "The banner and ad breaks disappear for good."
                )
                FeatureRow(
                    icon: "bell.badge.fill",
                    tint: .premiumGold,
                    title: "Weekly reminders",
                    subtitle: "Choose a day and time and get your totals in a notification."
                )
                FeatureRow(
                    icon: "infinity",
                    tint: .brandBright,
                    title: "Lifetime access",
                    subtitle: "Pay once. All future Premium features are included."
                )
                FeatureRow(
                    icon: "heart.fill",
                    tint: .owedToMeBright,
                    title: "Support an indie developer",
                    subtitle: "Your purchase keeps the app alive and updated."
                )
            }
            .padding(.horizontal, 4)

        }
        .padding(.horizontal, 22)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }

    private var sampleSummary: DebtSummary {
        var summary = DebtSummary()
        summary.owedToMe = 320
        summary.iOwe = 45
        return summary
    }

    private var hero: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.premiumGold.opacity(0.35), .clear],
                        center: .center,
                        startRadius: 6,
                        endRadius: 90
                    ))
                    .frame(width: 180, height: 180)

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(LinearGradient(colors: [.brandBright, .inkGlow], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 96, height: 96)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: Color.inkGlow.opacity(0.6), radius: 26, y: 12)

                Image("promo")
                    .resizable()
                    .frame(width: 180, height: 180)
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .foregroundStyle(Color.premiumGold)
                    .symbolEffect(.bounce, value: appeared)
            }
            .frame(height: 150)
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 10) {
                Text("Debtors list Lite Premium")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                Text("One payment. No subscription. Yours forever.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(.easeOut(duration: 0.5).delay(0.05), value: appeared)
        }
    }


    private var purchaseBar: some View {
        VStack(spacing: 12) {
            Button {
                Task { await buy() }
            } label: {
                ZStack {
                    if isPurchasing || (iap.product == nil && iap.isLoadingProduct) {
                        ProgressView()
                            .tint(.white)
                    } else if let product = iap.product {
                        Text("Unlock for \(product.displayPrice)")
                    } else {
                        Text("Try again")
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isPurchasing || isRestoring || (iap.product == nil && iap.isLoadingProduct))

            HStack(spacing: 20) {
                Button("Restore") {
                    Task { await restore() }
                }
                .disabled(isPurchasing || isRestoring)
                Link("Terms of Use", destination: AppInfo.termsOfUseURL)
                Link("Privacy Policy", destination: AppInfo.privacyPolicyURL)
            }
            .font(.footnote.weight(.medium))
            .tint(.white.opacity(0.75))
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                colors: [Color.inkBottom.opacity(0), Color.inkBottom.opacity(0.92), Color.inkBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.12), in: Circle())
                }
                .accessibilityLabel(Text("Close"))
                .opacity(showCloseButton ? 1 : 0)
                .disabled(!showCloseButton || isPurchasing)
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var unlockedOverlay: some View {
        ZStack {
            Color.inkBottom.opacity(0.85)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.premiumGold)
                    .symbolEffect(.bounce, value: didUnlock)
                Text("Premium unlocked")
                    .font(.system(.title, design: .rounded, weight: .bold))
                Text("Thank you for supporting Debtors list!")
                    .foregroundStyle(.white.opacity(0.7))
            }
            .multilineTextAlignment(.center)
            .padding(32)
        }
    }


    private func buy() async {
        guard let product = iap.product else {
            await iap.loadProduct(forceReload: true)
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await purchase(product)
            switch await iap.handle(purchaseResult: result) {
            case .purchased, .cancelled:
                break
            case .pending:
                infoMessage = String(localized: "Your purchase is waiting for approval. Premium will turn on automatically.")
            case .failed:
                errorMessage = String(localized: "The purchase couldn't be verified. Please try again.")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }

        let restored = await iap.restorePurchases()
        if !restored {
            infoMessage = String(localized: "No previous purchase was found for this Apple Account.")
        }
    }

    private func celebrateAndClose() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            didUnlock = true
        }
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            onClose()
        }
    }
}


private struct FeatureRow: View {
    let icon: String
    let tint: Color
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}


private struct ComparisonRow: View {
    let title: LocalizedStringKey
    let free: Bool
    let premium: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.white.opacity(0.08))
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                mark(free, highlighted: false)
                    .frame(width: 64)
                mark(premium, highlighted: true)
                    .frame(width: 76)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
        }
    }

    @ViewBuilder
    private func mark(_ included: Bool, highlighted: Bool) -> some View {
        if included {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(highlighted ? Color.premiumGold : Color.white.opacity(0.55))
                .accessibilityLabel(Text("Included"))
        } else {
            Image(systemName: "minus")
                .foregroundStyle(.white.opacity(0.3))
                .accessibilityLabel(Text("Not included"))
        }
    }
}
