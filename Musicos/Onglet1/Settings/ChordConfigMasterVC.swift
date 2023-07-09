import UIKit
import RealmSwift

class ChordConfigMasterVC: UIViewController {
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


    @IBAction func saveCurrent(_ sender: Any) {
        let myChordConfig = ChordConfiguration()
        try! realm.write {
            myChordConfig.title = "New configuration"
        }
        try! realm.write {
            myChordConfig.chordsNotes.append(objectsIn: globalVar.song!.chordsNotes)
        }
        try! realm.write{
            myChordConfig.roots.append(objectsIn: globalVar.song!.chordsRoots)
        }
        try! realm.write{
            myChordConfig.chordNames.append(objectsIn: globalVar.song!.chordNames)
        }
        try! realm.write {
            myChordConfig.detail =
                globalVar.getDetail(
                    roots:globalVar.dbToRoots(rootsDb: globalVar.song!.chordsRoots),
                    myChordNames:globalVar.dbToNames(namesDb: globalVar.song!.chordNames))
        }
        try! realm.write{
            realm.add(myChordConfig)
        }
        
        self.popUpText(title:"", message: "The current chord configuration has been saved.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(globalVar.chordConfigs!.count == 0){
            let myChordConfig = ChordConfiguration()
            try! realm.write {
                realm.add(myChordConfig)
                myChordConfig.title = "Majeur"
                myChordConfig.detail = "I IIm IIIm IV V VIm VIIdim"
            }
            globalVar.setsToDb(myChordNotes: globalVar.defaultConfig!, chordsNotes: myChordConfig.chordsNotes)
            globalVar.rootsToDb(roots: globalVar.defaultRoots, rootsDb: myChordConfig.roots)
            globalVar.namesToDb(names: globalVar.defaultChordNames!, namesDb: myChordConfig.chordNames)
        }
    }
    
    @IBAction func unwindToConfigMaster(segue:UIStoryboardSegue) {
    }

    @IBAction func comeBack(_ sender: Any) {
        performSegue(withIdentifier: "unwindingToSettings", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "letsEditLocalConfig" {
            if let nextVC = segue.destination as? ChordConfigVC{
                nextVC.fromWhere = 3
                nextVC.numList = -1
                nextVC.myChordNotes = globalVar.dbToSets(chordsNotes: globalVar.song!.chordsNotes)
                nextVC.roots = globalVar.dbToRoots(rootsDb: globalVar.song!.chordsRoots)
                nextVC.myChordNames = globalVar.dbToNames(namesDb: globalVar.song!.chordNames)
            }
        }
    }
    
    
}
