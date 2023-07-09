
import Foundation
import RealmSwift

class Note: Object{
    @objc dynamic var midiNote:Int = 60
    @objc dynamic var start:Float = 0
    @objc dynamic var duration:Float = 1
    @objc dynamic var velocity:Int = 100
    
    convenience init(midiNote:Int,start:Float,duration:Float,velocity:Int){
        self.init()
        self.midiNote = midiNote
        self.start = start
        self.velocity = velocity
        self.duration = duration
    }
}
