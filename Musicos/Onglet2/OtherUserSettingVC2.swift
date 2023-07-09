
import UIKit
import RealmSwift

class OtherUserSettingVC2: UITableViewController, DropDownDelegate {
    @IBOutlet weak var notesNamesDropdown: DropDown!
    @IBOutlet weak var notesInstrumentDropdown: DropDown!
    @IBOutlet weak var chordsInstrumentDropdown: DropDown!
    
    let listeInstruments : [String] = globalVar.instruments.map { $0.copy() as! String }
    let copyNoteNameAll : [String] = globalVar.noteNamesAll.map { $0.copy() as! String }

    func dropDown(_ dropDown: DropDown, didSelectItem item: Int){
        if dropDown == notesInstrumentDropdown {
            globalVar.songFirebase.songPourFile.instru1_n = item
        } else if dropDown == chordsInstrumentDropdown {
            globalVar.songFirebase.songPourFile.instru2_n = item
        } else if dropDown == notesNamesDropdown {
            globalVar.songFirebase.songPourFile.noteNames = item
        }
    }
    
    let realm = try! Realm()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notesInstrumentDropdown.optionArray = listeInstruments
        notesInstrumentDropdown.delegateYoyo = self
        notesInstrumentDropdown.text = listeInstruments[globalVar.songFirebase.songPourFile.instru1_n]
        
        chordsInstrumentDropdown.optionArray = listeInstruments
        chordsInstrumentDropdown.delegateYoyo = self
        chordsInstrumentDropdown.text = listeInstruments[globalVar.songFirebase.songPourFile.instru2_n]
        
        notesNamesDropdown.optionArray = copyNoteNameAll
        notesNamesDropdown.delegateYoyo = self
        notesNamesDropdown.text = copyNoteNameAll[globalVar.songFirebase.songPourFile.noteNames]
    }
}
