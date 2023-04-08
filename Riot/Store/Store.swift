//swiftlint:disable all

import Foundation
import SwiftUI
import StoreKit

@available(iOS 15.0, *)
class StoreViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedIds: [String] = []
    
    func fetchProducts(){
        Task {
            do{
                let productIdentifiers = [
                    "com.temporary.ads.bss.1",
                    "com.temporary.ads.bss.2",
                    "com.temporary.ads.bss.3",
                    "com.temporary.ads.bss.4",
                    "com.temporary.ads.bss.5",
                    "com.temporary.ads.bss.6",
                    "com.temporary.ads.bss.7",
                    "com.temporary.ads.bss.14",
                    "com.temporary.ads.bss.21",
                    "com.temporary.ads.bss.30",
                ]
                let products = try await Product.products(for: productIdentifiers)
                DispatchQueue.main.async {
                    self.products = products
                }
                
                if let product = products.first{
                    isPurchased(product: product)
                }
            }
            catch{
                print("products fetch error")
                print(error)
            }
        }
    }
    
    func isPurchased(product: Product){
        Task {
            guard let state = await product.currentEntitlement else {
                return
            }
            switch state{
            case .verified(let transaction):
                print(transaction.productID)
                DispatchQueue.main.async {
                    self.purchasedIds.append(transaction.productID)
                }
                break
            case .unverified(_):
                break
            }
        }
    }
    
    func purchase(quantity: Int) async {
        guard let product = products.first(where: {
            $0.id.hasSuffix(".\(quantity)")
        }) else {
            print("oh.shit \(quantity)")
            return
        }
        
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification{
                case .verified(let transaction):
                    await transaction.finish()
                    self.purchasedIds.append(transaction.productID)
                    print(transaction.productID)
                    break
                case .unverified(_):
                    break
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
            print(result)
        }
        catch {
            print(error)
        }
    }
}



