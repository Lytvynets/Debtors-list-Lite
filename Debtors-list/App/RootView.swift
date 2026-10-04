

import SwiftUI
import SwiftData

struct RootView: View {
    enum Phase: Equatable {
        case splash
        case onboarding
        case main
    }

    @Environment(IAPManager.self) private var iap
    @Environment(CurrencyRateService.self) private var rates
    @Environment(AppLock.self) private var appLock
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    @AppStorage(StorageKey.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    @State private var phase: Phase = .splash
    @State private var showPeriodicPaywall = false
    @State private var isPaywallPending = false
    @State private var isReturningFromBackground = false

    var body: some View {
        ZStack {
            switch phase {
            case .splash:
                SplashView(onFinish: finishSplash)
                    .transition(.opacity)
            case .onboarding:
                OnboardingView(onFinish: finishOnboarding)
                    .transition(.opacity)
            case .main:
                MainView()
                    .transition(.opacity)
            }

            if phase == .main && appLock.isLocked {
                LockView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: phase)
        .animation(.easeInOut(duration: 0.3), value: appLock.isLocked)
        .fullScreenCover(isPresented: $showPeriodicPaywall) {
            PremiumVersionPaywall(source: .periodic) {
                showPeriodicPaywall = false
            }
        }
        .task {
            await iap.refreshEntitlements()
            await iap.loadProduct()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhase(newPhase)
        }
        .onChange(of: appLock.isLocked) { _, isLocked in
            if !isLocked {
                presentPendingPaywallIfPossible()
            }
        }
    }


    private func finishSplash() {
        if hasCompletedOnboarding {
            phase = .main
            requestPaywallForAppOpen()
        } else {
            phase = .onboarding
        }
    }

    private func finishOnboarding() {
        hasCompletedOnboarding = true
        phase = .main
    }


    private func requestPaywallForAppOpen() {
        guard !iap.isPremium, !showPeriodicPaywall else { return }
        isPaywallPending = true
        presentPendingPaywallIfPossible()
    }

    private func presentPendingPaywallIfPossible() {
        guard isPaywallPending, phase == .main, !appLock.isLocked else { return }
        isPaywallPending = false
        guard !iap.isPremium, !showPeriodicPaywall else { return }

        Task {
            try? await Task.sleep(for: .milliseconds(600))
            guard !iap.isPremium, !appLock.isLocked else { return }
            showPeriodicPaywall = true
        }
    }


    private func handleScenePhase(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            isReturningFromBackground = true
            appLock.lockIfNeeded()
            showPeriodicPaywall = false
            isPaywallPending = false
            let isPremium = iap.isPremium
            Task {
                await ReminderScheduler.reschedule(context: modelContext, rates: rates, isPremium: isPremium)
            }
        case .active:
            Task {
                await ReminderScheduler.clearBadge()
            }
   
            if isReturningFromBackground {
                isReturningFromBackground = false
                if phase == .main {
                    requestPaywallForAppOpen()
                    if appLock.isLocked {
                        Task { await appLock.unlock() }
                    }
                }
            }
        default:
            break
        }
    }
}
