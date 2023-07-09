
import Foundation
import RealmSwift
import AudioKit

class GlobalVar {
    let callbackInstr = AKMIDICallbackInstrument(callback: {
        (a:UInt8, b:MIDINoteNumber, c:MIDIVelocity) in
        switch(a){
        case 144, 157:
            try! globalVar.sampler.play(noteNumber: b,velocity: globalVar.velocityRecordingNotes ,channel: 0)
            break;
        default:
            try! globalVar.sampler.stop(noteNumber: b, channel: 0)
            break;
        }
    })
    
    let callbackChords = AKMIDICallbackInstrument(callback: {
        (a:UInt8, b:MIDINoteNumber, c:MIDIVelocity) in
        switch(a){
        case 144, 157:
            try! globalVar.samplerChords.play(noteNumber: b,velocity: globalVar.velocityRecordingChords ,channel: 0)
            break;
        default:
            try! globalVar.samplerChords.stop(noteNumber: b, channel: 0)
            break;
        }
    })
    
    let emptyCallBack = AKMIDICallbackInstrument(callback: {
        (a:UInt8, b:MIDINoteNumber, c:MIDIVelocity) in
    })
    
    var explainsThatYoutubeSucks = false
    let myIAPService = IAPService()
    let firebaseSongsManager = FirebaseSongsManager()
    let gemsManager = GemsManager()
    var userId: String = ""
    var userName: String = ""
    var sequencer : AKAppleSequencer = AKAppleSequencer()
    var track:AudioKit.AKMusicTrack? // AKMusicTrack()
    var trackChords:AudioKit.AKMusicTrack?
    var trackTime:AudioKit.AKMusicTrack?
    var mesAccords = [AccordSimple]()
    var coucou:Int
    let realm = try! Realm()
    var chordConfigs: Results<ChordConfiguration>?
    var song: Song?
    let defaultRoots = [true, false, true, false, true, true, false,
                        true, false, true, false, true]
    var defaultConfig:Array<Set<Int>>?
    var defaultChordNames:Array<String>?
    var youtubeIsMuted = false
    var currentVelocity:UInt8 = 100
    var velocityRecording:UInt8 = 90 {
        didSet{
            updateBalanceNotesVsChords(val: balanceNotesVsChords)
        }
    }
    var balanceNotesVsChords: Float = 0.5 {
        didSet{
            updateBalanceNotesVsChords(val: balanceNotesVsChords)
        }
    }
    var velocityRecordingNotes:UInt8 = 90
    var velocityRecordingChords:UInt8 = 90
    
    var modeAffichage:Int = 0 // 0 = ecriture, 1 = in between, 2 = lecture

    let modeAffichageNames = ["Write", "In between", "Read"]
    
    let noteNamesAll = ["US", "French", "Relative Roman", "Relative Numeric", "None"]
    
    let instruments =
        ["Acoustic Grand Piano", "Bright Acoustic Piano", "Electric Grand Piano",
     "Honky-tonk Piano", "Electric Piano 1", "Electric Piano 2", "Harpsichord", "Clavi", "Celesta", "Glockenspiel",
     "Music Box", "Vibraphone", "Marimba", "Xylophone", "Tubular Bells", "Dulcimer", "Drawbar Organ", "Percussive Organ", "Rock Organ", "Church Organ",
     "Reed Organ", "Accordion", "Harmonica", "Tango Accordion", "Acoustic Guitar (nylon)", "Acoustic Guitar (steel)",
     "Electric Guitar (jazz)", "Electric Guitar (clean)", "Electric Guitar (muted)", "Overdriven Guitar",
     "Distortion Guitar", "Guitar harmonics", "Acoustic Bass", "Electric Bass (finger)",
     "Electric Bass (pick)", "Fretless Bass", "Slap Bass 1", "Slap Bass 2", "Synth Bass 1", "Synth Bass 2", "Violin",
     "Viola", "Cello", "Contrabass", "Tremolo Strings", "Pizzicato Strings", "Orchestral Harp", "Timpani", "String Ensemble 1", "String Ensemble 2",
     "SynthStrings 1", "SynthStrings 2", "Choir Aahs", "Voice Oohs", "Synth Voice", "Orchestra Hit",
     "Trumpet", "Trombone", "Tuba", "Muted Trumpet", "French Horn", "Brass Section", "SynthBrass 1", "SynthBrass 2",
     "Soprano Sax", "Alto Sax", "Tenor Sax", "Baritone Sax", "Oboe", "English Horn", "Bassoon", "Clarinet", "Piccolo", "Flute", "Recorder", "Pan Flute",
     "Blown Bottle", "Shakuhachi", "Whistle", "Ocarina", "Lead 1 (square)", "Lead 2 (sawtooth)",
     "Lead 3 (calliope)", "Lead 4 (chiff)", "Lead 5 (charang)", "Lead 6 (voice)", "Lead 7 (fifths)", "Lead 8 (bass + lead)", "Pad 1 (new age)", "Pad 2 (warm)",
     "Pad 3 (polysynth)", "Pad 4 (choir)", "Pad 5 (bowed)", "Pad 6 (metallic)", "Pad 7 (halo)", "Pad 8 (sweep)",
     "FX 1 (rain)", "FX 2 (soundtrack)", "FX 3 (crystal)", "FX 4 (atmosphere)", "FX 5 (brightness)", "FX 6 (goblins)", "FX 7 (echoes)", "FX 8 (sci-fi)",
     "Sitar", "Banjo", "Shamisen", "Koto", "Kalimba", "Bag pipe", "Fiddle", "Shanai", "Tinkle Bell", "Agogo", "Steel Drums", "Woodblock", "Taiko Drum",
     "Melodic Tom", "Synth Drum", "Reverse Cymbal", "Guitar Fret Noise", "Breath Noise", "Seashore", "Bird Tweet", "Telephone Ring", "Helicopter",
     "Applause", "Gunshot"]
    
    let notes =
          ["C-1","C#-1","D-1","Eb-1","E-1","F-1","F#-1","G-1","Ab-1","A-1","Bb-1","B-1",
           "C0","C#0","D0","Eb0","E0","F0","F#0","G0","Ab0","A0","Bb0","B0",
           "C1","C#1","D1","Eb1","E1","F1","F#1","G1","Ab1","A1","Bb1","B1",
           "C2","C#2","D2","Eb2","E2","F2","F#2","G2","Ab2","A2","Bb2","B2",
           "C3","C#3","D3","Eb3","E3","F3","F#3","G3","Ab3","A3","Bb3","B3",
           "C4","C#4","D4","Eb4","E4","F4","F#4","G4","Ab4","A4","Bb4","B4",
           "C5","C#5","D5","Eb5","E5","F5","F#5","G5","Ab5","A5","Bb5","B5",
           "C6","C#6","D6","Eb6","E6","F6","F#6","G6","Ab6","A6","Bb6","B6",
           "C7","C#7","D7","Eb7","E7","F7","F#7","G7","Ab7","A7","Bb7","B7",
           "C8","C#8","D8","Eb8","E8","F8","F#8","G8","Ab8","A8","Bb8","B8",
           "C9","C#9","D9","Eb9","E9","F9","F#9","G9"]

    let notesFrench =
["Do-1","Do#-1","Re-1","Mib-1","Mi-1","Fa-1","Fa#-1","Sol-1","Lab-1","La-1","Sib-1","Si-1","Do0","Do#0","Re0","Mib0","Mi0","Fa0","Fa#0","Sol0","Lab0","La0","Sib0","Si0",
    "Do1","Do#1","Re1","Mib1","Mi1","Fa1","Fa#1","Sol1","Lab1","La1","Sib1","Si1",
    "Do2","Do#2","Re2","Mib2","Mi2","Fa2","Fa#2","Sol2","Lab2","La2","Sib2","Si2",
    "Do3","Do#3","Re3","Mib3","Mi3","Fa3","Fa#3","Sol3","Lab3","La3","Sib3","Si3",
    "Do4","Do#4","Re4","Mib4","Mi4","Fa4","Fa#4","Sol4","Lab4","La4","Sib4","Si4",
    "Do5","Do#5","Re5","Mib5","Mi5","Fa5","Fa#5","Sol5","Lab5","La5","Sib5","Si5",
    "Do6","Do#6","Re6","Mib6","Mi6","Fa6","Fa#6","Sol6","Lab6","La6","Sib6","Si6",
    "Do7","Do#7","Re7","Mib7","Mi7","Fa7","Fa#7","Sol7","Lab7","La7","Sib7","Si7",
    "Do8","Do#8","Re8","Mib8","Mi8","Fa8","Fa#8","Sol8","Lab8","La8","Sib8","Si8",
    "Do9","Do#9","Re9","Mib9","Mi9","Fa9","Fa#9","Sol9"]

    let notesRoman = ["I", "IIb", "II", "IIIb", "III", "IV", "Vb", "V", "VIb", "VI", "VIIb", "VII"]
    let notesLatin = ["1", "2b", "2", "3b", "3", "4", "5b", "5", "6b", "6", "7b", "7"]
    let notesFrenchAccords = ["Do","Do#","Re","Mib","Mi","Fa","Fa#","Sol","Lab","La","Sib","Si"]
    let notesUSAccords =
    ["C","C#","D","Eb","E","F","F#","G","Ab","A","Bb","B"]
    
    var sampler : AKAppleSampler = AKAppleSampler()
    var samplerChords : AKAppleSampler = AKAppleSampler()
    var currentSampler : AKAppleSampler = AKAppleSampler()
    var mixer : AKMixer?
    
    var dico = Dictionary<Int,String>()
    var myChordNames = [ChordName]()
    
    var songFirebase = SongStructAll(
        songPourDb : SongStruct(
            title: "titrepourri",
            videoID: "videoidpourrie",
            datetime: Int(Date().timeIntervalSince1970.milliseconds/1000),
            imageUrl: "www.fakeurl.com",
            duration: 63.2,
            ownerID: "fakeOwnerId",
            ownerName: "fakeOwnerName",
            objectID: "fakeSongID",
            originalID: ""
        ),
        songPourFile : SongStruct2(
            instru1_n: 0,
            instru2_n: 0,
            volumeRecording: 90,
            volumePlayer: 90,
            volumeYoutube: 1,
            rootNote: 48,
            noteNames: 0,
            showChords: 0,
            scale:[true, true, true, true, true, true, true,
                   true, true, true, true, true],
            notes:[],
            chordsRoots: [true, false, true, false, true, true, false,
                          true, false, true, false, true],
            chordNames: ["+","","-","","-","+","","+","","-","","dim",
                         "Δ","","m7","","m7","Δ","","7","","m7","","ø",
                         "Δ","","m7","","m7","Δ","","7","","m7","","ø"],
            chordsNotes:[],
            notesAccompagnement:[]
        )
    )
    
    var watchedUser : UserStruct = UserStruct(name: "", objectID: "")
    var defaultChordNotes = [Set<Int>]()

    // !!!!!
    init(){
        let liste = [[4,7,0],[],[2,9,5],[],[11,7,4],[9,5,12],[],[11,14,7],[],[16,9,12],[],[17,14,11],[11,0,7,4],[],[12,2,9,5],[],[14,11,4,7],[5,12,16,9],[],[7,14,11,17],[],[19,9,12,16],[],[17,14,11,21],[7,11,4,0],[],[2,5,9,12],[],[4,11,7,14],[16,5,12,9],[],[7,17,14,11],[],[16,12,9,19],[],[11,21,14,17]]
        defaultChordNotes.removeAll()
        for l in liste{
            defaultChordNotes.append(Set(l))
        }
        songFirebase.songPourFile.chordsNotes = defaultChordNotes
        
        coucou = 1
        chordConfigs = realm.objects(ChordConfiguration.self)

        defaultConfig = buildDefaultSetsPrepare(myBooleans: defaultRoots)
        
//        loadInstrumentsInSampler(instru:0, instruChords:0)
//        currentSampler = sampler
            
        myChordNames.append(ChordName(v:[], name:""))
        myChordNames.append(ChordName(v:[0,4,7], name:"+"))
        myChordNames.append(ChordName(v:[0,4,8], name:"aug"))
        myChordNames.append(ChordName(v:[0,3,7], name:"-"))
        myChordNames.append(ChordName(v:[0,3,6], name:"dim"))
        myChordNames.append(ChordName(v:[0,4,7,10], name:"7"))
        myChordNames.append(ChordName(v:[0,4,7,11], name:"Δ")) // M7
        myChordNames.append(ChordName(v:[0,3,7,10], name:"m7"))
        myChordNames.append(ChordName(v:[0,3,6,10], name:"ø")) //m7b5
        myChordNames.append(ChordName(v:[0,3,6,9], name:"dim7"))
        
        for chordName in myChordNames {
            let x = getIntOfVector2(v: chordName.v)
            // print("\(x), \(chordName.name)")
            dico[x] = chordName.name
        }
        
        defaultChordNames = guessNames(config: defaultConfig!)
        
        print("chord names !!! :")
        for (index,s) in defaultChordNames!.enumerated() {
            print("\(index), \(s)")
        }
    }
    
    func guessNames(config:Array<Set<Int>>) -> [String]{
        var myStrings:[String] = []
        for (index,mySet) in config.enumerated() {
            myStrings.append(guessName(set: mySet, index:index))
        }
        return myStrings
    }
    
    func guessName(set:Set<Int>, index:Int) -> String{
        var v = [Bool](repeating: false, count: 12)
        for e in set {
            let projection = (e + 1200 - index) % 12
            v[projection] = true
        }
        let answer = dico[getIntOfVector(v: v), default: "?"]
        return answer
    }

    
    func getIntOfVector(v:[Bool]) -> Int{
        var multiplier = 1
        var somme = 0
        for value in v {
            if value {
                somme += multiplier
            }
            multiplier *= 2
        }
        return somme
    }
    
    func getIntOfVector2(v:[Int]) -> Int{
        var multiplier = 1
        var somme = 0
        var j = 0
        for i in 0..<12 {
            if j >= v.count{
                break
            }
            if i == v[j] {
                somme += multiplier
                j+=1
            }
            multiplier *= 2
        }
        return somme
    }

    func loadInstrumentsInSampler(instru:Int, instruChords:Int, showChords:Int){
        do{
            //  TimGM6mb.sf2     gs_instruments.dls      MuseScore_General.sf3
            //sampler.loadSoundFont("TimGM6mb", preset: 0, bank: 0)
            //sampler.loadPath("MuseScore_General.sf3")
            try AKManager.stop()
            try sampler.loadMelodicSoundFont("TimGM6mb", preset: instru)
            try samplerChords.loadMelodicSoundFont("TimGM6mb", preset: instruChords)
            mixer = AKMixer(sampler, samplerChords)
            AKManager.output = mixer!
            updateCurrentSampler(showChords: showChords)
            try AKManager.start()
        } catch {
            print("couldn't load sf2 file")
        }
    }

    func updateCurrentSampler(showChords:Int){
        switch(showChords % 2){
        case 0:
            currentSampler = sampler
        case 1:
            currentSampler = samplerChords
        default:
            currentSampler = sampler
        }
    }
    
    func rootsToDb(roots:Array<Bool>, rootsDb:List<Bool>){
        let realm = try! Realm()
        try! realm.write {
            rootsDb.removeAll()
        }
        for i in 0 ..< roots.count{
            try! realm.write {
                rootsDb.append(roots[i])
            }
        }
    }
    
    func dbToRoots(rootsDb:List<Bool>) -> Array<Bool>{
        var roots = Array<Bool>()
        var iterator = rootsDb.makeIterator()
        while let myBool = iterator.next() {
            roots.append(myBool)
        }
        return roots
    }
    
    
    func namesToDb(names:Array<String>, namesDb:List<String>){
        let realm = try! Realm()
        try! realm.write {
            namesDb.removeAll()
        }
        for i in 0 ..< names.count{
            try! realm.write {
                namesDb.append(names[i])
            }
        }
    }
    
    func dbToNames(namesDb:List<String>) -> Array<String>{
        var names = Array<String>()
        var iterator = namesDb.makeIterator()
        while let name = iterator.next() {
            names.append(name)
        }
        return names
    }

    
    
    func dbToSets(chordsNotes:List<ChordNotes>) -> [Set<Int>] {
        var myChordNotes = [Set<Int>]()
        myChordNotes = []
        var iterator = chordsNotes.makeIterator()
        var iii=0
        while let set = iterator.next() {
            //set.notes.filter("")
            myChordNotes.append(Set<Int>())
            var iterator2 = set.notes.makeIterator()
            while let set2 = iterator2.next() {
                myChordNotes[iii].insert(set2)
            }
            iii += 1
        }
        return myChordNotes
    }
    
    func setsToDb(myChordNotes:Array<Set<Int>>, chordsNotes:List<ChordNotes>){
        // let chordsNotes = List<ChordNotes>()
        let realm = try! Realm()
        try! realm.write {
            chordsNotes.removeAll()
        }
        for i in 0 ..< myChordNotes.count{
            let myList = ChordNotes()
            for a in myChordNotes[i]{
                myList.notes.append(a)
            }
            try! realm.write {
                chordsNotes.append(myList)
            }
        }
        // return chordsNotes
    }
    
    func getNoteList(myBooleans:[Bool]) -> [Int]{
        var l:[Int] = []
        for i in 0..<12{
            if myBooleans[i] {
                l.append(i)
            }
        }
        return l
    }
    
    func buildDefaultSetsPrepare(myBooleans:[Bool]) -> [Set<Int>] {
        var myChordNotes = [Set<Int>]()
        let l = getNoteList(myBooleans: myBooleans)
        myChordNotes = [] // memory leak ?
        var l2 = l + l
        for i in l.count ..< l2.count{
            l2[i] += 12
        }
        
        // useless ? useful only if array elmts initialized by swift as nil
        for i in 0 ..< 36 {
            myChordNotes.append(Set<Int>())
        }
        
        for i in 0 ..< l.count{
            let j = l[i]
            myChordNotes[j].insert(l2[i])
            myChordNotes[j].insert(l2[i+2])
            myChordNotes[j].insert(l2[i+4])
            
            //myChordNotes[i+12].insert(myChordNotes[i])
            myChordNotes[j+12].insert(l2[i])
            myChordNotes[j+12].insert(l2[i+2])
            myChordNotes[j+12].insert(l2[i+4])
            myChordNotes[j+12].insert(l2[i+6])
            
            //myChordNotes[i+24].insert(myChordNotes[i+12])
            myChordNotes[j+24].insert(l2[i])
            myChordNotes[j+24].insert(l2[i+2])
            myChordNotes[j+24].insert(l2[i+4])
            myChordNotes[j+24].insert(l2[i+6])
        }
        
        return myChordNotes
    }
    
    func getDetail(roots:[Bool], myChordNames:[String]) -> String{
        var s = ""
        for i in 0..<12{
            if(roots[i]){
                s += globalVar.notesRoman[i]
                s += myChordNames[i]
                s += " "
            }
        }
        return s
    }
    
    func updateBalanceNotesVsChords(val: Float){
        if val < 0.5{
            let ratio = val / 0.5 // (1 - val)
            let volume = globalVar.velocityRecording
            globalVar.velocityRecordingChords = UInt8(Float(volume) * ratio)
            globalVar.velocityRecordingNotes = volume
        }else{
            let ratio = (1 - val) / 0.5 // val
            let volume = globalVar.velocityRecording
            globalVar.velocityRecordingChords = volume
            globalVar.velocityRecordingNotes = UInt8(Float(volume) * ratio)
        }
    }
    
    func setSequencerFromSongPart1(firebaseNotRealm: Bool){
        sequencer = AKAppleSequencer()
        
//        for i in 0 ..< sequencer.trackCount{
//            sequencer.deleteTrack(trackIndex: i)
//        }
        
        sequencer.setTempo(60)

        track = sequencer.newTrack()!
        if firebaseNotRealm{
            dbToNotes(track: track!, notes: songFirebase.songPourFile.notes)
        }
        else{
            song!.dbToNotes(track: track!)
        }
        track!.setMIDIOutput(callbackInstr.midiIn)

        trackChords = sequencer.newTrack()!
        if firebaseNotRealm{
            mesAccords = songFirebase.songPourFile.notesAccompagnement
            dbToAccompagnement(trackChords: trackChords!, notesAccompagnement: mesAccords)
        }else{
            mesAccords = song!.dbToAccompagnement(trackChords: trackChords!)
        }
        trackChords!.setMIDIOutput(callbackChords.midiIn)
    }
    
    func setSequencerFromSong(firebaseNotRealm: Bool){
        setSequencerFromSongPart1(firebaseNotRealm: firebaseNotRealm)
        sequencer.rewind()
        sequencer.preroll()
    }
        
    func reset(){
        globalVar.sequencer.stop()
        do {
            try AKManager.stop()
        } catch {
            print("Oops! AudioKit didn't stop!")
        }
        for i in 0 ..< sequencer.trackCount{
            sequencer.deleteTrack(trackIndex: i)
        }
        globalVar.track = nil
        globalVar.trackChords = nil
        globalVar.trackTime = nil
        globalVar.mesAccords = []
    }

}

var globalVar = GlobalVar()


