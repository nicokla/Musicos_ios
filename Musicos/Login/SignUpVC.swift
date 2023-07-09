
import Foundation
import RealmSwift
import AlgoliaSearchClient
import Firebase
import CodableFirebase
import UIKit
import FirebaseAuth

class SignUpVC: UIViewController {

    @IBOutlet weak var firstNameTextField: UITextField!
        
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var signUpButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setUpElements()
    }
    
    func setUpElements() {
    
        // Hide the error label
        errorLabel.alpha = 0
    
        // Style the elements
        Utilities.styleTextField(firstNameTextField)
        Utilities.styleTextField(emailTextField)
        Utilities.styleTextField(passwordTextField)
        Utilities.styleFilledButton(signUpButton)
    }
    
    // Check the fields and validate that the data is correct. If everything is correct, this method returns nil. Otherwise, it returns the error message
    func validateFields() -> String? {
        
        // Check that all fields are filled in
        if firstNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            
            return "Please fill in all fields."
        }
        
        // Check if the password is secure
        /*
        let cleanedPassword = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if Utilities.isPasswordValid(cleanedPassword) == false {
            // Password isn't secure enough
            return "Please make sure your password is at least 8 characters, contains a special character and a number."
        }
         */
        
        return nil
    }
    

    @IBAction func signUpTapped(_ sender: Any) {
        
        // Validate the fields
        let error = validateFields()
        
        if error != nil {
            
            // There's something wrong with the fields, show error message
            showError(error!)
        }
        else {
            
            // Create cleaned versions of the data
            let name = firstNameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let email = emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let password = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Create the user
            Auth.auth().createUser(withEmail: email, password: password) { (result, err) in
                
                // Check for errors
                if err != nil {
                    
                    // There was an error creating the user
                    //"Error creating user"
                    self.showError(err!.localizedDescription)
                }
                else {
                    
                    // User was created successfully, now store the first name and last name
                    let db = Firestore.firestore()
                    
                    // CRUD : Create user
                    // for later, use token instead of id
                    // --> https://firebase.google.com/docs/auth/admin/verify-id-tokens#retrieve_id_tokens_on_clients
                    let id = String(result!.user.uid)
                    
                    let user = UserStruct(
                        name: name,
                        objectID: id
                    )
                    let docData = try! FirestoreEncoder().encode(user)
                    db.collection("users").document(id).setData(docData)
                    { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("Document successfully written!")
                        }
                    }
                    
                    globalVar.userId = id
                    globalVar.userName = name
                    do {
                        try _ = globalVar.gemsManager.getGems()
                    } catch GemsManagerError.invalidKey(_) {
                        globalVar.gemsManager.setGems(30)
                    } catch {
                        print("Lol, you shouldn't be here!")
                    }
                    
                    globalVar.firebaseSongsManager.deleteAllRealmSongs()
//                    globalVar.firebaseSongsManager.loadAllSong1sFromFirebaseToRealm(continueLogin: self.transitionToHome)
                    self.transitionToHome()
                }
                
            }
        }
    }
    
    func showError(_ message:String) {
        
        errorLabel.text = message
        errorLabel.alpha = 1
    }
    
    func transitionToHome() {
        
        let homeViewController = storyboard?.instantiateViewController(withIdentifier: "NavigationVC_root")
        
        view.window?.rootViewController = homeViewController
        view.window?.makeKeyAndVisible()
        
    }
    
}
