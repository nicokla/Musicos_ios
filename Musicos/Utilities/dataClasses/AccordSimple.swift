
import Foundation

class AccordSimple:Codable {
    var start:Float = 0
    var duration:Float = 1
    var notesAbsolute = Set<Int>()
    var ligne = 0
    var rootKeyModulo12 = 0 // you can then deduce column
    
    init(start:Float,duration:Float, notesRelative:Set<Int>, ligne:Int, rootKeyModulo12:Int, rootNote:Int){
        self.start = start
        self.duration = duration
        for a in notesRelative{
            self.notesAbsolute.insert(a+rootNote)
        }
        self.ligne = ligne
        self.rootKeyModulo12 = rootKeyModulo12
    }
}
