import UIKit
import SimpleCheckbox

class PopupDontShowAgain: UIViewController {
    
    var key:String = ""
//    var nextVCIdentifier:String = ""
    var content:String = ""
    var myTitle: String = ""
    var textButtonCancel : String = ""
    var textButtonContinue : String = ""

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var checkbox: Checkbox!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    var completionFunction: (() -> ())?
    
    func setup(myTitle: String, content: String, textButtonCancel: String, textButtonContinue: String, key: String, completionFunction: @escaping(() -> ())){ // nextVCIdentifier: String
        self.key = key
//        self.nextVCIdentifier = nextVCIdentifier
        self.myTitle = myTitle
        self.content = content
        self.textButtonCancel = textButtonCancel
        self.textButtonContinue = textButtonContinue
        self.completionFunction = completionFunction
    }
        
    @IBAction func cancelAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func continueAction(_ sender: Any) {
        self.dismiss(animated: true, completion: {
//            pushVC(identifier: self.nextVCIdentifier)
            self.completionFunction!()
            self.completionFunction = nil
        })
    }
    
    @IBAction func checkboxAction(_ sender: Checkbox) {
        if sender.isChecked {
            globalVar.gemsManager.setVariable(key, "a")
        } else {
            globalVar.gemsManager.setVariable(key, "")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkbox.checkmarkStyle = .tick
        titleLabel.text = myTitle
        contentLabel.text = content
        cancelButton.setTitle(textButtonCancel, for: .normal)
        continueButton.setTitle(textButtonContinue, for: .normal)
    }
}

func setupAndShowPopupIfNecessary(myTitle: String, content: String, textButtonCancel: String, textButtonContinue: String, key: String, currentVC: UIViewController, completionFunction: @escaping(() -> ()) ){ // nextVCIdentifier: String
    let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    let popup : PopupDontShowAgain = storyboard.instantiateViewController(withIdentifier: "PopupDontShowAgain") as! PopupDontShowAgain
    let s:String? = globalVar.gemsManager.getVariable(key)
    if(s == nil || s == ""){
        popup.setup(myTitle: myTitle, content: content, textButtonCancel: textButtonCancel, textButtonContinue: textButtonContinue, key: key, completionFunction: completionFunction)
        popup.modalTransitionStyle = .crossDissolve
        popup.modalPresentationStyle = .overCurrentContext
        currentVC.present(popup, animated: true, completion: nil)
    } else {
//        pushVC(identifier: nextVCIdentifier)
        completionFunction()
    }
}

func setupAndShowPopupWithoutVideo(userId:String, currentVC: UIViewController, completionFunction: @escaping(() -> ())) { // nextVCIdentifier: String
    setupAndShowPopupIfNecessary(myTitle: "Info",
                                 content: "Creating a song without video costs 3 gems, and you will get back 2 gems if you delete the song later. Continue ?", textButtonCancel: "Cancel", textButtonContinue: "Continue", key: userId + "_withoutVideo", currentVC: currentVC, completionFunction: completionFunction)
}

func setupAndShowPopupWithVideo(userId:String, currentVC: UIViewController, completionFunction: @escaping(() -> ())){ // nextVCIdentifier: String
    setupAndShowPopupIfNecessary(myTitle: "Info",
                                 content: "Creating a song with video costs 6 gems, and you will get back 4 gems if you delete the song later. Continue ?", textButtonCancel: "Cancel", textButtonContinue: "Continue", key: userId + "_withVideo", currentVC: currentVC, completionFunction: completionFunction)
}

func setupAndShowPopupImport(userId:String, currentVC: UIViewController, completionFunction: @escaping(() -> ())){
    setupAndShowPopupIfNecessary(myTitle: "Info",
                                 content: "Importing a song costs 10 gems, and you will get back 6 gems if you delete the song later. Continue ?", textButtonCancel: "Cancel", textButtonContinue: "Continue", key: userId + "_import", currentVC: currentVC, completionFunction: completionFunction)
}
