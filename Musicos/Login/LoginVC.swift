import UIKit
import FirebaseAuth
import Foundation
import Firebase
import CodableFirebase
import PopupDialog
import KeychainAccess

class LoginVC: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        setUpElements()
    }
    
    func emailHasBeenSentPopup(){
        let title = "Email sent successfully"
        let message = "We sent an email to your adress \(emailTextField.text!) to reset your password."
        let popup = PopupDialog(title: title, message: message)
        let button = DefaultButton(title: "OK") {
        }
        button.backgroundColor = .green
        popup.addButton(button)
        self.present(popup, animated: true, completion: nil)
    }
    
    func emailCouldNotBeSentPopup(){
        let title = "Email could not be sent"
        let message = "We did not manage to send you an email at the adress ' \(String(describing: emailTextField.text!)) '."
        let popup = PopupDialog(title: title, message: message)
        let dialogAppearance = PopupDialogDefaultView.appearance()
        dialogAppearance.backgroundColor = .lightGray
        dialogAppearance.titleColor = .black
        dialogAppearance.messageColor = .darkGray
        let button = DefaultButton(title: "OK") {
        }
        popup.addButton(button)
        self.present(popup, animated: true, completion: nil)
    }
    
    @IBAction func passwordForgotten(_ sender: Any) {
        let email = emailTextField.text!
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            guard let self = self else { return }
            if error != nil {
                self.emailCouldNotBeSentPopup()
            } else {
                self.emailHasBeenSentPopup()
            }
        }
    }
    
    func setUpElements() {
        // Hide the error label
        errorLabel.alpha = 0
        
        // Style the elements
        Utilities.styleTextField(emailTextField)
        Utilities.styleTextField(passwordTextField)
        Utilities.styleFilledButton(loginButton)
    }
    
    
    @IBAction func loginTapped(_ sender: Any) {
        // TODO: Validate Text Fields
        
        // Create cleaned versions of the text field
        let email = emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Signing in the user
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            
            if error != nil {
                // Couldn't sign in
                self.errorLabel.text = error!.localizedDescription
                self.errorLabel.alpha = 1
            }
            else {
                globalVar.userId = result!.user.uid
                
                let db = Firestore.firestore()
                let docRef = db.collection("users").document(globalVar.userId)
                docRef.getDocument { document, error in
                    if let document = document {
                        let data = document.data()!
                        print(data)
                        let user = try! FirestoreDecoder().decode(UserStruct.self, from: data)
                        globalVar.userName = user.name
                    } else {
                        print("Document does not exist")
                    }
                }
                do {
                    try _ = globalVar.gemsManager.getGems()
                } catch GemsManagerError.invalidKey(_) {
                    globalVar.gemsManager.setGems(30)
                } catch {
                    print("Lol, you shouldn't be here!")
                }
                
                
                // CRUD : Read
                globalVar.firebaseSongsManager.loadAllSong1sFromFirebaseToRealm(continueLogin: self.continueLogin)
            }
        }
 
    }
    
    func continueLogin(){
        let homeViewController = self.storyboard?.instantiateViewController(withIdentifier: "NavigationVC_root")
        
        self.view.window?.rootViewController = homeViewController
        self.view.window?.makeKeyAndVisible()
    }
    
}
