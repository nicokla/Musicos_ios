
import UIKit

class OtherUserSettingVC: UIViewController {
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
        if(globalVar.songFirebase.songPourDb.videoID.count == 0){
            performSegue(withIdentifier: "goBackToOtherVC2", sender: self)
        } else {
            performSegue(withIdentifier: "goBackToOtherVC", sender: self)
        }
//        popVC()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "otherUserSettingEmbed" {
            if let nextVC = segue.destination as? OtherUserSettingVC2{
//                nextVC.parentVC = self
            }
        }
        //else if segue.identifier == "goBackToOtherVC"{
        //}
    }
    
    @IBAction func unwindToSettingsScaleVC(segue:UIStoryboardSegue) {
    }
}
