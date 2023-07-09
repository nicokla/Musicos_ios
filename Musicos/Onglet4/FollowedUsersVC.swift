import UIKit
import Kingfisher
import PopupDialog

class FollowedUsersVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var users: [UserStruct] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        globalVar.firebaseSongsManager.getFollowedUsers(fonction: updateTableViewFromServer)
        tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        globalVar.firebaseSongsManager.getFollowedUsers(fonction: updateTableViewFromServer)
        tableView.reloadData()
    }

    func updateTableViewFromServer(answer: [UserStruct]){
        self.users = answer
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = users[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: "mySongsCell3_coucou", for: indexPath) as! MySongsCell3
        cell.label.text = user.name
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[indexPath.row]
        globalVar.watchedUser = user
        pushVC(identifier: "SongsOfAUserVC")
    }
}
