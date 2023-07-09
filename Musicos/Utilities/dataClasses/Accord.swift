
import Foundation
import RealmSwift

class Accord: Object{
    @objc dynamic var start:Float = 0
    @objc dynamic var duration:Float = 1
    @objc dynamic var ligne:Int = 0
    @objc dynamic var rootKeyModulo12:Int = 0
    // from rootKeyModulo12 you can deduce column and isDiese.

    let notesAbsolute = List<Int>()
    
    convenience init(start:Float,duration:Float, notesRelative:Set<Int>, ligne:Int, rootKeyModulo12:Int, rootNote:Int){
        self.init()
        self.start = start
        self.duration = duration
        for a in notesRelative{
            self.notesAbsolute.append(a+rootNote)
        }
        self.ligne = ligne
        self.rootKeyModulo12 = rootKeyModulo12
    }

    convenience init(start:Float,duration:Float, notesAbsolute:Set<Int>, ligne:Int, rootKeyModulo12:Int){
        self.init()
        self.start = start
        self.duration = duration
        self.notesAbsolute.append(objectsIn: notesAbsolute)
        self.ligne = ligne
        self.rootKeyModulo12 = rootKeyModulo12
    }

    convenience init(accord:AccordSimple){
        self.init()
        self.start = accord.start
        self.duration = accord.duration
        self.notesAbsolute.append(objectsIn: accord.notesAbsolute)
        self.ligne = accord.ligne
        self.rootKeyModulo12 = accord.rootKeyModulo12
    }
}
