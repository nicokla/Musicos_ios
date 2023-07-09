
import UIKit
import AlgoliaSearchClient
import Kingfisher
import RealmSwift

class SearchSongsVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate  {

    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var tableView: UITableView!
    
//    var myList:[Hit<JSON>] = []
    var songs: [SongStruct] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        searchBar.delegate = self
    }

    
    // -------------------------
    // Table view
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    // https://www.avanderlee.com/swift/json-parsing-decoding/
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let song = songs[indexPath.row]
        
        if song.videoID.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "mySongsCell5", for: indexPath) as! MySongsCell5
            cell.songNameLabel.text = song.title
            cell.userNameLabel.text = song.ownerName
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "mySongsCell6", for: indexPath) as! MySongsCell6
            cell.songNameLabel.text = song.title
            cell.userNameLabel.text = song.ownerName
            cell.songImage.kf.indicatorType = .activity
            cell.songImage.kf.setImage(with: ImageResource( downloadURL: URL(string: song.imageUrl)!))
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

    
    // -----------------------------
    // Search bar
    
    func updateTableViewFromServer(answer: [SongStruct]){
        self.songs = answer
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let text = searchBar.text!
        // CRUD : Read
        globalVar.firebaseSongsManager.searchSongs(s: text, fonction: updateTableViewFromServer)
        DispatchQueue.main.async {
            searchBar.resignFirstResponder()
        }
    }

    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        self.songs = []
        tableView.reloadData()
    }
    
}
