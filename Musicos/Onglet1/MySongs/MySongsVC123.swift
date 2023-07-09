
import UIKit
import Kingfisher
import RealmSwift
import SwipeCellKit


extension UIColor {
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }
}

class MySongsVC123: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, SwipeTableViewCellDelegate {
    
    var allSongs: Results<Song>?
    var songs: Results<Song>?
    let realm = try! Realm()
    var myTabBarVC : MyTabBarVC?
    
    @IBOutlet weak var mySearchBar: UISearchBar!
    @IBOutlet weak var myTableView: UITableView!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        myTableView.dataSource = self
        myTableView.delegate = self
        
        mySearchBar.delegate = self
                
        allSongs = realm.objects(Song.self)
        songs  = realm.objects(Song.self)

        let reachability = Reachability()!
        
        if reachability.connection == .none {
            self.popUpText(title:"No internet", message: "You need internet to play the videos")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        myTableView.reloadData()
    }
    
    func popUpText(title:String,message:String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    // -----------------------------
    // Table view
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  songs?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let song = songs![indexPath.row]
        
        if song.videoID.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "mySongsCell2", for: indexPath) as! MySongsCell2
            cell.delegate = self
            cell.label.text = song.title
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "mySongsCell", for: indexPath) as! MySongsCell
            cell.delegate = self
            cell.label.text = song.title
            cell.myImage.kf.indicatorType = .activity
            cell.myImage.kf.setImage(with: ImageResource( downloadURL: URL(string: song.imageUrl)!) )
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        globalVar.song = songs?[indexPath.row]
        // CRUD : Read
        globalVar.firebaseSongsManager.loadOneSong2FromFirebaseToRealm(id: globalVar.song!.id, completionFunction: self.completionFunction)
    }
    
    func completionFunction(){
        if globalVar.song!.videoID.count == 0 {
            pushVC(identifier: "PlayerVC2")
        } else {
            pushVC(identifier: "PlayerVC")
        }
    }
    
    // -------------------
    // Utilities

    func updateModel(at indexPath: IndexPath) {
        if let songForDeletion = self.songs?[indexPath.row] {
            do {
                // CRUD : Delete
                globalVar.firebaseSongsManager.deleteSongFromFirebase(id: songForDeletion.id)
                if (songForDeletion.originalID != ""){
                    try! globalVar.gemsManager.addGems(6)
                }else if(songForDeletion.videoID == ""){
                    try! globalVar.gemsManager.addGems(2)
                }else{
                    try! globalVar.gemsManager.addGems(4)
                }
                myTabBarVC!.gemsLabel.text = try! String(globalVar.gemsManager.getGems()) + " Gems"
                try self.realm.write {
                    self.realm.delete(songForDeletion)
                }
            } catch {
                print("Error deleting song, \(error)")
            }
        }
    }
    
    func loadItems() {
        songs = allSongs?.sorted(byKeyPath: "title", ascending: true)
        myTableView.reloadData()
    }

    /*
    @IBAction func unwindToMySongsVC123(segue:UIStoryboardSegue) {
        myTableView.reloadData()
    }
    */
    
    // ------------------------
    // Swipe
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            self.updateModel(at: indexPath)
        }
        deleteAction.image = UIImage(named: "delete-icon")
        return [deleteAction]
    }
    
    // !!!
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeTableOptions {
        var options = SwipeTableOptions()
        options.expansionStyle = .destructive
        return options
    }
    
    // -----------------------------
    // Search bar
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text?.count == 0 {
            loadItems()
        }else{
            songs = allSongs?.filter("title CONTAINS[cd] %@", searchBar.text!) //.sorted(byKeyPath: "dateCreated", ascending: true)
            myTableView.reloadData()
        }
        DispatchQueue.main.async {
            searchBar.resignFirstResponder()
        }
    }

    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        } else {
            songs = allSongs?.filter("title CONTAINS[cd] %@", searchBar.text!) //.sorted(byKeyPath: "dateCreated", ascending: true)
            myTableView.reloadData()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        myTableView.reloadData()
    }
    
    
    // -----------------------------
    // New song
    
//    @IBAction func nextAction(_ sender: Any) {
//        pushVC(identifier: "AddSongVC")
//    }
    
}
