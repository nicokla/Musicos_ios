
import Foundation
import RealmSwift

class ChordConfiguration: Object {
    @objc dynamic var title: String = ""
    @objc dynamic var detail: String = ""
    
    let roots = List<Bool>() // 12 booleens, les true sont les roots actives
    let chordsNotes = List<ChordNotes>() // 36 = 3 lignes de 12 , let ???
    //@objc dynamic var detail2: Set<Int> = Set<Int>()
    let chordNames = List<String>() // 36, seulement une partie sont displayed
    
    convenience init(
                    title:String = "Major",
                    detail:String = "I+ II- III- IV+ V+ VI- VIIdim",
                    roots: [Bool]
                     = [true, false, true, false, true, true, false,
                        true, false, true, false, true]
                    ) {
        self.init()
        self.title = title
        self.detail = detail
        self.roots.append(objectsIn: roots)
        self.chordNames.append(objectsIn: globalVar.defaultChordNames!)
        globalVar.setsToDb(myChordNotes: globalVar.defaultConfig!, chordsNotes: self.chordsNotes)

    }
    
}
