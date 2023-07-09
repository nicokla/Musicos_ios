
import UIKit

class SettingsScaleVC: UIViewController {
    //var 
    //var song: Song?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func backToPlayer(_ sender: Any) {
        if(globalVar.song!.videoID.count == 0){
            performSegue(withIdentifier: "goBackToPlayer2", sender: self)
        } else {
            performSegue(withIdentifier: "goBackToPlayer", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "settingEmbeded" {
//            if let nextVC = segue.destination as? SettingsScaleVC2{
//                nextVC.parentVC = self
//            }
        }else if segue.identifier == "goBackToPlayer"{
        }
    }
    
    @IBAction func unwindToSettingsScaleVC(segue:UIStoryboardSegue) {
    }
}
