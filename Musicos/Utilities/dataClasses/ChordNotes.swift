

import Foundation
import RealmSwift

class ChordNotes: Object {
    let notes: List<Int> = List<Int>() // Set<Int>
    
    convenience init(set:Set<Int>){
        self.init()
        notes.removeAll()
        for a in set{
            notes.append(a)
        }
    }
}
