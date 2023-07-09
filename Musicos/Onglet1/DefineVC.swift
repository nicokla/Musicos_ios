import UIKit
import RealmSwift

class DefineVC: UIViewController, UITextFieldDelegate {

    let realm = try! Realm()
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var myStepper: UIStepper!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var myLabel: UILabel!
    var numMinutes:Int = 3
    var myTitle:String = ""
    
    @IBAction func letsPlayButtonAction(_ sender: Any) {
        do {
            try globalVar.gemsManager.subGems(3)
            let song = Song()
            
            song.title = titleTextField.text!
            song.duration = Float(numMinutes) * 60
            song.videoID = ""
            song.imageUrl = ""
            song.scale.removeAll()
            song.scale.append(objectsIn: [true, true, true, true, true, true, true, true, true, true, true, true])
            song.id = UUID().uuidString
            
            try! realm.write {
                realm.add(song)
            }
            
            // CRUD : Create song
            globalVar.firebaseSongsManager.createSongRealmToFirebase(song: song)

            // --------------------
            globalVar.song = song
            
            globalVar.setsToDb(myChordNotes: globalVar.defaultConfig!, chordsNotes: globalVar.song!.chordsNotes)
            globalVar.rootsToDb(roots: globalVar.defaultRoots, rootsDb: globalVar.song!.chordsRoots)
            globalVar.namesToDb(names: globalVar.defaultChordNames!, namesDb: globalVar.song!.chordNames)
            
            pushVC(identifier: "PlayerVC2")
        } catch GemsManagerError.insufficientFunds(let coinsNeeded) {
            proposeGemsPurchase(self)
        } catch {
            print("Unknown error")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        myLabel.text = String(numMinutes)
        titleTextField.delegate = self
    }
    
    @IBAction func myStepperChanged(_ sender: Any) {
        numMinutes = Int(myStepper.value)
        myLabel.text = String(numMinutes)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        return true
    }
}
