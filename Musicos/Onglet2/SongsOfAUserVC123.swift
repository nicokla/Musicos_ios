
import UIKit
import Kingfisher
import RealmSwift

// UISearchBarDelegate
class SongsOfAUserVC123: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var myTableView: UITableView!
    
    @IBOutlet weak var followUserButton: UIButton!
    
    
    var songs: [SongStruct] = []
    var followed = false

    func updateFollowButton(){
        if(followed) {
            followUserButton.setTitle("Unfollow", for: .normal)
        } else {
            followUserButton.setTitle("Follow", for: .normal)
        }
    }
    
    @IBAction func followUserButtonAction(_ sender: Any) {
        followed = !followed
        updateFollowButton()
        if(followed) {
            globalVar.firebaseSongsManager.followUserInFirebase(user: globalVar.watchedUser)
        } else {
            globalVar.firebaseSongsManager.unfollowUserInFirebase(user: globalVar.watchedUser)
        }
    }
    
    func firebaseToldMeItWasActuallyFollowed(){
        followed = true
        updateFollowButton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myTableView.dataSource = self
        myTableView.delegate = self
        
        let userId = globalVar.watchedUser.objectID
        globalVar.firebaseSongsManager.getSongsFromUserId(userId: userId, fonction: updateTableViewFromServer)
        
        globalVar.firebaseSongsManager.checkIfUserIsFollowed(user: globalVar.watchedUser, completionFunction: firebaseToldMeItWasActuallyFollowed)
    }

    func updateTableViewFromServer(answer: [SongStruct]){
        self.songs = answer
        DispatchQueue.main.async {
            self.myTableView.reloadData()
        }
    }
    
    // -----------------------------
    // Table view
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  songs.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let song = songs[indexPath.row]
        
        if song.videoID.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "mySongsCell3_3", for: indexPath) as! MySongsCell3
            cell.label.text = song.title
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "mySongsCell4", for: indexPath) as! MySongsCell4
            cell.label.text = song.title
            cell.myImage.kf.indicatorType = .activity
            cell.myImage.kf.setImage(with: ImageResource( downloadURL: URL(string: song.imageUrl)!) )
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        globalVar.songFirebase.songPourDb = songs[indexPath.row]
//        print(globalVar.songFirebase.songPourDb)

        // CRUD : Read
        globalVar.firebaseSongsManager.getSong2(id: songs[indexPath.row].objectID, completionFunction: completionFunction, completionFunctionError: {})
    }
    
    func completionFunction(){
        if globalVar.songFirebase.songPourDb.videoID.count == 0 {
            pushVC(identifier: "OtherUserSongVC2")
        } else {
            pushVC(identifier: "OtherUserSongVC")
        }
    }
    
}
