

import SwiftUI
import SwiftData

@main
struct DebtorsListApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var iap = IAPManager()
    @State private var rates = CurrencyRateService()
    @State private var appLock = AppLock()

    @AppStorage(StorageKey.appearance) private var appearanceRaw = AppearanceMode.system.rawValue

    private let modelContainer: ModelContainer

    init() {
        SettingsMigration.runIfNeeded()
        LaunchCounter.registerLaunch()

        let container = DataManager.makeModelContainer()
        modelContainer = container
        if !DataManager.isUsingFallbackStore {
            LegacyRealmMigrator.migrateIfNeeded(into: container.mainContext)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(iap)
                .environment(rates)
                .environment(appLock)
                .preferredColorScheme(AppearanceMode(rawValue: appearanceRaw)?.colorScheme)
                .fontDesign(.rounded)
                .tint(.brand)
        }
        .modelContainer(modelContainer)
    }
}
