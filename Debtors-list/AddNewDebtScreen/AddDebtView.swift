

import SwiftUI
import SwiftData

struct AddDebtView: View {
    var onSave: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @AppStorage(StorageKey.lastCurrency) private var lastCurrencyRaw = CurrencyCode.usd.rawValue

    @State private var amountText = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isOwedToMe = true
    @State private var currency: CurrencyCode = .usd

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case amount
        case firstName
        case lastName
    }

    private var amount: Double? {
        AmountInput.value(from: amountText)
    }

    private var canSave: Bool {
        (amount ?? 0) > 0 && !firstName.trimmed.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(alignment: .center, spacing: 12) {
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(isOwedToMe ? Color.owedToMe : Color.iOwe)
                            .minimumScaleFactor(0.5)
                            .focused($focusedField, equals: .amount)
                            .accessibilityLabel(Text("Amount"))
                        CurrencyMenu(selection: $currency)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.appSurface)

                    Picker("Direction", selection: $isOwedToMe) {
                        Text("I lent").tag(true)
                        Text("I borrowed").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.appSurface)
                } footer: {
                    if isOwedToMe {
                        Text("They owe you this amount.")
                    } else {
                        Text("You owe them this amount.")
                    }
                }

                Section("Who") {
                    TextField("First name", text: $firstName)
                        .textContentType(.givenName)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .firstName)
                        .onSubmit { focusedField = .lastName }
                        .listRowBackground(Color.appSurface)
                    TextField("Last name (optional)", text: $lastName)
                        .textContentType(.familyName)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($focusedField, equals: .lastName)
                        .onSubmit { focusedField = nil }
                        .listRowBackground(Color.appSurface)
                }
            }
            .themedListBackground()
            .navigationTitle("New debt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .onChange(of: amountText) { _, newValue in
                let sanitized = AmountInput.sanitize(newValue)
                if sanitized != newValue {
                    amountText = sanitized
                }
            }
            .sensoryFeedback(.selection, trigger: isOwedToMe)
            .task {
                currency = CurrencyCode(rawValue: lastCurrencyRaw) ?? .usd
                try? await Task.sleep(for: .milliseconds(450))
                focusedField = .amount
            }
        }
    }

    private func save() {
        guard let value = amount, value > 0, !firstName.trimmed.isEmpty else { return }

        let record = DebtRecord(
            firstName: firstName.trimmed,
            lastName: lastName.trimmed,
            amount: value,
            currencyCode: currency.rawValue,
            isOwedToMe: isOwedToMe
        )
        modelContext.insert(record)
        try? modelContext.save()

        lastCurrencyRaw = currency.rawValue
        onSave()
        dismiss()
    }
}
