

import SwiftUI
import SwiftData
import StoreKit

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(IAPManager.self) private var iap
    @Environment(CurrencyRateService.self) private var rates
    @Environment(\.requestReview) private var requestReview

    @AppStorage(StorageKey.roundTotals) private var roundTotals = false

    @Query(sort: [
        SortDescriptor(\DebtRecord.date, order: .reverse),
        SortDescriptor(\DebtRecord.createdAt, order: .reverse)
    ])
    private var records: [DebtRecord]

    @State private var viewModel = MainViewModel()
    @State private var interstitialAds = InterstitialAdManager()
    @State private var didSaveNewDebt = false

    private var summary: DebtSummary {
        DebtSummary(records: records, rates: rates.effectiveRates)
    }

    private var usedCurrencyCodes: Set<String> {
        Set(records.map(\.currencyCode))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    BalanceCardView(
                        summary: summary,
                        roundTotals: roundTotals,
                        isPremium: iap.isPremium,
                        ratesUpdatedAt: rates.lastUpdated,
                        onPremiumTap: { viewModel.isShowingPaywall = true }
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                if !records.isEmpty {
                    Section {
                        DebtFilterBar(selection: $viewModel.filter)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                }

                debtsSection
            }
            .scrollIndicators(.hidden)
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .themedListBackground()
            .navigationTitle("Debts")
            .searchable(text: $viewModel.searchText, prompt: Text("Search by name"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .accessibilityLabel(Text("Settings"))
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomBar
            }
            .refreshable {
                await rates.refresh(codes: usedCurrencyCodes, force: true)
            }
        }
        .sheet(isPresented: $viewModel.isAddingDebt, onDismiss: showAdAfterAddingIfNeeded) {
            AddDebtView {
                didSaveNewDebt = true
            }
        }
        .sheet(item: $viewModel.editingRecord) { record in
            EditDebtView(record: record) { settledRecord in
                settle(settledRecord)
            }
        }
        .fullScreenCover(isPresented: $viewModel.isShowingPaywall) {
            PremiumVersionPaywall(source: .main) {
                viewModel.isShowingPaywall = false
            }
        }
        .confirmationDialog(
            Text("Delete this debt?"),
            isPresented: Binding(
                get: { viewModel.recordPendingDeletion != nil },
                set: { if !$0 { viewModel.recordPendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: viewModel.recordPendingDeletion
        ) { record in
            Button("Delete", role: .destructive) {
                delete(record)
            }
            Button("Cancel", role: .cancel) {}
        } message: { record in
            Text("\(record.displayName) will be removed from the list.")
        }
        .task(id: usedCurrencyCodes) {
            await rates.refresh(codes: usedCurrencyCodes)
        }
        .task {
            await requestReviewIfNeeded()
        }
        .task(id: iap.isPremium) {
            if !iap.isPremium {
                await interstitialAds.load()
            }
        }
        .sensoryFeedback(.success, trigger: records.count) { oldValue, newValue in
            newValue > oldValue
        }
        .sensoryFeedback(.selection, trigger: viewModel.filter)
    }


    @ViewBuilder
    private var debtsSection: some View {
        let visible = viewModel.visibleRecords(from: records)

        if records.isEmpty {
            Section {
                ContentUnavailableView {
                    Label("No debts yet", systemImage: "list.bullet.rectangle.portrait")
                } description: {
                    Text("Add who owes you and whom you owe. The totals will appear above.")
                } actions: {
                    Button("Add a debt") {
                        viewModel.isAddingDebt = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .listRowBackground(Color.clear)
            }
        } else if visible.isEmpty {
            Section {
                if viewModel.searchText.trimmed.isEmpty {
                    ContentUnavailableView(
                        "Nothing here yet",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("No debts match this filter.")
                    )
                } else {
                    ContentUnavailableView.search(text: viewModel.searchText)
                }
            }
            .listRowBackground(Color.clear)
        } else {
            Section {
                ForEach(visible) { record in
                    Button {
                        viewModel.editingRecord = record
                    } label: {
                        DebtRowView(record: record)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.editingRecord = record
                        } label: {
                            Label("Change amount", systemImage: "plusminus")
                        }
                        .tint(.brand)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            viewModel.recordPendingDeletion = record
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                    .contextMenu {
                        Button {
                            viewModel.editingRecord = record
                        } label: {
                            Label("Change amount", systemImage: "plusminus")
                        }
                        Button(role: .destructive) {
                            viewModel.recordPendingDeletion = record
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .listRowBackground(Color.appSurface)
                }
            } header: {
                Text("History")
            }
        }
    }


    private var bottomBar: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.isAddingDebt = true
            } label: {
                Label("New debt", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .frame(height: 54)
                    .background(Color.brand, in: Capsule())
                    .shadow(color: Color.brand.opacity(0.35), radius: 14, y: 6)
            }
            .buttonStyle(PressableButtonStyle())

            if !iap.isPremium {
                BannerAdView()
            }
        }
        .padding(.top, 8)
    }


    private func delete(_ record: DebtRecord) {
        withAnimation {
            modelContext.delete(record)
            try? modelContext.save()
        }
        viewModel.recordPendingDeletion = nil
    }


    private func settle(_ record: DebtRecord) {
        viewModel.editingRecord = nil
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation {
                modelContext.delete(record)
                try? modelContext.save()
            }
        }
    }


    private func showAdAfterAddingIfNeeded() {
        guard didSaveNewDebt else { return }
        didSaveNewDebt = false
        guard !iap.isPremium else { return }
        interstitialAds.debtWasAdded()
    }

    private func requestReviewIfNeeded() async {
        guard LaunchCounter.shouldRequestReview, !records.isEmpty else { return }
        LaunchCounter.markReviewRequested()
        try? await Task.sleep(for: .seconds(2))
        requestReview()
    }
}


struct DebtFilterBar: View {
    @Binding var selection: DebtFilter

    @Namespace private var selectionNamespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(DebtFilter.allCases) { filter in
                let isSelected = selection == filter
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selection = filter
                    }
                } label: {
                    HStack(spacing: 6) {
                        if let dotColor = filter.dotColor(isSelected: isSelected) {
                            Circle()
                                .fill(dotColor)
                                .frame(width: 7, height: 7)
                        }
                        Text(filter.title)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.white : Color.secondary)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [.brandBright, .inkGlow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .shadow(color: Color.inkGlow.opacity(0.35), radius: 8, y: 3)
                                .matchedGeometryEffect(id: "selection", in: selectionNamespace)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color.appSurface, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.brand.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Filter"))
    }
}

private extension DebtFilter {
    func dotColor(isSelected: Bool) -> Color? {
        switch self {
        case .all: return nil
        case .owedToMe: return isSelected ? .owedToMeBright : .owedToMe
        case .iOwe: return isSelected ? .iOweBright : .iOwe
        }
    }
}
