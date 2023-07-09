
import Foundation
import AudioKit

func dbToNotes(track:AKMusicTrack, notes: [NoteStruct]){
    for note in notes {
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


func dbToAccompagnement(trackChords:AKMusicTrack, notesAccompagnement: [AccordSimple]){
    for chord in notesAccompagnement {
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
    }
}

