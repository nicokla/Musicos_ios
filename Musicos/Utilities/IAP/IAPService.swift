import Foundation
import StoreKit


extension SKProduct {
    fileprivate static var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }

    var localizedPrice: String {
        if self.price == 0.00 {
            return "Get"
        } else {
            let formatter = SKProduct.formatter
            formatter.locale = self.priceLocale

            guard let formattedPrice = formatter.string(from: self.price) else {
                return "Unknown Price"
            }

            return formattedPrice
        }
    }
}

class IAPService: NSObject{
    override init() {
        super.init()
        getProducts()
    }
    
//    static let shared = IAPService()
    var products = [SKProduct]()
    let paymentQueue = SKPaymentQueue.default()
    let productsNames: Set = [IAPProduct.consumable_100gems.rawValue,
                         IAPProduct.consumable_240gems.rawValue,
                         IAPProduct.consumable_700gems.rawValue,
                         IAPProduct.consumable_2000gems.rawValue]

    func getProducts(){
        // !!!
        let request = SKProductsRequest(productIdentifiers: productsNames)
        request.delegate = self
        request.start()
        paymentQueue.add(self)
    }
    
    func purchase(product: IAPProduct){ // !!!
        guard let productToPurchase = products.filter({ $0.productIdentifier == product.rawValue}).first else {return}
        let payment = SKPayment(product: productToPurchase)
        paymentQueue.add(payment)
    }
    
    func restorePurchases(){
        print("restoring purchases")
        paymentQueue.restoreCompletedTransactions()
    }
}


extension IAPService : SKProductsRequestDelegate{
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse){
        self.products = response.products
        for product in response.products{
            switch(product.productIdentifier){
            case(IAPProduct.consumable_100gems.rawValue):
                button100gemsText = "Get 100 Gems for " + product.localizedPrice
            case(IAPProduct.consumable_240gems.rawValue):
                button240gemsText = "Get 240 Gems for " + product.localizedPrice
            case(IAPProduct.consumable_700gems.rawValue):
                button700gemsText = "Get 700 Gems for " + product.localizedPrice
            case(IAPProduct.consumable_2000gems.rawValue):
                button2000gemsText = "Get 2000 Gems for " + product.localizedPrice
            default:
                print("product id is unknown.")
            }
            print("\(product.localizedTitle): \(product.localizedPrice)")
        }
    }
}

extension IAPService: SKPaymentTransactionObserver{
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions{
            print(transaction.transactionState)
            switch transaction.transactionState{
            case .purchasing:
                break
            case .purchased:
                queue.finishTransaction(transaction)
                let myProductId = transaction.payment.productIdentifier
                switch (myProductId){
                case IAPProduct.consumable_100gems.rawValue:
                    try! globalVar.gemsManager.addGems(100)
                case IAPProduct.consumable_240gems.rawValue:
                    try! globalVar.gemsManager.addGems(240)
                case IAPProduct.consumable_700gems.rawValue:
                    try! globalVar.gemsManager.addGems(700)
                case IAPProduct.consumable_2000gems.rawValue:
                    try! globalVar.gemsManager.addGems(2000)
                default:
                    print("product identifier is unknown")
                }
                break
            case .failed:
                queue.finishTransaction(transaction)
                break
            case .restored:
                queue.finishTransaction(transaction)
                break
                
            default: break

            }
        }
    }
}

extension SKPaymentTransactionState{
    func status() -> String{
        switch self{
        case .deferred: return "deferred"
        case .failed: return "failed"
        case .purchased: return "purchased"
        case .purchasing: return "purchasing"
        case .restored: return "restored"
        }
    }
}









