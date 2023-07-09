import UIKit
import RealmSwift

class ChordConfigImportVC: UIViewController , UIPickerViewDelegate, UIPickerViewDataSource{
    let realm = try! Realm()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    func popUpText(title:String,message:String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBOutlet weak var myPicker: UIPickerView!
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return globalVar.chordConfigs!.count //... globalVar.instruments.count
    }
    

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return globalVar.chordConfigs![row].title
        //"coucou"//globalVar.instruments[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
    }
    
    
    @IBAction func importChords(_ sender: Any) {
        let row = myPicker!.selectedRow(inComponent: 0)
        try! realm.write {
            globalVar.song!.chordsRoots.removeAll()
            globalVar.song!.chordsNotes.removeAll()
            globalVar.song!.chordNames.removeAll()
        }
        try! realm.write {
            globalVar.song!.chordsNotes.append(objectsIn: globalVar.chordConfigs![row].chordsNotes)
        }
        try! realm.write {
            globalVar.song!.chordsRoots.append(objectsIn:globalVar.chordConfigs![row].roots)
        }
        try! realm.write {
            globalVar.song!.chordNames.append(objectsIn:globalVar.chordConfigs![row].chordNames)
        }
        self.popUpText(title:"", message: "The current chord configuration has now been set to the chosen configuration.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

    @IBAction func goBack(_ sender: Any) {
        performSegue(withIdentifier: "unwindFromImportToMaster", sender: self)
    }
    
}
