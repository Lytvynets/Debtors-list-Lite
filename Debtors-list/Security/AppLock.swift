

import SwiftUI
import LocalAuthentication
import Observation

@MainActor
@Observable
final class AppLock {
    private(set) var isLocked: Bool
    private(set) var isAuthenticating = false

    init() {
        isLocked = UserDefaults.standard.bool(forKey: StorageKey.faceID)
    }

    private var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: StorageKey.faceID)
    }

    func lockIfNeeded() {
        if isEnabled {
            isLocked = true
        }
    }

    func unlock() async {
        guard isLocked, !isAuthenticating else { return }
        guard isEnabled else {
            isLocked = false
            return
        }

        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            isLocked = false
            return
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: String(localized: "Unlock to see your debts")
            )
            if success {
                isLocked = false
            }
        } catch {
        }
    }

    static func verifyOwner() async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { return false }
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: String(localized: "Confirm it's you to turn on the lock")
            )
        } catch {
            return false
        }
    }


    private static var biometryType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    static var settingsTitle: String {
        switch biometryType {
        case .faceID: return String(localized: "Lock with Face ID")
        case .touchID: return String(localized: "Lock with Touch ID")
        case .opticID: return String(localized: "Lock with Optic ID")
        case .none: return String(localized: "Lock with passcode")
        @unknown default: return String(localized: "Lock with passcode")
        }
    }

    static var unlockButtonTitle: String {
        switch biometryType {
        case .faceID: return String(localized: "Unlock with Face ID")
        case .touchID: return String(localized: "Unlock with Touch ID")
        case .opticID: return String(localized: "Unlock with Optic ID")
        case .none: return String(localized: "Unlock")
        @unknown default: return String(localized: "Unlock")
        }
    }

    static var symbolName: String {
        switch biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        case .none: return "lock.fill"
        @unknown default: return "lock.fill"
        }
    }
}


struct LockView: View {
    @Environment(AppLock.self) private var appLock

    var body: some View {
        ZStack {
            InkBackground()

            VStack(spacing: 20) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .frame(width: 92, height: 92)
                    .background(.white.opacity(0.08), in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.14), lineWidth: 1))

                VStack(spacing: 8) {
                    Text("Debtors list is locked")
                        .font(.title2.weight(.bold))
                    Text("Your records are hidden until you unlock the app.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await appLock.unlock() }
                } label: {
                    Label(AppLock.unlockButtonTitle, systemImage: AppLock.symbolName)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(appLock.isAuthenticating)
                .padding(.top, 12)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 36)
        }
        .environment(\.colorScheme, .dark)
        .task {
            await appLock.unlock()
        }
    }
}
