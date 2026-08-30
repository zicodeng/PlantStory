import StoreKit

@MainActor
final class TipJarStore: ObservableObject {
    static let productIDs = [
        "com.zicodeng.PlantStory.tip.small",
        "com.zicodeng.PlantStory.tip.regular",
        "com.zicodeng.PlantStory.tip.generous"
    ]

    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var purchasingProductID: String?
    @Published private(set) var loadingError: String?
    @Published var notice: TipJarNotice?

    private var hasLoaded = false

    func loadProducts(force: Bool = false) async {
        guard !isLoading, force || !hasLoaded else { return }

        isLoading = true
        loadingError = nil
        defer { isLoading = false }

        do {
            let fetchedProducts = try await Product.products(for: Self.productIDs)
            let order = Dictionary(
                uniqueKeysWithValues: Self.productIDs.enumerated().map { ($1, $0) }
            )

            products = fetchedProducts.sorted {
                order[$0.id, default: .max] < order[$1.id, default: .max]
            }
            hasLoaded = true

            if products.isEmpty {
                loadingError = "Support options are not available yet."
            }
        } catch {
            loadingError = "Support options could not be loaded. Please try again."
        }
    }

    func purchase(_ product: Product) async {
        guard purchasingProductID == nil else { return }

        purchasingProductID = product.id
        defer { purchasingProductID = nil }

        do {
            switch try await product.purchase() {
            case .success(let verificationResult):
                switch verificationResult {
                case .verified(let transaction):
                    await transaction.finish()
                    notice = TipJarNotice(
                        title: "Thank you!",
                        message: "You helped the PlantStory garden grow."
                    )
                case .unverified:
                    notice = TipJarNotice(
                        title: "Purchase not verified",
                        message: "Apple could not verify this purchase. You have not been credited for it."
                    )
                }
            case .pending:
                notice = TipJarNotice(
                    title: "Purchase pending",
                    message: "Apple is still processing this purchase."
                )
            case .userCancelled:
                break
            @unknown default:
                notice = TipJarNotice(
                    title: "Purchase unavailable",
                    message: "This purchase could not be completed. Please try again later."
                )
            }
        } catch {
            notice = TipJarNotice(
                title: "Purchase unavailable",
                message: "This purchase could not be completed. Please try again later."
            )
        }
    }
}

struct TipJarNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
