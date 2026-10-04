

import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    @Environment(IAPManager.self) private var iap

    @State private var selection = 0
    @State private var isShowingPaywall = false

    private let pages = OnboardingPage.all

    private var isLastPage: Bool {
        selection == pages.count - 1
    }

    var body: some View {
        ZStack {
            if isShowingPaywall {
                PremiumVersionPaywall(source: .onboarding, onClose: onFinish)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                pagesView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isShowingPaywall)
    }

    private var pagesView: some View {
        ZStack {
            InkBackground()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    if !isLastPage {
                        Button("Skip", action: finishPages)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .transition(.opacity)
                    }
                }
                .frame(height: 44)
                .padding(.horizontal, 24)
                .animation(.easeInOut(duration: 0.2), value: isLastPage)

                TabView(selection: $selection) {
                    ForEach(pages) { page in
                        OnboardingPageView(page: page, isActive: selection == page.id)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                PageIndicator(count: pages.count, current: selection)
                    .padding(.bottom, 24)

                Button(action: next) {
                    if isLastPage {
                        Text("Get started")
                    } else {
                        Text("Continue")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func next() {
        if isLastPage {
            finishPages()
        } else {
            withAnimation(.easeInOut) {
                selection += 1
            }
        }
    }

    private func finishPages() {
        if iap.isPremium {
            onFinish()
        } else {
            isShowingPaywall = true
        }
    }
}


struct OnboardingPage: Identifiable {
    enum Illustration {
        case ledger
        case currencies
        case privacy
        case reminders
    }

    let id: Int
    let illustration: Illustration
    let title: LocalizedStringResource
    let message: LocalizedStringResource

    static let all: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            illustration: .ledger,
            title: "Every debt in one list",
            message: "Add a debt in seconds and always know who owes you and whom you owe."
        ),
        OnboardingPage(
            id: 1,
            illustration: .currencies,
            title: "Any currency, one total",
            message: "Lend in hryvnias, borrow in euros. Totals are converted to dollars at current rates."
        ),
        OnboardingPage(
            id: 2,
            illustration: .privacy,
            title: "Private by default",
            message: "No sign-up. Your records stay on your device, and Face ID can lock the app."
        ),
        OnboardingPage(
            id: 3,
            illustration: .reminders,
            title: "A nudge every week",
            message: "Get a weekly summary of your debts so nothing slips your mind."
        )
    ]
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 8)

            illustration
                .frame(height: 300)
                .frame(maxWidth: .infinity)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(page.message)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            .opacity(isActive ? 1 : 0)
            .offset(y: isActive ? 0 : 12)
            .animation(.easeOut(duration: 0.45).delay(0.1), value: isActive)

            Spacer(minLength: 8)
        }
        .foregroundStyle(.white)
    }

    @ViewBuilder
    private var illustration: some View {
        switch page.illustration {
        case .ledger:
            LedgerIllustration(isActive: isActive)
        case .currencies:
            CurrenciesIllustration(isActive: isActive)
        case .privacy:
            PrivacyIllustration(isActive: isActive)
        case .reminders:
            RemindersIllustration(isActive: isActive)
        }
    }
}


struct PageIndicator: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.white : Color.white.opacity(0.25))
                    .frame(width: index == current ? 24 : 8, height: 8)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: current)
        .accessibilityHidden(true)
    }
}
