

import SwiftUI
import SwiftData

struct EditDebtView: View {
    let record: DebtRecord
    var onSettle: (DebtRecord) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private enum Operation: Hashable {
        case add
        case subtract
    }

    @State private var operation: Operation = .subtract
    @State private var changeText = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isConfirmingSettle = false
    @FocusState private var isAmountFocused: Bool

    private var change: Double {
        AmountInput.value(from: changeText) ?? 0
    }

    private var newAmount: Double {
        operation == .add ? record.amount + change : record.amount - change
    }

    private var hasChanges: Bool {
        change > 0
            || (firstName.trimmed != record.firstName && !firstName.trimmed.isEmpty)
            || lastName.trimmed != record.lastName
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    header
                }
                .listRowBackground(Color.clear)

                Section {
                    Picker("Operation", selection: $operation) {
                        Text("Add").tag(Operation.add)
                        Text("Subtract").tag(Operation.subtract)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.appSurface)

                    HStack(spacing: 10) {
                        Text(verbatim: operation == .add ? "+" : "−")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: 22)
                        TextField("0", text: $changeText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .focused($isAmountFocused)
                            .accessibilityLabel(Text("Change amount"))
                        Text(verbatim: record.currencyCode)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color.appSurface)
                } header: {
                    Text("Change amount")
                } footer: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("New balance")
                            Spacer()
                            Text(verbatim: MoneyFormat.amount(newAmount, code: record.currencyCode))
                                .monospacedDigit()
                                .fontWeight(.semibold)
                                .contentTransition(.numericText(value: newAmount))
                                .animation(.snappy, value: newAmount)
                        }
                        if change > 0 && newAmount <= 0 {
                            Text("The balance will be zero or less. You can mark the debt as settled instead.")
                        }
                    }
                }

                Section("Who") {
                    TextField("First name", text: $firstName)
                        .textContentType(.givenName)
                        .textInputAutocapitalization(.words)
                        .listRowBackground(Color.appSurface)
                    TextField("Last name (optional)", text: $lastName)
                        .textContentType(.familyName)
                        .textInputAutocapitalization(.words)
                        .listRowBackground(Color.appSurface)
                }

                Section {
                    Button(role: .destructive) {
                        isConfirmingSettle = true
                    } label: {
                        Label("Mark as settled", systemImage: "checkmark.seal")
                    }
                    .listRowBackground(Color.appSurface)
                } footer: {
                    Text("The debt will be removed from the list.")
                }
            }
            .themedListBackground()
            .navigationTitle(record.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(!hasChanges)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isAmountFocused = false }
                }
            }
            .confirmationDialog(
                "Mark this debt as settled?",
                isPresented: $isConfirmingSettle,
                titleVisibility: .visible
            ) {
                Button("Mark as settled", role: .destructive) {
                    dismiss()
                    onSettle(record)
                }
                Button("Cancel", role: .cancel) {}
            }
            .onChange(of: changeText) { _, newValue in
                let sanitized = AmountInput.sanitize(newValue)
                if sanitized != newValue {
                    changeText = sanitized
                }
            }
            .sensoryFeedback(.selection, trigger: operation)
            .onAppear {
                firstName = record.firstName
                lastName = record.lastName
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            AvatarView(name: record.displayName, size: 64)
            Text(verbatim: MoneyFormat.signedAmount(record.signedAmount, code: record.currencyCode))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(record.signedAmount >= 0 ? Color.owedToMe : Color.iOwe)
            Group {
                if record.isOwedToMe {
                    Text("owes you")
                } else {
                    Text("you owe")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func save() {
        if change > 0 {
            record.amount = newAmount
            record.date = .now
        }
        let newFirstName = firstName.trimmed
        if !newFirstName.isEmpty {
            record.firstName = newFirstName
        }
        record.lastName = lastName.trimmed
        try? modelContext.save()
        dismiss()
    }
}
