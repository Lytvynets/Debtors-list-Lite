

import Foundation
import Observation


struct NetworkManager {
    enum NetworkError: Error {
        case badURL
        case badStatus(Int)
        case badRate
    }

    private let headers = [
        "X-RapidAPI-Key": "20e6cda988mshb1ffa7966633a31p1f7f91jsne5d2a00c30e6",
        "X-RapidAPI-Host": "alpha-vantage.p.rapidapi.com"
    ]

    func fetchRate(from: String, to: String) async throws -> Double {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "alpha-vantage.p.rapidapi.com"
        components.path = "/query"
        components.queryItems = [
            URLQueryItem(name: "function", value: "CURRENCY_EXCHANGE_RATE"),
            URLQueryItem(name: "from_currency", value: from),
            URLQueryItem(name: "to_currency", value: to)
        ]
        guard let url = components.url else { throw NetworkError.badURL }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw NetworkError.badStatus(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(RateResponse.self, from: data)
        guard let rate = Double(decoded.payload.rate), rate > 0 else { throw NetworkError.badRate }
        return rate
    }
}


private struct RateResponse: Decodable {
    struct Payload: Decodable {
        let rate: String

        enum CodingKeys: String, CodingKey {
            case rate = "5. Exchange Rate"
        }
    }

    let payload: Payload

    enum CodingKeys: String, CodingKey {
        case payload = "Realtime Currency Exchange Rate"
    }
}


@MainActor
@Observable
final class CurrencyRateService {
    private(set) var cachedRates: [String: Double]
    private(set) var lastUpdated: Date?
    private(set) var isRefreshing = false

    @ObservationIgnored private let network = NetworkManager()
    @ObservationIgnored private let cacheLifetime: TimeInterval = 12 * 60 * 60

    init() {
        let defaults = UserDefaults.standard
        cachedRates = (defaults.dictionary(forKey: StorageKey.cachedRates) as? [String: Double]) ?? [:]
        lastUpdated = defaults.object(forKey: StorageKey.cachedRatesDate) as? Date
    }

    var effectiveRates: [String: Double] {
        var result: [String: Double] = [:]
        for code in CurrencyCode.allCases {
            result[code.rawValue] = cachedRates[code.rawValue] ?? code.fallbackRateToUSD
        }
        result[CurrencyCode.usd.rawValue] = 1
        return result
    }

    func refresh(codes: Set<String>, force: Bool = false) async {
        let needed = codes.filter { $0 != CurrencyCode.usd.rawValue && CurrencyCode(rawValue: $0) != nil }
        guard !needed.isEmpty, !isRefreshing else { return }

        let isFresh = lastUpdated.map { Date().timeIntervalSince($0) < cacheLifetime } ?? false
        let hasMissing = needed.contains { cachedRates[$0] == nil }
        guard force || !isFresh || hasMissing else { return }

        isRefreshing = true
        defer { isRefreshing = false }

        let network = self.network
        let fetched = await withTaskGroup(of: (String, Double?).self, returning: [String: Double].self) { group in
            for code in needed {
                group.addTask {
                    let rate = try? await network.fetchRate(from: code, to: "USD")
                    return (code, rate)
                }
            }
            var result: [String: Double] = [:]
            for await (code, rate) in group {
                if let rate {
                    result[code] = rate
                }
            }
            return result
        }

        guard !fetched.isEmpty else { return }
        cachedRates.merge(fetched) { _, new in new }
        lastUpdated = Date()

        let defaults = UserDefaults.standard
        defaults.set(cachedRates, forKey: StorageKey.cachedRates)
        defaults.set(lastUpdated, forKey: StorageKey.cachedRatesDate)
    }
}
