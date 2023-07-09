
import UIKit
import RealmSwift

class SettingsScaleVC2: UITableViewController, DropDownDelegate {
        
    @IBOutlet weak var notesNamesDropdown: DropDown!
    @IBOutlet weak var notesInstrumentDropdown: DropDown!
    @IBOutlet weak var chordsInstrumentDropdown: DropDown!
    
    let listeInstruments : [String] = globalVar.instruments.map { $0.copy() as! String }
    let copyNoteNameAll : [String] = globalVar.noteNamesAll.map { $0.copy() as! String }

    @IBAction func clearMelodyAction(_ sender: Any) {
        let alert = UIAlertController(title: "", message: "This will delete all melody notes. Are you sure ?", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler: { action in
            globalVar.track!.clear()
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: UIAlertAction.Style.cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func clearChordsAction(_ sender: Any) {
        let alert = UIAlertController(title: "", message: "This will delete all chords. Are you sure ?", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler: { action in
            globalVar.trackChords!.clear()
            globalVar.mesAccords.removeAll()
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: UIAlertAction.Style.cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // ----------------------

    func dropDown(_ dropDown: DropDown, didSelectItem item: Int){
        if dropDown == notesInstrumentDropdown {
            try! realm.write {
                globalVar.song!.instru1_n = item
            }
        } else if dropDown == chordsInstrumentDropdown {
            try! realm.write {
                globalVar.song!.instru2_n = item
            }
        } else if dropDown == notesNamesDropdown {
            try! realm.write {
                globalVar.song!.noteNames = item
            }
        }
    }
    
    // ----------------------------
    
    
    let realm = try! Realm()
    
    @IBOutlet weak var stackWithScale: UIStackView!
    
    @IBAction func noteGamme(_ sender: Any) {
        guard let myButton = sender as? UIButton else{
            print("c bizarre tiens.")
            return
        }
        
        if let scale = globalVar.song?.scale{
            do {
                try realm.write {
                    scale[myButton.tag] = !scale[myButton.tag]
                }
            } catch {
                print("Error deleting Item, \(error)")
            }
        }
        
        if( globalVar.song!.scale[myButton.tag] ){
            myButton.backgroundColor =  UIColor.white
        } else {
            myButton.backgroundColor = UIColor.gray
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        notesInstrumentDropdown.optionArray = listeInstruments
        notesInstrumentDropdown.delegateYoyo = self
        notesInstrumentDropdown.text = listeInstruments[globalVar.song!.instru1_n]
        
        chordsInstrumentDropdown.optionArray = listeInstruments
        chordsInstrumentDropdown.delegateYoyo = self
        chordsInstrumentDropdown.text = listeInstruments[globalVar.song!.instru2_n]
        
        notesNamesDropdown.optionArray = copyNoteNameAll
        notesNamesDropdown.delegateYoyo = self
        notesNamesDropdown.text = copyNoteNameAll[globalVar.song!.noteNames]
        
        for b in stackWithScale.subviews{
            if let bb = b as? UIButton{
                bb.backgroundColor = globalVar.song!.scale[bb.tag] ?
                    UIColor.white : UIColor.gray
            } else{print("unlogic. fuck you man.")}
        }
    }
}
