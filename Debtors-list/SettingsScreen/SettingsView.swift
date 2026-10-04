

import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(IAPManager.self) private var iap
    @Environment(\.openURL) private var openURL

    @AppStorage(StorageKey.faceID) private var faceIDEnabled = false
    @AppStorage(StorageKey.roundTotals) private var roundTotals = false
    @AppStorage(StorageKey.appearance) private var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage(StorageKey.remindersEnabled) private var remindersEnabled = false

    @State private var rewardedAds = RewardedAdManager()
    @State private var isShowingPaywall = false
    @State private var isRestoring = false
    @State private var alertMessage: String?

    var body: some View {
        Form {
            premiumSection

            Section {
                if iap.isPremium {
                    NavigationLink {
                        ReminderSettingsView()
                    } label: {
                        LabeledContent {
                            if remindersEnabled {
                                Text(verbatim: ReminderScheduler.scheduleDescription)
                            } else {
                                Text("Off")
                            }
                        } label: {
                            Label("Weekly reminder", systemImage: "bell.badge")
                        }
                    }
                    .listRowBackground(Color.appSurface)
                } else {
                    Button {
                        isShowingPaywall = true
                    } label: {
                        LabeledContent {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(Color.premiumGold)
                        } label: {
                            Label("Weekly reminder", systemImage: "bell.badge")
                                .foregroundStyle(.primary)
                        }
                    }
                    .listRowBackground(Color.appSurface)
                }
            } header: {
                Text("Reminders")
            }

            Section {
                Toggle(isOn: faceIDBinding) {
                    Label(AppLock.settingsTitle, systemImage: AppLock.symbolName)
                }
                .listRowBackground(Color.appSurface)
                Toggle(isOn: $roundTotals) {
                    Label("Round totals", systemImage: "number")
                }
                .listRowBackground(Color.appSurface)
                Picker(selection: $appearanceRaw) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                } label: {
                    Label("Appearance", systemImage: "circle.lefthalf.filled")
                }
                .listRowBackground(Color.appSurface)
            } header: {
                Text("Privacy & display")
            }

            Section {
                Button(action: openLanguageSettings) {
                    LabeledContent {
                        HStack(spacing: 6) {
                            Text(verbatim: currentLanguageName)
                            Image(systemName: "arrow.up.forward")
                                .font(.footnote.weight(.semibold))
                        }
                        .foregroundStyle(.secondary)
                    } label: {
                        Label("Language", systemImage: "globe")
                            .foregroundStyle(.primary)
                    }
                }
                .listRowBackground(Color.appSurface)
            } footer: {
                Text("Choose the app language in iPhone Settings.")
            }

            Section {
                Link(destination: AppInfo.proAppURL) {
                    ProVersionRow()
                }
                .listRowBackground(Color.appSurface)
            } header: {
                Text("Pro version")
            }

            Section {
                if !iap.isPremium {
                    Button(action: watchAd) {
                        HStack {
                            Label("Watch an ad to support the project", systemImage: "play.rectangle")
                                .foregroundStyle(.primary)
                            Spacer()
                            if rewardedAds.isLoading {
                                ProgressView()
                            }
                        }
                    }
                    .listRowBackground(Color.appSurface)
                }
                Button {
                    Task { await restore() }
                } label: {
                    HStack {
                        Label("Restore purchases", systemImage: "arrow.clockwise")
                            .foregroundStyle(.primary)
                        Spacer()
                        if isRestoring {
                            ProgressView()
                        }
                    }
                }
                .disabled(isRestoring)
                .listRowBackground(Color.appSurface)
                Link(destination: AppInfo.otherAppsURL) {
                    Label("Other apps", systemImage: "square.grid.2x2")
                        .foregroundStyle(.primary)
                }
                .listRowBackground(Color.appSurface)
                Link(destination: AppInfo.privacyPolicyURL) {
                    Label("Privacy policy", systemImage: "hand.raised")
                        .foregroundStyle(.primary)
                }
                .listRowBackground(Color.appSurface)
            } header: {
                Text("Support")
            } footer: {
                VStack(spacing: 2) {
                    Text(verbatim: "Debtors list Light")
                        .fontWeight(.semibold)
                    Text("Version \(AppInfo.version) (\(AppInfo.build))")
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
            }
        }
        .scrollIndicators(.hidden)
        .themedListBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isShowingPaywall) {
            PremiumVersionPaywall(source: .settings) {
                isShowingPaywall = false
            }
        }
        .alert(
            "Debtors list",
            isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(verbatim: alertMessage ?? "")
        }
        .task {
            if !iap.isPremium {
                await rewardedAds.load()
            }
        }
    }


    @ViewBuilder
    private var premiumSection: some View {
        Section {
            if iap.isPremium {
                HStack(spacing: 14) {
                    Image(systemName: "crown.fill")
                        .font(.title2)
                        .foregroundStyle(Color.premiumGold)
                        .frame(width: 44, height: 44)
                        .background(Color.premiumGold.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Premium is active")
                            .font(.headline)
                        Text("Thank you for supporting Debtors list!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.appSurface)
            } else {
                Button {
                    isShowingPaywall = true
                } label: {
                    PremiumUpsellCard()
                }
                .buttonStyle(PressableButtonStyle())
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
    }


    private var faceIDBinding: Binding<Bool> {
        Binding(
            get: { faceIDEnabled },
            set: { newValue in
                if newValue {
                    Task {
                        if await AppLock.verifyOwner() {
                            faceIDEnabled = true
                        } else {
                            alertMessage = String(localized: "Couldn't turn on the lock. Make sure a passcode is set in the iPhone settings.")
                        }
                    }
                } else {
                    faceIDEnabled = false
                }
            }
        )
    }


    private var currentLanguageName: String {
        let code = Bundle.main.preferredLocalizations.first ?? "en"
        let name = Locale.current.localizedString(forLanguageCode: code) ?? code
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    
    private func openLanguageSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }


    private func watchAd() {
        let didShow = rewardedAds.show {
            alertMessage = String(localized: "Thank you for your support!")
        }
        if !didShow {
            alertMessage = String(localized: "The ad isn't ready yet. Please try again in a moment.")
            Task { await rewardedAds.load() }
        }
    }

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }

        if await iap.restorePurchases() {
            alertMessage = String(localized: "Premium has been restored.")
        } else {
            alertMessage = String(localized: "No previous purchase was found for this Apple Account.")
        }
    }
}


private struct ProVersionRow: View {
    var body: some View {
        HStack(spacing: 14) {

            Image("dlpro")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 75, height: 75)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "Debtors list Pro")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("The advanced version of Debtors list")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)

            Image(systemName: "arrow.up.forward.app")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.brand)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}


private struct PremiumUpsellCard: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "crown.fill")
                .font(.title2)
                .foregroundStyle(Color.premiumGold)
                .frame(width: 48, height: 48)
                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("Get Premium")
                    .font(.headline)
                Text("No ads and weekly reminders. One-time purchase.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.white.opacity(0.5))
        }
        .foregroundStyle(.white)
        .padding(16)
        .background {
            ZStack {
                LinearGradient(colors: [.inkTop, Color(hex: 0x2B1A6E)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle()
                    .fill(Color.inkGlow.opacity(0.5))
                    .frame(width: 160, height: 160)
                    .blur(radius: 50)
                    .offset(x: 110, y: -40)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .environment(\.colorScheme, .dark)
    }
}
