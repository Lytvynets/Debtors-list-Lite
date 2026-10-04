
import SwiftUI
import SwiftData
import UIKit

struct ReminderSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(IAPManager.self) private var iap
    @Environment(CurrencyRateService.self) private var rates

    @AppStorage(StorageKey.remindersEnabled) private var remindersEnabled = false
    @AppStorage(StorageKey.reminderWeekday) private var weekday = ReminderScheduler.defaultWeekday
    @AppStorage(StorageKey.reminderHour) private var hour = ReminderScheduler.defaultHour
    @AppStorage(StorageKey.reminderMinute) private var minute = 0
    @AppStorage(StorageKey.roundTotals) private var roundTotals = false

    @Query private var records: [DebtRecord]

    @State private var isShowingPermissionAlert = false

    var body: some View {
        Form {
            Section {
                Toggle(isOn: enabledBinding) {
                    Label("Weekly reminder", systemImage: "bell.badge")
                }
                .listRowBackground(Color.appSurface)
            } footer: {
                Text("Once a week you'll get a notification with your current totals.")
            }

            if remindersEnabled {
                Section("Day") {
                    WeekdayPicker(selection: weekdayBinding)
                        .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                        .listRowBackground(Color.appSurface)
                }

                Section {
                    DatePicker("Time", selection: timeBinding, displayedComponents: .hourAndMinute)
                        .listRowBackground(Color.appSurface)
                }

                Section("Preview") {
                    MockNotificationCard(
                        title: String(localized: "Your debts"),
                        message: ReminderScheduler.bodyText(
                            for: DebtSummary(records: records, rates: rates.effectiveRates),
                            rounded: roundTotals
                        )
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.inkTop)
                }
            }
        }
        .themedListBackground()
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.default, value: remindersEnabled)
        .onChange(of: weekday) { reschedule() }
        .onChange(of: hour) { reschedule() }
        .onChange(of: minute) { reschedule() }
        .alert("Notifications are turned off", isPresented: $isShowingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow notifications for Debtors list in the Settings app to get reminders.")
        }
    }


    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { remindersEnabled },
            set: { newValue in
                if newValue {
                    Task {
                        if await ReminderScheduler.requestAuthorization() {
                            remindersEnabled = true
                            if !(1...7).contains(weekday) {
                                weekday = ReminderScheduler.defaultWeekday
                            }
                            reschedule()
                        } else {
                            isShowingPermissionAlert = true
                        }
                    }
                } else {
                    remindersEnabled = false
                    ReminderScheduler.cancel()
                }
            }
        )
    }

    private var weekdayBinding: Binding<Int> {
        Binding(
            get: { (1...7).contains(weekday) ? weekday : ReminderScheduler.defaultWeekday },
            set: { weekday = $0 }
        )
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                hour = components.hour ?? ReminderScheduler.defaultHour
                minute = components.minute ?? 0
                UserDefaults.standard.set(newValue, forKey: StorageKey.reminderDate)
            }
        )
    }

    private func reschedule() {
        let isPremium = iap.isPremium
        Task {
            await ReminderScheduler.reschedule(context: modelContext, rates: rates, isPremium: isPremium)
        }
    }
}


struct WeekdayPicker: View {
    @Binding var selection: Int

    private var orderedWeekdays: [Int] {
        let first = Calendar.current.firstWeekday
        return (0..<7).map { (first - 1 + $0) % 7 + 1 }
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(orderedWeekdays, id: \.self) { day in
                let isSelected = selection == day
                Button {
                    selection = day
                } label: {
                    Text(verbatim: Calendar.current.shortWeekdaySymbols[day - 1])
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .background(
                            isSelected ? Color.brand : Color.appFill,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: Calendar.current.standaloneWeekdaySymbols[day - 1]))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
        .animation(.snappy, value: selection)
    }
}
