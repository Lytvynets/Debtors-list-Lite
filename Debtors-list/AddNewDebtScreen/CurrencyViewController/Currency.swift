

import SwiftUI

enum CurrencyCode: String, CaseIterable, Identifiable {
    case uah = "UAH"
    case usd = "USD"
    case eur = "EUR"
    case chf = "CHF"
    case gbp = "GBP"
    case pln = "PLN"
    case aud = "AUD"
    case sek = "SEK"
    case jpy = "JPY"
    case kwd = "KWD"

    var id: String { rawValue }

    var localizedName: String {
        Locale.current.localizedString(forCurrencyCode: rawValue) ?? rawValue
    }

    var symbol: String {
        switch self {
        case .uah: return "₴"
        case .usd: return "$"
        case .eur: return "€"
        case .chf: return "₣"
        case .gbp: return "£"
        case .pln: return "zł"
        case .aud: return "A$"
        case .sek: return "kr"
        case .jpy: return "¥"
        case .kwd: return "KD"
        }
    }

    var fallbackRateToUSD: Double {
        switch self {
        case .uah: return 0.027
        case .usd: return 1
        case .eur: return 1.061
        case .chf: return 1.075
        case .gbp: return 1.20
        case .pln: return 0.24
        case .aud: return 0.69
        case .sek: return 0.095
        case .jpy: return 0.0076
        case .kwd: return 3.25
        }
    }
}


struct CurrencyMenu: View {
    @Binding var selection: CurrencyCode

    var body: some View {
        Menu {
            Picker("Currency", selection: $selection) {
                ForEach(CurrencyCode.allCases) { code in
                    Text(verbatim: "\(code.symbol)  \(code.localizedName) (\(code.rawValue))")
                        .tag(code)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(verbatim: selection.rawValue)
                    .font(.headline)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(Color.brand)
            .background(Color.brand.opacity(0.12), in: Capsule())
        }
        .accessibilityLabel(Text("Currency"))
        .accessibilityValue(Text(verbatim: selection.localizedName))
    }
}
