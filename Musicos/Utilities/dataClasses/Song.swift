
import Foundation
import RealmSwift
import AudioKit

class Song: Object {
    @objc dynamic var id: String = "" // UUID().uuidString
    @objc dynamic var datetime: Int = 0
    @objc dynamic var title: String = ""
    @objc dynamic var videoID: String = ""
    @objc dynamic var imageUrl:  String = ""
    @objc dynamic var instru1_n:Int = 0
    @objc dynamic var instru2_n:Int = 0
    @objc dynamic var volumePlayer:Int = 100
    @objc dynamic var volumeRecording:Int = 90
    @objc dynamic var volumeYoutube:Float = 0.9
    @objc dynamic var noteNames:Int = 0
    @objc dynamic var rootNote:Int = 48
    //@objc dynamic var volumeYoutube:Int = 10 // 0 to 100
    @objc dynamic var duration:Float = 0
    @objc dynamic var showChords:Int = 0 // 0 : melody, 1 : chords, 2 : both
    @objc dynamic var originalID: String = "" // if imported, is the id of
    // the song which was copied. if not imported, value is "".

    let scale = List<Bool>()
    let chordsRoots = List<Bool>()
    let chordsNotes = List<ChordNotes>()
    let chordNames = List<String>()
    
    let notes = List<Note>()
    let notesAccompagnement = List<Accord>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func notesToDb(track:AKMusicTrack){
        let liste = track.getMIDINoteData()
        let realm = try! Realm()
        try! realm.write {
            notes.removeAll()
        }
        for i in 0 ..< liste.count{
            let note1 = liste[i]
            let note = Note(
                midiNote: Int(note1.noteNumber),
                start: Float(note1.position.seconds),
                duration: Float(note1.duration.seconds),
                velocity: Int(note1.velocity))
            try! realm.write {
                notes.append(note)
            }
        }
    }
    
    // [AKMIDINoteData]
    // track.getMIDINoteData()
    func dbToNotes(track:AKMusicTrack){
        //let track = AKMusicTrack()
        var iterator = notes.makeIterator()
        //var iii=0
        while let note = iterator.next() {
            track.add(midiNoteData:
                AKMIDINoteData(
                    noteNumber: UInt8(note.midiNote), //MIDINoteNumber
                    velocity: UInt8(note.velocity), //MIDIVelocity
                    channel: 0, //MIDIChannel
                    duration: AKDuration(seconds:Double(note.duration)),
                    position: AKDuration(seconds:Double(note.start))
                )
            )
        }
        //return track
    }
    
    
    
    func accompagnementToDb(mesAccords:[AccordSimple]){
        let realm = try! Realm()
        try! realm.write {
            notesAccompagnement.removeAll()
        }
        for i in 0 ..< mesAccords.count{
            let accord = Accord(accord: mesAccords[i])
            try! realm.write {
                notesAccompagnement.append(accord)
            }
        }
    }
    
    
    func dbToAccompagnement(trackChords:AKMusicTrack) -> [AccordSimple]{
        var mesAccords = [AccordSimple]()
        var iterator = notesAccompagnement.makeIterator()
        while let chord = iterator.next() {
            let acc = AccordSimple(start: chord.start, duration: chord.duration, notesRelative: Set<Int>(), ligne: chord.ligne, rootKeyModulo12: chord.rootKeyModulo12, rootNote: 60)
            var iterator2 = chord.notesAbsolute.makeIterator()
            while let note = iterator2.next(){
                trackChords.add(midiNoteData:
                    AKMIDINoteData(
                        noteNumber: UInt8(note), //MIDINoteNumber
                        velocity: UInt8(100), //MIDIVelocity
                        channel: 0, //MIDIChannel
                        duration: AKDuration(seconds:Double(chord.duration)),
                        position: AKDuration(seconds:Double(chord.start))
                    )
                )
                acc.notesAbsolute.insert(note)
            }
            mesAccords.append(acc)
        }
        return mesAccords
    }
    
    func realmToDataStruct() -> [AccordSimple]{
        var mesAccords = [AccordSimple]()
        var iterator = notesAccompagnement.makeIterator()
        while let chord = iterator.next() {
            let acc = AccordSimple(start: chord.start, duration: chord.duration, notesRelative: Set<Int>(), ligne: chord.ligne, rootKeyModulo12: chord.rootKeyModulo12, rootNote: 60)
            var iterator2 = chord.notesAbsolute.makeIterator()
            while let note = iterator2.next(){
                acc.notesAbsolute.insert(note)
            }
            mesAccords.append(acc)
        }
        return mesAccords
    }
    
}

