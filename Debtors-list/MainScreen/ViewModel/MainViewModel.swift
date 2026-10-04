

import Foundation
import Observation


enum DebtFilter: String, CaseIterable, Identifiable {
    case all
    case owedToMe
    case iOwe

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .all: return "All"
        case .owedToMe: return "Owed to you"
        case .iOwe: return "You owe"
        }
    }

    func matches(_ record: DebtRecord) -> Bool {
        switch self {
        case .all: return true
        case .owedToMe: return record.isOwedToMe
        case .iOwe: return !record.isOwedToMe
        }
    }
}


struct DebtSummary: Equatable {
    var owedToMe: Double = 0
    var iOwe: Double = 0

    var net: Double { owedToMe - iOwe }
    var total: Double { owedToMe + iOwe }
    var owedToMeShare: Double { total > 0 ? owedToMe / total : 0.5 }

    init() {}

    init(records: [DebtRecord], rates: [String: Double]) {
        for record in records {
            let rate = rates[record.currencyCode] ?? 1
            let usd = record.amount * rate
            if record.isOwedToMe {
                owedToMe += usd
            } else {
                iOwe += usd
            }
        }
    }
}


@MainActor
@Observable
final class MainViewModel {
    var filter: DebtFilter = .all
    var searchText = ""

    var isAddingDebt = false
    var editingRecord: DebtRecord?
    var recordPendingDeletion: DebtRecord?
    var isShowingPaywall = false

    func visibleRecords(from records: [DebtRecord]) -> [DebtRecord] {
        let query = searchText.trimmed
        return records.filter { record in
            guard filter.matches(record) else { return false }
            return query.isEmpty || record.fullName.localizedStandardContains(query)
        }
    }
}
