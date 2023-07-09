
import UIKit
import RealmSwift

class ChordConfigVC: UIViewController {
    var myChordConfig2:ChordConfiguration?
    var fromWhere:Int? // 1=listAlreadyExist, 2=listNew, 3=current
    var numList:Int? // nil = current, else indice de liste.
    var myNextVC:ChordConfigVC2?
    let realm = try! Realm()
    var myChordNotes = Array<Set<Int>>()
    var roots = Array<Bool>()
    var myChordNames = Array<String>()
    var myTitle : String?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func goBack(_ sender: Any) {
        // cas 1 --> on save dans le already exist list element (need ref to myChordConfig)
        // cas 2 --> on cree un new (no need for ref, on le cree on the fly a la fin)
        // cas 3 --> on save dans current (no need for ref, on n'utilise que l'interieur de song, donc jamais de structure de donnee de type ChordConfiguration)
        if fromWhere == 1 {
            globalVar.setsToDb(myChordNotes: myChordNotes, chordsNotes: myChordConfig2!.chordsNotes)
            globalVar.rootsToDb(roots: roots, rootsDb: myChordConfig2!.roots)
            globalVar.namesToDb(names: myChordNames, namesDb: myChordConfig2!.chordNames)
            try! realm.write {
                myChordConfig2!.title = myNextVC!.textFieldTitle!.text!
                myChordConfig2!.detail =
                    globalVar.getDetail(roots:roots, myChordNames:myChordNames)
            }
            performSegue(withIdentifier: "goBackToConfigList", sender: self)
        } else if fromWhere == 2 {
            let myChordConfig = ChordConfiguration()
            try! realm.write {
                realm.add(myChordConfig)
                myChordConfig.title = myNextVC!.textFieldTitle!.text!
                myChordConfig.detail =
                    globalVar.getDetail(roots:roots, myChordNames:myChordNames)
            }
            globalVar.setsToDb(myChordNotes: myChordNotes, chordsNotes: myChordConfig.chordsNotes)
            globalVar.rootsToDb(roots: roots, rootsDb: myChordConfig.roots)
            globalVar.namesToDb(names: myChordNames, namesDb: myChordConfig.chordNames)
            performSegue(withIdentifier: "goBackToConfigList", sender: self)
        } else if fromWhere == 3 {
            globalVar.setsToDb(myChordNotes: myChordNotes, chordsNotes: globalVar.song!.chordsNotes)
            globalVar.rootsToDb(roots: roots, rootsDb: globalVar.song!.chordsRoots)
            globalVar.namesToDb(names: myChordNames, namesDb: globalVar.song!.chordNames)
            performSegue(withIdentifier: "goBackToMasterFromDetails", sender: self)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "settingsChordsEmbeded" {
            if let nextVC = segue.destination as? ChordConfigVC2 {
                myNextVC = nextVC
                nextVC.parentVC = self
            }
        } else {
            // print("coucou toi")
        }
    }
    
    
    /*func getDetail() -> String{
        var s = ""
        for i in 0..<12{
            if(roots[i]){
                s += globalVar.notesRoman[i]
                s += myChordNames[i]
                s += " "
            }
        }
        return s
    }*/
    
}
