
import UIKit
import AlgoliaSearchClient

class SearchUsersVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    let client = SearchClient(appID: "SKJIA8T5Z2", apiKey: "cde90e9470f0ee7676b7c06fbd200132")
    var index: Index?

//    var myList:[Hit<JSON>] = []
    var users: [UserStruct] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        searchBar.delegate = self

        index = client.index(withName: "users")
    }

    // -------------------------
    // Table view
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = users[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "mySongsCell3_2", for: indexPath) as! MySongsCell3
        cell.label.text = user.name // + " : " + user.objectID
        return cell
    }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // CRUD : Read (all the songs by this user)
        let user = users[indexPath.row]
        globalVar.watchedUser = user
        pushVC(identifier: "SongsOfAUserVC")
    }
    
    // -----------------------------
    // Search bar
    
    func updateTableViewFromServer(answer: [UserStruct]){
        self.users = answer
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let text = searchBar.text!
        // CRUD : Read
        globalVar.firebaseSongsManager.searchUsers(s: text, fonction: updateTableViewFromServer)
        DispatchQueue.main.async {
            searchBar.resignFirstResponder()
        }
    }

    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        self.users = []
        tableView.reloadData()
    }
    
}
