
import UIKit
import RealmSwift
import AudioKit

class ChordConfigVC2: UITableViewController, UITextFieldDelegate {
    let realm = try! Realm()
    
    @IBOutlet weak var rootsStack1: UIStackView!
    @IBOutlet weak var rootsStack2: UIStackView!
    @IBOutlet weak var rootsStack3: UIStackView!
    
    @IBOutlet weak var chordNotesStack1: UIStackView!
    @IBOutlet weak var chordNotesStack2: UIStackView!
    @IBOutlet weak var chordNotesStack3: UIStackView!
    
    @IBOutlet weak var stackWithRootsDef: UIStackView!
    
    @IBOutlet weak var textFieldTitle: UITextField!
    @IBOutlet weak var textFieldChordName: UITextField!
    
    var parentVC:ChordConfigVC?
    var rootsStacks = [UIStackView]()
    var chordNotesStacks = [UIStackView]()
    let noteColumn = [0,1,1,2,2,3,4,4,5,5,6,6]
    let noteLine =   [0,1,0,1,0,0,1,0,1,0,1,0]
    var rootNote:Int = 48
    var baseRelative:Int = 0 // base des notes en bas, / à rootNote. multiple de 12.
    let currentVelocity:UInt8 = 90 // 127
    var sampler : AKAppleSampler?
    var dico=[Int:UIButton]() // dico des boutons du bas
    var currentRootTag = 0
    var dicoRoots=[Int:UIButton]() // dico des boutons du haut

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if(textField == textFieldTitle){
            parentVC!.myTitle = textField.text!
        } else {
            parentVC!.myChordNames[currentRootTag] = textField.text!
            var buttonName = globalVar.notesRoman[currentRootTag % 12]
            buttonName += textField.text!
            let button = dicoRoots[currentRootTag]
            button!.setTitle(buttonName, for: [])
        }
    }
    
    @IBAction func guessChordsFromScale(_ sender: Any) {
        //guard let playerVC = self.presentingViewController as? PlayerVC else {return} //parentVC!.parent
        
        let alert = UIAlertController(title: "", message: "This will replace all chords of the configuration. Are you sure ?", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler: { action in
            self.parentVC!.myChordNotes = globalVar.buildDefaultSetsPrepare(myBooleans:self.parentVC!.roots)
            self.parentVC!.myChordNames = globalVar.guessNames(config: self.parentVC!.myChordNotes)
            self.updateRootsStacks(stackviews:self.rootsStacks)
        }))
        alert.addAction(UIAlertAction(title: "No", style: UIAlertAction.Style.cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textFieldTitle.delegate = self
        /*if(parentVC!.numList! >= 0){ // si on n'edite pas le current config
            textFieldTitle.text = globalVar.chordConfigs![parentVC!.numList!].title
        }*/
        if(parentVC!.myTitle != nil){
            textFieldTitle.text = parentVC!.myTitle!
        }
        
        textFieldChordName.delegate = self
        
        
        rootsStacks=[rootsStack1,rootsStack2,rootsStack3]
        chordNotesStacks=[chordNotesStack1,chordNotesStack2,chordNotesStack3]
        
        for b in stackWithRootsDef.subviews{
            if let bb = b as? UIButton{
                bb.backgroundColor = parentVC!.roots[bb.tag] ?
                    UIColor.white : UIColor.gray
            } else{print("snif.")}
        }

        rootNote = globalVar.song!.rootNote
        rootNote = ((rootNote - 40) % 12) + 40 // project in midi(40 to 51), like guitar
        
        updateRootsStacks(stackviews:rootsStacks)
        updateChordNotesStacks(stackviews:chordNotesStacks)
        
        updateChordNotesColors()
    }


    @IBAction func buttonRoot(_ sender: Any) {
        guard let myButton = sender as? UIButton else{
            print("c bizarre tiens.")
            return
        }
        let tag = myButton.tag
        parentVC!.roots[tag] = !parentVC!.roots[tag]
        
        if( parentVC!.roots[tag] ){
            myButton.backgroundColor = UIColor.white
        } else {
            myButton.backgroundColor = UIColor.gray
        }
        
        //textFieldChordName.text = parentVC!.myChordNames[tag]
        // print(myButton.tag)
        updateRootsStacks(stackviews:rootsStacks)
        //updateChordNotesStacks()
    }

    
    func updateRootsStacks(stackviews:[UIStackView]){
        //let stackviews = rootsStacks
        
        // clearing the old arrangement
        for stack in stackviews {
            for view in stack.subviews {
                view.removeFromSuperview()
            }
        }
        
        // filling the stackviews with new arrangement
        var oldColumn = -1
        var noteNumber = 60
        var buttonName = ""
        //var currentSubStackView = UIStackView()
        for i in 0 ..< 12 {
            // do we need a sub-stackview ?
            if(noteColumn[i] != oldColumn) {
                oldColumn = noteColumn[i]
                for stack in stackviews {
                    let subStackView = UIStackView()
                    subStackView.axis = .vertical
                    subStackView.alignment = .fill
                    subStackView.distribution = .fillEqually
                    //currentSubStackView = subStackView
                    stack.addArrangedSubview(subStackView)
                }
            }
            if(parentVC!.roots[i]) {
                for (index, stack) in stackviews.enumerated() {
                    let button = UIButton(type: UIButton.ButtonType.system)
                    
                    noteNumber = i + (index * 12)
                    button.tag = noteNumber
                    dicoRoots[noteNumber] = button
                    
                    button.layer.cornerRadius = 5
                    button.layer.borderColor = UIColor.black.cgColor
                    button.layer.borderWidth = 2
                    
                    if(noteLine[i] == 1){
                        button.backgroundColor = UIColor.lightGray
                    } else{
                        button.backgroundColor = UIColor.white
                    }
                    
                    //buttonName = globalVar.notes[noteNumber]
                    buttonName = globalVar.notesRoman[i] // % 12
                //globalVar.chordConfigs![parentVC!.numList!].chordNames[...]
                    buttonName += parentVC!.myChordNames[noteNumber]
                    button.setTitle(buttonName, for: [])
                    button.setTitleColor(UIColor.black, for: [])
                    
                    if(UIDevice.current.userInterfaceIdiom == .pad){
                        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
                    }
                    
                    if let currentSubStackView = stack.arrangedSubviews.last as? UIStackView{
                        currentSubStackView.addArrangedSubview(button)
                    } else {print("bizarre bizarre.")}
                    
                    button.addTarget(self,
                                     action: #selector(rootButton),
                                     for: .touchDown)
                    button.addTarget(self,
                                     action: #selector(rootButtonUp),
                                     for: .touchUpInside)
                }
            }
        }
    }

    @IBAction func rootButton(_ sender: UIButton) {
        for i in parentVC!.myChordNotes[sender.tag] {
            try! globalVar.sampler.play(noteNumber: UInt8(rootNote + i),
                          velocity: currentVelocity,
                          channel: 0)
        }
        currentRootTag = sender.tag
        textFieldChordName.text = parentVC!.myChordNames[sender.tag]
        updateChordNotesColors() // set: myChordNotes[sender.tag]
    }
    
    @IBAction func rootButtonUp(_ sender: UIButton) {
        for i in parentVC!.myChordNotes[sender.tag] {
            try! globalVar.sampler.stop(noteNumber: UInt8(rootNote + i), channel: 0)
        }
    }

    @IBAction func notesButton(_ sender: UIButton) {
        let n=baseRelative + sender.tag
        try! globalVar.sampler.play(noteNumber: UInt8(rootNote + n),
            velocity: currentVelocity,
            channel: 0)
        if(!parentVC!.myChordNotes[currentRootTag].contains(n)){
            parentVC!.myChordNotes[currentRootTag].insert(n)
        } else {
            parentVC!.myChordNotes[currentRootTag].remove(n)
        }
        updateChordNotesColors()
    }

    @IBAction func notesButtonUp(_ sender: UIButton) {
        let n=baseRelative + sender.tag
        try! globalVar.sampler.stop(noteNumber: UInt8(rootNote + n), channel: 0)
    }

    // myChordNotes[currentRootTag]   //sender.tag
    func updateChordNotesColors(){ //set:Set<Int>
        let set = parentVC!.myChordNotes[currentRootTag]
        for i in 0 ..< 36 {
            dico[i]!.backgroundColor = UIColor.white
        }
        for a in set {
            let b = a - baseRelative // le chiffre en tant que bouton
            if( b >= 0 && b < 36 ){ // si le bouton est sur les 3 lignes
                dico[b]!.backgroundColor = UIColor.green
            }
        }
        
        // en fait aussi les couleurs des boutons du haut (why not?)
        for i in 0 ..< 36 {
            if(parentVC!.roots[i % 12]){
                dicoRoots[i]!.backgroundColor = UIColor.white
            }
        }
        dicoRoots[currentRootTag]!.backgroundColor = UIColor.green
    }
    
    func updateChordNotesStacks(stackviews:[UIStackView]){
       // let  = chordNotesStacks
        
        // clearing the old arrangement
        for stack in stackviews {
            for view in stack.subviews {
                view.removeFromSuperview()
                //view = nil // is it really necessary ?
            }
        }
        
        // filling the stackviews with new arrangement
        var oldColumn = -1
        var noteNumber = 60
        var buttonName = ""
        //var currentSubStackView = UIStackView()
        for i in 0 ..< 12 {
            // do we need a sub-stackview ?
            if(noteColumn[i] != oldColumn) {
                oldColumn = noteColumn[i]
                for stack in stackviews {
                    let subStackView = UIStackView()
                    subStackView.axis = .vertical
                    //currentSubStackView = subStackView
                    subStackView.alignment = .fill
                    subStackView.distribution = .fillEqually
                    stack.addArrangedSubview(subStackView)
                }
            }
            for (index, stack) in stackviews.enumerated() {
                let button = UIButton(type: UIButton.ButtonType.system)
                
                noteNumber = i + (index * 12)
                button.tag = noteNumber
                dico[noteNumber] = button
                    
                button.layer.cornerRadius = 5
                button.layer.borderColor = UIColor.black.cgColor
                button.layer.borderWidth = 2
                
                if(noteLine[i] == 1){
                    button.backgroundColor = UIColor.lightGray
                } else{
                    button.backgroundColor = UIColor.white
                }
                
                //buttonName = globalVar.notes[noteNumber]
                buttonName = globalVar.notesRoman[i % 12]
                button.setTitle(buttonName, for: [])
                button.setTitleColor(UIColor.black, for: [])
                
                if(UIDevice.current.userInterfaceIdiom == .pad){
                    button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
                }

                if let currentSubStackView = stack.arrangedSubviews.last as? UIStackView{
                    currentSubStackView.addArrangedSubview(button)
                } else {print("bizarre bizarre.")}
                
                button.addTarget(self,
                                 action: #selector(notesButton),
                                 for: .touchDown)
                button.addTarget(self,
                                 action: #selector(notesButtonUp),
                                 for: .touchUpInside)
            }
        }
    }
    

}



