import UIKit

class MyTabBarVC: UITabBarController{

    @IBOutlet weak var gemsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        gemsLabel.text = try! String(globalVar.gemsManager.getGems()) + " Gems"
        reactIfYoutubeSucked(self)
    }
    
    @IBAction func unwindToMyTabBarVC(segue:UIStoryboardSegue) {
        
    }

}
