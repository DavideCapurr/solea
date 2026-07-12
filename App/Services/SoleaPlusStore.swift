import Foundation
import Observation
import StoreKit

struct SoleaPlusEntitlement: Equatable {
    var productID: String?
    var validUntil: Date?

    var isActive: Bool {
        guard productID != nil else { return false }
        guard let validUntil else { return true }
        return validUntil > .now
    }

    static let free = SoleaPlusEntitlement(productID: nil, validUntil: nil)
}

enum SoleaPlusProductID: String, CaseIterable {
    case monthly = "com.davidecapurro.Solea.plus.monthly"
    case annual = "com.davidecapurro.Solea.plus.annual"
    case seasonal = "com.davidecapurro.Solea.plus.seasonal"

    static let merchandised: [SoleaPlusProductID] = [.annual, .seasonal]

    var fallbackPriceText: String {
        switch self {
        case .monthly:
            return String(localized: "€3,99/mese")
        case .annual:
            return String(localized: "€19,99/anno")
        case .seasonal:
            return String(localized: "€9,99 pass estate")
        }
    }

    var fallbackTitle: String {
        switch self {
        case .monthly:
            return String(localized: "Tanora Plus mensile")
        case .annual:
            return String(localized: "Tanora Plus annuale")
        case .seasonal:
            return String(localized: "Tanora Plus Summer Pass")
        }
    }
}

enum SoleaPlusPurchaseError: LocalizedError {
    case unverified

    var errorDescription: String? {
        switch self {
        case .unverified:
            return String(localized: "L'acquisto non è verificabile. Non è stato sbloccato alcun accesso Plus.")
        }
    }
}

@MainActor
@Observable
final class SoleaPlusStore {
    private(set) var products: [Product] = []
    private(set) var entitlement: SoleaPlusEntitlement = .free
    private(set) var isLoadingProducts = false
    private(set) var isPurchasing = false
    var noticeMessage: String?

    @ObservationIgnored private var didStart = false
    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    private static let seasonalAccessDays = 120

    var hasPlus: Bool {
        entitlement.isActive
    }

    func start() async {
        guard !didStart else {
            await refreshEntitlement()
            return
        }
        didStart = true
        updatesTask = listenForTransactions()
        await loadProducts()
        await refreshEntitlement()
    }

    func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let fetched = try await Product.products(for: SoleaPlusProductID.allCases.map(\.rawValue))
            products = fetched.sorted { lhs, rhs in
                productSortIndex(lhs.id) < productSortIndex(rhs.id)
            }
            noticeMessage = nil
        } catch {
            noticeMessage = String(localized: "Prodotti Plus non disponibili: \(error.localizedDescription)")
        }
    }

    func product(for id: SoleaPlusProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verifiedTransaction(from: verification)
                await transaction.finish()
                await refreshEntitlement()
                noticeMessage = nil
            case .pending:
                noticeMessage = String(localized: "Acquisto in attesa di approvazione. Tanora Plus si sbloccherà appena Apple conferma la transazione.")
            case .userCancelled:
                break
            @unknown default:
                noticeMessage = String(localized: "Acquisto non completato. Riprova tra poco.")
            }
        } catch {
            noticeMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlement()
            noticeMessage = hasPlus
                ? String(localized: "Acquisti ripristinati.")
                : String(localized: "Nessun accesso Tanora Plus attivo trovato per questo Apple ID.")
        } catch {
            noticeMessage = String(localized: "Ripristino non riuscito: \(error.localizedDescription)")
        }
    }

    func refreshEntitlement() async {
        var best = SoleaPlusEntitlement.free

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  let candidate = entitlement(from: transaction),
                  candidate.isActive
            else {
                continue
            }

            if shouldPrefer(candidate, over: best) {
                best = candidate
            }
        }

        entitlement = best
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                await self.handle(transactionUpdate: update)
            }
        }
    }

    private func handle(transactionUpdate update: VerificationResult<Transaction>) async {
        do {
            let transaction = try verifiedTransaction(from: update)
            await transaction.finish()
            await refreshEntitlement()
        } catch {
            noticeMessage = error.localizedDescription
        }
    }

    private func verifiedTransaction(
        from result: VerificationResult<Transaction>
    ) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified:
            throw SoleaPlusPurchaseError.unverified
        }
    }

    private func entitlement(from transaction: Transaction) -> SoleaPlusEntitlement? {
        guard transaction.revocationDate == nil,
              let productID = SoleaPlusProductID(rawValue: transaction.productID)
        else {
            return nil
        }

        switch productID {
        case .monthly, .annual:
            if let expirationDate = transaction.expirationDate, expirationDate <= .now {
                return nil
            }
            return SoleaPlusEntitlement(
                productID: productID.rawValue,
                validUntil: transaction.expirationDate
            )
        case .seasonal:
            guard let expirationDate = Calendar.current.date(
                byAdding: .day,
                value: Self.seasonalAccessDays,
                to: transaction.purchaseDate
            ), expirationDate > .now else {
                return nil
            }
            return SoleaPlusEntitlement(productID: productID.rawValue, validUntil: expirationDate)
        }
    }

    private func shouldPrefer(
        _ candidate: SoleaPlusEntitlement,
        over current: SoleaPlusEntitlement
    ) -> Bool {
        guard current.isActive else { return true }

        if candidate.productID == SoleaPlusProductID.annual.rawValue {
            return true
        }
        if current.productID == SoleaPlusProductID.annual.rawValue {
            return false
        }

        let candidateDate = candidate.validUntil ?? .distantFuture
        let currentDate = current.validUntil ?? .distantFuture
        return candidateDate > currentDate
    }

    private func productSortIndex(_ productID: String) -> Int {
        SoleaPlusProductID.allCases.firstIndex { $0.rawValue == productID } ?? Int.max
    }
}
