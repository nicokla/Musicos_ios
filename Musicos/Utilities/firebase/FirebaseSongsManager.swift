import Foundation
import RealmSwift
import AlgoliaSearchClient
import Firebase
import CodableFirebase

// CRUD
let mySuperId = "machinChouette"

public struct SongStruct: Codable {
    var title: String
    var videoID: String
    var datetime: Int
    var imageUrl: String
    var duration: Float
    var ownerID: String
    var ownerName: String
    var objectID: String
    var originalID: String
}

public struct UserStruct: Codable {
    var name: String
    var objectID: String
}

// ---------------------------

struct NoteStruct: Codable{
    var midiNote: Int
    var start: Float
    var duration: Float
    var velocity: Int
}

struct SongStruct2: Codable {
    var instru1_n: Int
    var instru2_n: Int
    var volumeRecording: Int // max 127
    var volumePlayer: Int // max 127
    var volumeYoutube: Float
    var rootNote: Int
    var noteNames:Int // french/american/roman notation
    var showChords:Int
    // showChords ---> 0 : show melody, 1 : show chords,
    // 2 : show both and record melody, 3: show both and record chord
    var scale: [Bool]
    var notes: [NoteStruct]
    var chordsRoots:[Bool]
    var chordNames:[String]
    var chordsNotes:Array<Set<Int>>
    var notesAccompagnement: [AccordSimple] // [ChordStruct]
}

struct SongStructAll {
    var songPourDb: SongStruct
    var songPourFile: SongStruct2
}


class FirebaseSongsManager {
    let client = SearchClient(appID: "SKJIA8T5Z2", apiKey: "cde90e9470f0ee7676b7c06fbd200132")
    var index: Index?
    var indexUsers: Index?

    // Data in memory
    let storage = Storage.storage()
    let storageRef : StorageReference?
    let db = Firestore.firestore()

    init(){
        index = client.index(withName: "songs")
        indexUsers = client.index(withName: "users")
        storageRef = storage.reference()
    }
    
    // ---------------------
    
    func song2ToData(song2: SongStruct2) -> Data{
        let data = try! JSONEncoder().encode(song2)
        return data
            //(String(data: data, encoding: .utf8)!)
    }
    
    func dataToSong2(data: Data) -> SongStruct2{
        let answer:SongStruct2?
        try! answer = JSONDecoder().decode(SongStruct2.self, from: data)
        return answer!
    }
    
    func saveSong2ToFirebase(song2: SongStruct2, id: String){
        let riversRef = storageRef!.child("songs/" + id)

        let data = song2ToData(song2: song2)
        
        let uploadTask = riversRef.putData(data, metadata: nil) { (metadata, error) in
        }
    }
    
    func getSong2(id: String, completionFunction:  @escaping(() -> ()), completionFunctionError:  @escaping(() -> ())){
        let ref = storageRef!.child("songs/" + id)

        let downloadTask = ref.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                print(error)
                completionFunctionError()
            } else {
                let song2 = self.dataToSong2(data: data!)
                print("Song2 : \(song2)")
                globalVar.songFirebase.songPourFile = song2
                completionFunction()
            }
        }
    }
    
//    func getSong(id: String, completionFunction:  @escaping(() -> ())){
//        func myCompletionFunction() -> () {
//            self.getSong2(id: id, completionFunction: completionFunction)
//        }
//        getSong1(id: id, completionFunction: myCompletionFunction)
//    }
    
    func saveSong1ToFirebase(song: SongStruct, id: String){
        let docData = try! FirestoreEncoder().encode(song)
        db.collection("songs").document(id).setData(docData)
        { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
    }

    // ------------------
    
    func likeSongInFirebase(song: SongStruct){
        let docData = try! FirestoreEncoder().encode(song)
        db.collection("users").document(globalVar.userId).collection("likedSongs").document(song.objectID).setData(docData)
        { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
    }
    
    func dislikeSongInFirebase(song: SongStruct){
        db.collection("users").document(globalVar.userId).collection("likedSongs").document(song.objectID).delete()
    }
    
    func getLikedSongs(fonction:@escaping (([SongStruct]) -> ())){
        db.collection("users").document(globalVar.userId).collection("likedSongs")
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    var liste : [SongStruct] = []
                    for document in querySnapshot!.documents {
                        let data = document.data()
                        let song = try! FirestoreDecoder().decode(SongStruct.self, from: data)
                        liste.append(song)
                    }
                    fonction(liste)
                }
        }
    }
    
    func checkIfSongIsLiked(song: SongStruct, completionFunction:  @escaping(() -> ())) {
        let docRef = db.collection("users").document(globalVar.userId).collection("likedSongs").document(song.objectID)
        docRef.getDocument { document, error in
            if let document = document, document.exists{
                completionFunction()
            }else{
                print("Document does not exist")
            }
        }
    }
    
    // -------------------
    
    func getSong1(id: String, completionFunction:  @escaping(() -> ())) {
        let docRef = db.collection("songs").document(id)
        docRef.getDocument { document, error in
            if let document = document {
                let data = document.data()!
                print(data)
                let song = try! FirestoreDecoder().decode(SongStruct.self, from: data)
                print("Model: \(song)")
                globalVar.songFirebase.songPourDb = song
                completionFunction()
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func saveSongStructAllToFirebase(song:SongStructAll, id: String){
        saveSong2ToFirebase(song2: song.songPourFile, id: id)
        saveSong1ToFirebase(song: song.songPourDb, id: id)
    }
    
    func saveSongRealmToFirebase(song: Song){
        var liste2 : [NoteStruct] = []
        for note1 in song.notes {
            let note = NoteStruct(midiNote: note1.midiNote,
                                  start: note1.start,
                                  duration: note1.duration,
                                  velocity: 100)
            liste2.append(note)
        }
        var myChordNotes = Array<Set<Int>>()
        for accord1 in song.chordsNotes{
            var accord2 = Set<Int>()
            for note in accord1.notes{
                accord2.insert(note)
            }
            myChordNotes.append(accord2)
        }
        let myNotesAccompagnement = song.realmToDataStruct()
        let song2 = SongStruct2(
            instru1_n: song.instru1_n,
            instru2_n: song.instru2_n,
            volumeRecording: song.volumeRecording,
            volumePlayer: song.volumePlayer,
            volumeYoutube: song.volumeYoutube,
            rootNote: song.rootNote,
            noteNames: song.noteNames,
            showChords: song.showChords,
            scale: Array(song.scale), // liste1
            notes: liste2,
            chordsRoots: Array(song.chordsRoots),
            chordNames:Array(song.chordNames),
            chordsNotes: myChordNotes,
            notesAccompagnement: myNotesAccompagnement
        )
        saveSong2ToFirebase(song2: song2, id: song.id)
        // TODO : Save song1 ?
    }
    
    func createSongRealmToFirebase(song: Song){
        let song1 = SongStruct(
            title: song.title,
            videoID: song.videoID,
            datetime: Int(Date().timeIntervalSince1970.milliseconds/1000),
            imageUrl: song.imageUrl,
            duration: song.duration,
            ownerID: globalVar.userId,
            ownerName: globalVar.userName,
            objectID: song.id,
            originalID: song.originalID
        )
        // TODO : check si c bien ca les valeurs par defaut
        let song2 = SongStruct2(
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
            chordsNotes:globalVar.defaultChordNotes,
            notesAccompagnement:[]
        )
//        saveSong2ToFirebase(song2: song.songPourFile, id: id)
        let songAll = SongStructAll (
            songPourDb: song1,
            songPourFile: song2
        )
        saveSongStructAllToFirebase(song: songAll, id: song.id)
    }
    
    
    // -------------------------
    
    func songFirebaseToSongRealm(songFirebase:SongStruct2, songRealm: Song){
        let realm = try! Realm()
        try! realm.write {
            songRealm.notes.removeAll()
        }
        for note1 in songFirebase.notes {
            let note = Note(
                midiNote: Int(note1.midiNote),
                start: Float(note1.start),
                duration: Float(note1.duration),
                velocity: Int(note1.velocity))
            try! realm.write {
                songRealm.notes.append(note)
            }
        }
        
        // song.notesAccompagnement
        songRealm.accompagnementToDb(mesAccords: songFirebase.notesAccompagnement)
        
        try! realm.write {
            songRealm.chordsNotes.removeAll()
        }
        for chord in songFirebase.chordsNotes{
            try! realm.write {
                songRealm.chordsNotes.append(ChordNotes(set: chord))
            }
        }
        
        try! realm.write {
            songRealm.instru1_n = songFirebase.instru1_n
            songRealm.instru2_n = songFirebase.instru2_n
            songRealm.volumeRecording = songFirebase.volumeRecording
            songRealm.volumePlayer = songFirebase.volumePlayer
            songRealm.volumeYoutube = songFirebase.volumeYoutube
            songRealm.rootNote = songFirebase.rootNote
            songRealm.scale.removeAll()
            songRealm.scale.append(objectsIn: songFirebase.scale)
            songRealm.chordsRoots.removeAll()
            songRealm.chordsRoots.append(objectsIn: songFirebase.chordsRoots)
            songRealm.chordNames.removeAll()
            songRealm.chordNames.append(objectsIn: songFirebase.chordNames)
        }
    }
    
    func loadOneSong2FromFirebaseToRealm(id: String, completionFunction:  @escaping(() -> ())){
        let realm = try! Realm()
        
        let ref = storageRef!.child("songs/" + id)

        let downloadTask = ref.getData(maxSize: 1 * 1024 * 1024) {[weak self] data, error in
            guard let self = self else { return }
            if let error = error {
                print(error)
            } else {
                let songFirebase = self.dataToSong2(data: data!)
                // print("Song2 : \(song2)")
                let songRealm = realm.object(ofType: Song.self, forPrimaryKey: id)!
                // should be globalVar.song!
                // !!! --> we suppose are sure we already have it
                // in our realm database (we have the song1 part,
                // but not the song2 part, which we will load here :
                self.songFirebaseToSongRealm(songFirebase: songFirebase, songRealm: songRealm)
            }
            completionFunction()
        }
    }
    
    func deleteAllRealmSongs(){
        let realm = try! Realm()
        let allSongs = realm.objects(Song.self)
        try! realm.write {
            realm.delete(allSongs)
        }
    }
    
    func loadAllSong1sFromFirebaseToRealm( continueLogin: @escaping(() -> ()) ){
        deleteAllRealmSongs()
        let realm = try! Realm()
        db.collection("songs").whereField("ownerID", isEqualTo: globalVar.userId)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        let data = document.data()
                        let song = try! FirestoreDecoder().decode(SongStruct.self, from: data)
                        let songRealm = Song()
                    
                        songRealm.imageUrl = song.imageUrl
                        songRealm.title = song.title
                        songRealm.videoID = song.videoID
                        songRealm.duration = song.duration
                        songRealm.id = song.objectID
                       
                        try! realm.write {
                            realm.add(songRealm)
                        }
                    }
                }
            continueLogin()
        }
    }
    
    // -----------------------
    
    func getSongsFromUserId(userId: String, fonction:@escaping (([SongStruct]) -> ())){
        db.collection("songs").whereField("ownerID", isEqualTo: userId)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    var liste : [SongStruct] = []
                    for document in querySnapshot!.documents {
                        let data = document.data()
    //                        print("\(document.documentID) => \(data)")
    //                        print((document.data()["duration"]! as! Int) == 256)
    //                        print(document.data()["title"]!)
                        let song = try! FirestoreDecoder().decode(SongStruct.self, from: data)
//                        print("Model: \(song)")
                        liste.append(song)
                    }
                    fonction(liste)
                }
        }
    }
    
    // ----------------------
    
    func searchSongs(s: String, fonction:@escaping (([SongStruct]) -> ()) ){
        var myQuery = Query(s)
        myQuery.length = 10
        var answer: [SongStruct] = []
        index!.search(query: myQuery) { result in
            switch result {
            case .failure(let error):
                print("Error: \(error)")
            case .success(let response):
                //            print("NbHits: \(response.nbHits)")
                //            self.myList = response.hits
                do{
                    answer = try response.extractHits()
//                    DispatchQueue.main.async{
                    fonction(answer)
//                    }
                }catch{
                    print("Unexpected error: \(error).")
                }
            }
        }
    }
    
    // ----------------------
    
    
    func searchUsers(s: String, fonction:@escaping (([UserStruct]) -> ()) ){
        var myQuery = Query(s)
        myQuery.length = 10
        var answer: [UserStruct] = []
        indexUsers!.search(query: myQuery) { result in
            switch result {
            case .failure(let error):
                print("Error: \(error)")
            case .success(let response):
                //            print("NbHits: \(response.nbHits)")
                //            self.myList = response.hits
                print(response.hits)
                do{
                    answer = try response.extractHits()
                    print(answer)
//                    DispatchQueue.main.async{
                    fonction(answer)
//                    }
                }catch{
                    print("Unexpected error: \(error).")
                }
            }
        }
    }
    
    // --------------------
    // Delete
    
    func deleteSongFromFirebase(id:String){
        db.collection("songs").document(id).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
        let ref = storageRef!.child("songs/" + id)
        ref.delete { error in
            if let error = error {
                print("Error removing file: \(error)")
            } else {
                print("Deleted file successfully.")
            }
        }
    }
    
    // ---------------------
    
    
    func followUserInFirebase(user: UserStruct){
        let docData = try! FirestoreEncoder().encode(user)
        db.collection("users").document(globalVar.userId).collection("followedUsers").document(user.objectID).setData(docData)
        { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
    }
    
    func unfollowUserInFirebase(user: UserStruct){
        db.collection("users").document(globalVar.userId).collection("followedUsers").document(user.objectID).delete()
    }
    
    func getFollowedUsers(fonction:@escaping (([UserStruct]) -> ())){
        db.collection("users").document(globalVar.userId).collection("followedUsers")
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    var liste : [UserStruct] = []
                    for document in querySnapshot!.documents {
                        let data = document.data()
                        let user = try! FirestoreDecoder().decode(UserStruct.self, from: data)
                        liste.append(user)
                    }
                    fonction(liste)
                }
        }
    }
    
    func checkIfUserIsFollowed(user: UserStruct, completionFunction:  @escaping(() -> ())) {
        let docRef = db.collection("users").document(globalVar.userId).collection("followedUsers").document(user.objectID)
        docRef.getDocument { document, error in
            if let document = document, document.exists{
                completionFunction()
            }else{
                print("Document does not exist")
            }
        }
    }
    
}
