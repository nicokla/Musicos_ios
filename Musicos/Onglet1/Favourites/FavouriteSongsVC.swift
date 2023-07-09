import UIKit
import Kingfisher
import PopupDialog

class FavouriteSongsVC: UIViewController, UITableViewDataSource, UITableViewDelegate{

    @IBOutlet weak var tableView: UITableView!
    var songs: [SongStruct] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        globalVar.firebaseSongsManager.getLikedSongs(fonction: updateTableViewFromServer)
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        globalVar.firebaseSongsManager.getLikedSongs(fonction: updateTableViewFromServer)
        tableView.reloadData()
    }
    
    func updateTableViewFromServer(answer: [SongStruct]){
        self.songs = answer
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let song = songs[indexPath.row]
        
        if song.videoID.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "mySongsCell5_2", for: indexPath) as! MySongsCell5
            cell.songNameLabel.text = song.title
            cell.userNameLabel.text = song.ownerName
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "mySongsCell6_2", for: indexPath) as! MySongsCell6
            cell.songNameLabel.text = song.title
            cell.userNameLabel.text = song.ownerName
            cell.songImage.kf.indicatorType = .activity
            cell.songImage.kf.setImage(with: ImageResource( downloadURL: URL(string: song.imageUrl)!))
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        globalVar.songFirebase.songPourDb = songs[indexPath.row]
//        print(globalVar.songFirebase.songPourDb)

        // CRUD : Read
        globalVar.firebaseSongsManager.getSong2(id: songs[indexPath.row].objectID, completionFunction: completionFunction, completionFunctionError: completionFunctionError)
    }

    func completionFunction(){
        if globalVar.songFirebase.songPourDb.videoID.count == 0 {
            pushVC(identifier: "OtherUserSongVC2")
        } else {
            pushVC(identifier: "OtherUserSongVC")
        }
    }

    func completionFunctionError(){
        let title = "This song doesn't exist anymore"
        let message = "This song has been deleted by its owner. It cannot be opened anymore."
        let popup = PopupDialog(title: title, message: message)
        let dialogAppearance = PopupDialogDefaultView.appearance()
        dialogAppearance.backgroundColor = .lightGray
        dialogAppearance.titleColor = .black
        dialogAppearance.messageColor = .darkGray
        let button = DefaultButton(title: "OK") {
            globalVar.firebaseSongsManager.getLikedSongs(fonction: self.updateTableViewFromServer)
        }
        popup.addButton(button)
        globalVar.firebaseSongsManager.dislikeSongInFirebase(song: globalVar.songFirebase.songPourDb)
        self.present(popup, animated: true, completion: nil)
    }
}
