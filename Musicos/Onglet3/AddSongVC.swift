
import UIKit
import RealmSwift
import PopupDialog

class AddSongVC: UIViewController {
    let realm = try! Realm()
    var allSongs: Results<Song>?
    @IBOutlet weak var buttonWithoutVideo: UIButton!
    @IBOutlet weak var buttonWithVideo: UIButton!
    
    @IBAction func addSongWithVideo(_ sender: Any) {
        if try! globalVar.gemsManager.getGems() >= 6 {
            setupAndShowPopupWithVideo(userId:globalVar.userId, currentVC: self, completionFunction: pushWithVideo)
        } else {
            proposeGemsPurchase(self)
        }
    }
    
    func pushWithVideo(){
        pushVC(identifier: "YoutubeVC")
    }
    
    @IBAction func addSongWithoutVideo(_ sender: Any) {
        if try! globalVar.gemsManager.getGems() >= 3 {
            setupAndShowPopupWithoutVideo(userId:globalVar.userId, currentVC: self, completionFunction: pushWithoutVideo)
        } else {
            proposeGemsPurchase(self)
        }
    }
    
    func pushWithoutVideo(){
        pushVC(identifier: "DefineVC")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        allSongs = realm.objects(Song.self)
        buttonWithVideo.titleLabel!.textAlignment = .center
        buttonWithoutVideo.titleLabel!.textAlignment = .center
        if UIDevice.current.userInterfaceIdiom == .pad {
            buttonWithVideo.titleLabel!.font = .systemFont(ofSize: 30)
            buttonWithoutVideo.titleLabel!.font = .systemFont(ofSize: 30)
        }
    }
}
