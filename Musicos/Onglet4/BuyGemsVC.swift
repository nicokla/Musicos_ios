
import UIKit

var button100gemsText = "Get 100 Gems for 0.99 $"
var button240gemsText = "Get 240 Gems for 1.99 $"
var button700gemsText = "Get 700 Gems for 4.99 $"
var button2000gemsText = "Get 2000 Gems for 9.99 $"

class BuyGemsVC: UIViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
        button100gems.setTitle(button100gemsText, for: .normal)
        button240gems.setTitle(button240gemsText, for: .normal)
        button700gems.setTitle(button700gemsText, for: .normal)
        button2000gems.setTitle(button2000gemsText, for: .normal)
        if(UIDevice.current.userInterfaceIdiom == .phone){
            for button in [button100gems, button240gems, button700gems, button2000gems]{
                button!.titleLabel!.font = .systemFont(ofSize: 18)
                button!.titleLabel!.adjustsFontSizeToFitWidth = true
                button!.titleLabel!.adjustsFontForContentSizeCategory = true
            }
        }
    }
    
    @IBOutlet weak var button100gems: UIButton!
    
    @IBOutlet weak var button240gems: UIButton!
    
    @IBOutlet weak var button700gems: UIButton!
    
    @IBOutlet weak var button2000gems: UIButton!
    
    @IBAction func get100Gems(_ sender: Any) {
//        try! globalVar.gemsManager.addGems(100)
        globalVar.myIAPService.purchase(product: IAPProduct.consumable_100gems)
    }
    
    @IBAction func get240Gems(_ sender: Any) {
//        try! globalVar.gemsManager.addGems(240)
        globalVar.myIAPService.purchase(product: IAPProduct.consumable_240gems)
    }
    
    @IBAction func get700Gems(_ sender: Any) {
//        try! globalVar.gemsManager.addGems(700)
        globalVar.myIAPService.purchase(product: IAPProduct.consumable_700gems)
    }
    
    @IBAction func get2000Gems(_ sender: Any) {
//        try! globalVar.gemsManager.addGems(2000)
        globalVar.myIAPService.purchase(product: IAPProduct.consumable_2000gems)
    }
}
