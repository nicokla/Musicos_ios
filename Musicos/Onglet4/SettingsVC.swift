
import UIKit
import FirebaseAuth
import PopupDialog

class SettingsVC: UIViewController {
//    @IBOutlet weak var gemsLabel: UILabel!
    
    func showLogoutDialog(){
        let title = "Are you sure ?"
        let message = "Are you sure you want to log out ?"
        
        let popup = PopupDialog(title: title, message: message)
//        let dialogAppearance = PopupDialogDefaultView.appearance()
//        dialogAppearance.backgroundColor = .lightGray
//        dialogAppearance.titleColor = .black
//        dialogAppearance.messageColor = .darkGray
        let button = DefaultButton(title: "Log out") {
            self.logout()
        }
        button.backgroundColor = .lightGray
        popup.addButton(button)
        let button2 = DefaultButton(title: "Stay logged in") {
        }
        popup.addButton(button2)
        self.present(popup, animated: true, completion: nil)
    }
    
    func logout(){
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
        } catch let signOutError as NSError {
          print ("Error signing out: %@", signOutError)
        }
        let navController = self.storyboard?.instantiateViewController(withIdentifier: "navigationController1")
        self.view.window?.rootViewController = navController
        self.view.window?.makeKeyAndVisible()
    }
    
    @IBAction func logoutAction(_ sender: Any) {
        showLogoutDialog()
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        gemsLabel.text = try! String(globalVar.gemsManager.getGems()) + " Gems"
    }

    @IBAction func followedUsersButtonAction(_ sender: Any) {
        
    }
}
