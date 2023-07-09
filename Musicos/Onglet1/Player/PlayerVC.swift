import UIKit
import SpriteKit
import AudioKit
import RealmSwift
import Foundation
import GameplayKit
import CoreMotion
import AVKit
import XCDYouTubeKit

enum TypeEvent{
    case on, off
}

class MidiEvent{
    var note:UInt8
    var time:AKDuration
    var typeEvent:TypeEvent
    init(note:UInt8,time:AKDuration,typeEvent:TypeEvent){
        self.note = note
        self.time = time
        self.typeEvent = typeEvent
    }
}

class PlayerVC: UIViewController, UIScrollViewDelegate {
  
    @IBOutlet weak var boutonRecord: UIButton!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    
    @IBOutlet weak var youtubePlayerView: UIView!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var mySKView: SKView!
    
    @IBOutlet weak var stackViewUp: UIStackView!
    @IBOutlet weak var stackViewMiddle: UIStackView!
    @IBOutlet weak var stackViewDown: UIStackView!
    
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var sliderVolumeYoutube: UISlider!
    @IBOutlet weak var sliderVolumeMidi: UISlider!
    @IBOutlet weak var presentHeight: UIButton!
    @IBOutlet weak var notesOrChordsButton: UIButton!
    @IBOutlet weak var muteRecordedMidiButton: UIButton!
    @IBOutlet weak var balanceNotesVsChordsSlider: UISlider!
    
    var myTimeObserver : Any?
    
    var spinnerVC : SpinnerVC?
//    var sequencer : AKAppleSequencer = AKAppleSequencer()
    var lastNoteOn:[AKDuration] = Array(repeating: AKDuration(seconds: 0), count: 100)
    var events:[MidiEvent] = []

    var scene: GameScene?
    weak var clearContentView: UIView?
    weak var scrollView: UIScrollView?
    
    var stackviews = Array<UIStackView>()
    let noteColumn = [0,1,1,2,2,3,4,4,5,5,6,6]
    let noteLine =   [0,1,0,1,0,0,1,0,1,0,1,0]

    let realm = try! Realm()
    
//    var currentVelocity:UInt8 = 100
//    var velocityRecording:UInt8 = 90
    var duration:CGFloat = 1
    var isRecording = true
    var myChordNotes = Array<Set<Int>>()
    var roots = Array<Bool>()
    var rootNote:Int = 48
    
    var sawIt = false
    var isPlaying = false
    var recordedMidiIsMuted = false
    
    var buttonColors = [
        [UIColor(red: 1, green: 147.0/255, blue: 147.0/255, alpha: 1),
         UIColor(red: 181.0/255, green: 0, blue: 0, alpha: 1)],
        [UIColor(red: 202.0/255, green: 1, blue: 198.0/255, alpha: 1),
         UIColor(red: 12.0/255, green: 183.0/255, blue: 0, alpha: 1)],
        [UIColor(red: 168.0/255, green: 214.0/255, blue: 1, alpha: 1),
         UIColor(red: 0, green: 112.0/255, blue: 214.0/255, alpha: 1)]
    ]
    
    deinit{
        if player != nil{
            self.player!.removeObserver(self, forKeyPath: "status")
            self.player!.removeObserver(self, forKeyPath: "timeControlStatus")
            if myTimeObserver != nil{            self.player!.removeTimeObserver(myTimeObserver!)
            }
        }
        globalVar.reset()
        print("deinit playervc")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // CRUD : Read
        // loadOneSong2FromFirebaseToRealm
        // (actually the call to this function is in MySongsVC123 in function didSelectRowAt, just before reaching here).
        
        sliderVolumeMidi.setValue(Float(globalVar.song!.volumePlayer), animated: true)

        isRecording = true
        boutonRecord.setBackgroundImage(UIImage(named: "record-64123"), for: .normal) // recordIcon2

        createSpinnerView()

        XCDYouTubeClient.default().getVideoWithIdentifier(globalVar.song!.videoID) { [weak self] (video, error) in
            guard let self = self else {return}
            guard video != nil else {
                // Handle error
                try! globalVar.gemsManager.addGems(6)
                globalVar.firebaseSongsManager.deleteSongFromFirebase(id: globalVar.song!.id)
                try! self.realm.write {
                    self.realm.delete(globalVar.song!)
                }
                globalVar.explainsThatYoutubeSucks = true
                self.deleteSpinnerView()
                popVC()
                return
            }
            
            let myUrl = self.getVideoURL(video: video!)
            self.player = AVPlayer(url: myUrl!)
//            https://stackoverflow.com/questions/5401437/knowing-when-avplayer-object-is-ready-to-play
            self.player!.addObserver(self, forKeyPath: "status", options: .new, context: nil)
            self.player!.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
            //(observer: self?, forKeyPath: "status", options: 0, context: nil)
            
            let playerController = AVPlayerViewController()
            playerController.showsPlaybackControls = false
            playerController.player = self.player

            playerController.view.frame = (self.youtubePlayerView.frame)
            self.view.addSubview(playerController.view)
            self.addChild(playerController)
            
            let interval = CMTime(value: 1, timescale: 2)
            self.myTimeObserver = self.player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { [weak self] (progressTime) in
                guard let self = self else {return}
                let seconds = CMTimeGetSeconds(progressTime)
                self.currentTimeLabel.text = self.getTimeFormat(timeInt: Int(seconds))
                if let duration = self.player?.currentItem?.duration {
                    let durationSeconds = CMTimeGetSeconds(duration)
                    self.currentTimeLabel.text = self.getTimeFormat(timeInt: Int(seconds))
                    self.timeSlider.value = Float (seconds / durationSeconds)
                }
            })
        }
        
        globalVar.mesAccords = [AccordSimple]()
        globalVar.track = AKMusicTrack()
        globalVar.trackChords = AKMusicTrack()
        
        updateDeferringSystemGestures()

        globalVar.youtubeIsMuted = false
        globalVar.modeAffichage = 0
        globalVar.currentVelocity = UInt8(globalVar.song!.volumePlayer)
        globalVar.velocityRecording = UInt8(globalVar.song!.volumeRecording)
        // TODO add field of songFirebase and load it here :
        globalVar.balanceNotesVsChords = 0.5
        
        globalVar.loadInstrumentsInSampler(instru:globalVar.song!.instru1_n, instruChords: globalVar.song!.instru2_n, showChords: globalVar.song!.showChords)

        stepper.value = Double(exactly: globalVar.song!.rootNote)!
        stackviews = [stackViewUp,stackViewMiddle,stackViewDown]
        
        let volumeYoutube = globalVar.song!.volumeYoutube
        if (0 <= volumeYoutube && volumeYoutube <= 1){
            sliderVolumeYoutube.value = globalVar.song!.volumeYoutube
        }
        
        if(globalVar.song!.showChords % 2 != 0){
            myChordNotes = globalVar.dbToSets(chordsNotes: globalVar.song!.chordsNotes)
            roots = globalVar.dbToRoots(rootsDb: globalVar.song!.chordsRoots)
            rootNote = globalVar.song!.rootNote
            rootNote = ((rootNote - 40) % 12) + 40
        }
        updateButtons()
        
        globalVar.setSequencerFromSong(firebaseNotRealm: false)
        
        duration = CGFloat(globalVar.song!.duration)
        self.totalTimeLabel.text = self.getTimeFormat(timeInt: Int(duration))
        timeSlider.setValue(0, animated: false)
        playButton.tintColor = UIColor.black
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        scrollView?.frame = mySKView.bounds
        scene?.size = mySKView.bounds.size
        if let scrollView = scrollView {
            adjustContent(scrollView: scrollView)
        }
    }

    func adjustContent(scrollView: UIScrollView) {
        let contentOffset = scrollView.contentOffset
        let contentSize = scrollView.contentSize
        let scrollAreaHeight: CGFloat = contentSize.height - scrollView.bounds.height
        let yUIKit: CGFloat = contentOffset.y

        let ySpriteKit = scrollAreaHeight - yUIKit
        let contentOffsetSpriteKit = CGPoint(x: contentOffset.x, y: ySpriteKit)
        scene?.contentOffset = contentOffsetSpriteKit
    }
        
    override func viewDidLayoutSubviews(){
        if !sawIt {
            sawIt = true
            
            scene = GameScene(size: mySKView.frame.size)
            print(mySKView.frame.size)
            scene!.scaleMode = .resizeFill
            scene!.myPlayer = self

            var contentSize = mySKView!.frame.size
            scene!.heightDefault = (contentSize.height)
            contentSize.height *= (duration/scene!.secondesParHauteur)
            scene!.secondeToPixel = (contentSize.height) / duration
            scene!.contentSize = contentSize
            scene!.duration = duration
            
            preparerSKScene()
            
            scene!.bougerPianoRoll(seconds:0)
            mySKView.presentScene(scene)
        }
    }
    
    @IBAction func actionBackButton(_ sender: Any) {
        if player != nil{
            if player!.rate > 0 {
                player!.pause()
            }
            self.player?.replaceCurrentItem(with: nil)
        }
        scene!.stopDefilement()
        globalVar.sequencer.stop()
        do {
            try AKManager.stop()
        } catch {
            print("Oops! AudioKit didn't stop!")
        }
        
        globalVar.song!.notesToDb(track:globalVar.track!)
        globalVar.song!.accompagnementToDb(mesAccords:globalVar.mesAccords)
        
        // CRUD : Update
        globalVar.firebaseSongsManager.saveSongRealmToFirebase(
            song: globalVar.song!)
        
        popAll()
    }
    
    func pauseDefilementEtMidi(){
        globalVar.sequencer.stop()
        scene!.stopDefilement()
        
        let time = player?.currentTime().seconds
        print("seq time : \(globalVar.sequencer.currentPosition.seconds)")
        print("you time : \(time)")
        print("sce time : \(self.scene!.getCurrentTime())")
        print("size : \(self.scene!.spriteForScrollingGeometry!.size.height)")
        globalVar.sequencer.setTime(MusicTimeStamp(time!))
        self.scene!.bougerPianoRoll(seconds: CGFloat(time!))
    }
//    https://stackoverflow.com/questions/5401437/knowing-when-avplayer-object-is-ready-to-play
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if player != nil{
            if(object as! NSObject == player! && keyPath == "status"){
                if player!.status == .readyToPlay {
                    deleteSpinnerView()
                    player!.volume = globalVar.song!.volumeYoutube
                } else if player!.status == .failed{
                    deleteSpinnerView()
                    popUpText(title:":(", message: "Could not load the video.")
                }
            }else if (object as! NSObject == player! && keyPath == "timeControlStatus") {
                if player!.timeControlStatus == .playing {
                    print("playing")
                    globalVar.sequencer.play()
                    scene!.animerToFin()
                } else if player!.timeControlStatus == .paused {
                    print("paused")
//                    pauseDefilementEtMidi()
                } else if player!.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                    print("loading")
                    // TODO : loading symbol
                    pauseDefilementEtMidi()
                }
            }
        }
    }

    func createSpinnerView() {
        spinnerVC = SpinnerVC()

        // add the spinner view controller
        addChild(spinnerVC!)
        spinnerVC!.view.frame = view.frame
        view.addSubview(spinnerVC!.view)
        spinnerVC!.didMove(toParent: self)
    }

    func deleteSpinnerView(){
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        if spinnerVC != nil{
            spinnerVC!.willMove(toParent: nil)
            spinnerVC!.view.removeFromSuperview()
            spinnerVC!.removeFromParent()
            spinnerVC = nil
        }
    }
    
    func popUpText(title:String,message:String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // ------------------------
    
    @IBAction func presentHeightAction(_ sender: Any) {
        globalVar.modeAffichage = (globalVar.modeAffichage + 1) % 3;
        let images = ["up","middle","down"]
        presentHeight.setBackgroundImage(UIImage(named: images[globalVar.modeAffichage]), for: .normal) // recordIcon2
        scene!.stopDefilement()
        let sec = globalVar.sequencer.currentPosition.seconds
        scene!.bougerPianoRoll(seconds:CGFloat(sec))
        if isPlaying{
            scene!.animerToFin()
        }
    }
    
    @IBAction func sliderVolumeMidiAction(_ sender: UISlider) {
        try! realm.write{
            globalVar.song!.volumePlayer = Int(sender.value)
        }
        globalVar.currentVelocity = UInt8(globalVar.song!.volumePlayer)
        
        try! realm.write{
            globalVar.song!.volumeRecording = Int(sender.value)
        }
        globalVar.velocityRecording = UInt8(globalVar.song!.volumeRecording)
    }
    
    @IBAction func sliderVolumeAction(_ sender: UISlider) {
        if player != nil{
            player?.volume = sender.value / sender.maximumValue
            
            // TODO: https://stackoverflow.com/questions/9390298/iphone-how-to-detect-the-end-of-slider-drag
            try! realm.write {
                globalVar.song!.volumeYoutube = player!.volume
            }
        }
    }
    
    @IBAction func recordAction(_ sender: Any) {
        isRecording = !isRecording
        if isRecording{
            boutonRecord.setBackgroundImage(UIImage(named: "record-64123"), for: .normal) // recordIcon2
        } else {
            boutonRecord.setBackgroundImage(UIImage(named: "recordIcon1"), for: .normal)
        }
        if (player!.rate > 0){
            self.updateRecordingStatus(shouldRecord: self.isRecording)
        }
    }
    
    @IBAction func deleteNote(_ sender: Any) {
        if let monRondWhichWasSelected = scene!.rondASupprimer {
            //enleverRondEtNoteInMidi(noteNumber:noteNumber, avant:avant)
            let noteNumber = UInt8(monRondWhichWasSelected.name!)
            let secondes = Double(monRondWhichWasSelected.position.y / scene!.secondeToPixel)
            let avant = AKDuration(seconds: secondes - 0.001)
            let delta = AKDuration(seconds: 0.002)
            
            if(globalVar.song!.showChords % 2 == 0){
                globalVar.track!.clearRange(start: avant, duration: delta)
            }else{
                globalVar.trackChords!.clearRange(start: avant, duration: delta)
                for (index,acc) in globalVar.mesAccords.enumerated(){
                    if abs(acc.start - secondes) < 0.001{
                        globalVar.mesAccords.remove(at: index)
                        break
                    }
                }
            }
            scene!.supprimerRond(circle: monRondWhichWasSelected)
            scene!.rondASupprimer = nil
            scene!.oldRondASupprimer = nil
            
        } else{ // nil
            print("pas de cercle selected yet, deso mon gros.")
        }
    }

    @IBAction func timeSliderMoved(_ sender: UISlider) {
        let seconds = CGFloat(sender.value) * duration
        self.currentTimeLabel.text = getTimeFormat(timeInt: Int(seconds))
        let seekTime = CMTime(value: Int64(seconds*1000) , timescale: 1000)
        player?.seek(to: seekTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: { (completedSeek) in
        })
        print("time slider was moved : \(seconds)")
        scene!.bougerPianoRoll(seconds: seconds)
        globalVar.sequencer.setTime(MusicTimeStamp(seconds))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? SettingsScaleVC{
            
        }
    }
    
    @IBAction func unwindToMyPlayerVC(segue:UIStoryboardSegue) {
        globalVar.loadInstrumentsInSampler(instru:globalVar.song!.instru1_n, instruChords: globalVar.song!.instru2_n, showChords: globalVar.song!.showChords)
        
        globalVar.currentVelocity = UInt8(globalVar.song!.volumePlayer)
        globalVar.velocityRecording = UInt8(globalVar.song!.volumeRecording)

        if(globalVar.song!.showChords % 2 != 0){
            myChordNotes = globalVar.dbToSets(chordsNotes: globalVar.song!.chordsNotes)
            roots = globalVar.dbToRoots(rootsDb: globalVar.song!.chordsRoots)
            rootNote = globalVar.song!.rootNote
            rootNote = ((rootNote - 40) % 12) + 40
        }
        updateButtons()
        
        preparerSKScene()
        let sec = globalVar.sequencer.currentPosition.seconds
        print(sec)
        scene!.bougerPianoRoll(seconds:CGFloat(sec))
    }
    
    @IBAction func stepperValueChanged(_ sender: Any) {
        try! realm.write {
            globalVar.song!.rootNote = Int(stepper.value)
        }
        rootNote = globalVar.song!.rootNote
        rootNote = ((rootNote - 40) % 12) + 40
        
        updateButtons()
        preparerSKScene()
    }
        
    func pauseTime(){
        isPlaying = false
        player?.pause() // suite: cf observeValue
        pauseDefilementEtMidi()
        self.updateRecordingStatus(shouldRecord:false)
        self.playButton.setImage(UIImage(named: "baseline_play_arrow_black_48pt"), for: .normal)
        print("paused !!!!!!!!!!!! ")
    }
    
    func playTime(){
        isPlaying = true
        self.updateRecordingStatus(shouldRecord:self.isRecording)
        player?.play() // suite: cf observeValue
        print("playing !!!!!!!!!!!!!!! ")
        self.playButton.setImage(UIImage(named: "baseline_pause_black_48pt"), for: .normal)
    }
    
    @IBAction func playButtonClicked(_ sender: Any) {
        if isPlaying {
            pauseTime()
        } else {
            playTime()
        }
    }
    
    @IBAction func buttonNoteClicked(_ sender: UIButton) {
        let avant = globalVar.sequencer.currentPosition
        let noteNumber = sender.tag
        lastNoteOn[Int(noteNumber)] = avant
        try! globalVar.currentSampler.play(noteNumber: UInt8(noteNumber), velocity: globalVar.currentVelocity, channel: 0)
        scene!.ajouterRond(seconde: CGFloat(avant.seconds), colonne: noteColumn[(noteNumber - globalVar.song!.rootNote) % 12], noteNumber:noteNumber)
    }
    
    @IBAction func buttonNoteReleased(_ sender: UIButton) {
        let now = globalVar.sequencer.currentPosition
        let noteNumber = sender.tag
        try! globalVar.currentSampler.stop(noteNumber: UInt8(noteNumber), channel: 0)
        let avant = lastNoteOn[Int(noteNumber)]
        let myDuration = now-avant
        globalVar.track!.add(noteNumber: UInt8(noteNumber), velocity: globalVar.currentVelocity, position: avant, duration: myDuration , channel: 0)
    }
    
    
    @IBAction func buttonNoteClickedWithoutRecording(_ sender: UIButton) {
        try! globalVar.currentSampler.play(noteNumber: UInt8(sender.tag),
                                    velocity: globalVar.currentVelocity,
                                    channel: 0)
    }
    
    @IBAction func buttonNoteReleasedWithoutRecording(_ sender: UIButton) {
        try! globalVar.currentSampler.stop(noteNumber: UInt8(sender.tag), channel: 0)
    }
        
    func updateRecordingStatus(shouldRecord:Bool){
        for stack in stackviews {
            for j in 0..<stack.arrangedSubviews.count{
                guard let currentSubStackView = stack.arrangedSubviews[j] as? UIStackView else {return}
                for myButton in currentSubStackView.subviews{
                    guard let myButton2 = myButton as? UIButton else {return}
                    modifieActionsGen(button: myButton2, shouldRecord: shouldRecord)
                }
            }
        }
    }
    
    // !!!
    func modifieActionsMelody(button:UIButton, shouldRecord:Bool){
        button.removeTarget(nil, action: nil, for: .allEvents)

        if !shouldRecord{
            button.addTarget(self,
                                action: #selector(buttonNoteClickedWithoutRecording),
                                for: .touchDown)
            button.addTarget(self,
                                action: #selector(buttonNoteReleasedWithoutRecording),
                                for: .touchUpInside)
        } else {
            button.addTarget(self,
                                action: #selector(buttonNoteClicked),
                                for: .touchDown)
            button.addTarget(self,
                                action: #selector(buttonNoteReleased),
                                for: .touchUpInside)
        }
    }
        
    @IBAction func rootButton(_ sender: UIButton) {
        let avant = globalVar.sequencer.currentPosition
        let tag = sender.tag
        lastNoteOn[Int(tag)] = avant
        for i in myChordNotes[tag] {
            try! globalVar.currentSampler.play(noteNumber: UInt8(rootNote + i),
                                        velocity: globalVar.currentVelocity,
                                        channel: 0)
        }
        scene!.ajouterRectangleChord(seconde: CGFloat(avant.seconds), colonne: tag % 12, tag:tag)
    }
    
    @IBAction func rootButtonUp(_ sender: UIButton) {
        let now = globalVar.sequencer.currentPosition
        let tag = sender.tag
        let avant = lastNoteOn[Int(tag)]
        let myDuration = now-avant

        for i in myChordNotes[tag] {
            try! globalVar.currentSampler.stop(noteNumber: UInt8(rootNote + i), channel: 0)
        }
        for i in myChordNotes[tag] {
            globalVar.trackChords!.add(noteNumber: UInt8(rootNote + i), velocity: globalVar.currentVelocity, position: avant, duration: myDuration , channel: 0)
        }
        globalVar.mesAccords.append(AccordSimple(start: Float(avant.seconds), duration: Float(myDuration.seconds), notesRelative: myChordNotes[tag], ligne: tag/12, rootKeyModulo12: (rootNote+tag)%12, rootNote:rootNote ))
    }

    @IBAction func rootButtonWithoutRecording(_ sender: UIButton) {
        for i in myChordNotes[sender.tag] {
            try! globalVar.currentSampler.play(noteNumber: UInt8(rootNote + i),
                                        velocity: globalVar.currentVelocity,
                                        channel: 0)
        }
    }
    
    @IBAction func rootButtonUpWithoutRecording(_ sender: UIButton) {
        for i in myChordNotes[sender.tag] {
            try! globalVar.currentSampler.stop(noteNumber: UInt8(rootNote + i), channel: 0)
        }
    }

    // !!!
    func modifieActionsChords(button:UIButton, shouldRecord:Bool){
        button.removeTarget(nil, action: nil, for: .allEvents)
        
        if !shouldRecord{
            button.addTarget(self,
                             action: #selector(rootButtonWithoutRecording),
                             for: .touchDown)
            button.addTarget(self,
                             action: #selector(rootButtonUpWithoutRecording),
                             for: .touchUpInside)
        } else {
            button.addTarget(self,
                             action: #selector(rootButton),
                             for: .touchDown)
            button.addTarget(self,
                             action: #selector(rootButtonUp),
                             for: .touchUpInside)
        }
    }
    
    func modifieActionsGen(button:UIButton, shouldRecord:Bool){
        if(globalVar.song!.showChords % 2 == 0){
            modifieActionsMelody(button: button, shouldRecord: shouldRecord)
        } else {
            modifieActionsChords(button: button, shouldRecord: shouldRecord)
        }
    }
    
    func updateButtons(){
        for stack in stackviews {
            for view in stack.subviews {
                view.removeFromSuperview()
            }
        }

        var oldColumn = -1
        var noteNumber = 60
        var buttonName = ""
        
        var shouldRecord = isRecording && isPlaying
        
        var condition = true
        for i in 0 ..< 12 {
            if(noteColumn[i] != oldColumn) {
                oldColumn = noteColumn[i]
                for stack in stackviews {
                    let subStackView = UIStackView()
                    subStackView.axis = .vertical
                    subStackView.alignment = .fill
                    subStackView.distribution = .fillEqually
                    stack.addArrangedSubview(subStackView)
                }
            }
            
            if(globalVar.song!.showChords % 2 == 0){
                condition = globalVar.song!.scale[i]
            }else{
                condition = globalVar.song!.chordsRoots[i]
            }
            
            if(condition) {
                for (index, stack) in stackviews.enumerated() {
                    let button = UIButton(type: UIButton.ButtonType.system)
                    
                    if(globalVar.song!.showChords % 2 == 0){
                        noteNumber = globalVar.song!.rootNote + i + (index * 12)
                    }else{
                        noteNumber = i + (index * 12)
                    }
                    button.tag = noteNumber
                    
                    button.layer.cornerRadius = 5
                    button.layer.borderColor = UIColor.black.cgColor
                    button.layer.borderWidth = 2
                    
                    button.backgroundColor = buttonColors[index][noteLine[i]]
                    
                    if(globalVar.song!.showChords % 2 != 0){ // si chords
                        buttonName = globalVar.notesRoman[i % 12]
                        switch(globalVar.song!.noteNames){
                        case 0: buttonName = globalVar.notesUSAccords[(rootNote+noteNumber) % 12]
                        case 1: buttonName = globalVar.notesFrenchAccords[(rootNote+noteNumber) % 12]
                        case 2: buttonName = globalVar.notesRoman[i % 12]
                        case 3: buttonName = globalVar.notesLatin[i % 12]
                        case 4: buttonName = ""
                        default: buttonName = globalVar.notesRoman[i % 12]
                        }
                        buttonName += globalVar.song!.chordNames[noteNumber]
                    }else{ // si melodie
                        switch(globalVar.song!.noteNames){
                        case 0: buttonName = globalVar.notes[noteNumber]
                        case 1: buttonName = globalVar.notesFrench[noteNumber]
                        case 2: buttonName = globalVar.notesRoman[i % 12]
                        case 3: buttonName = globalVar.notesLatin[i % 12]
                        case 4: buttonName = ""
                        default: buttonName = globalVar.notes[noteNumber]
                        }
                    }
                    button.setTitle(buttonName, for: [])
                    button.setTitleColor(UIColor.black, for: [])
                    if(UIDevice.current.userInterfaceIdiom == .pad){
                        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
                    }

                    if let currentSubStackView = stack.arrangedSubviews.last as? UIStackView{
                        currentSubStackView.addArrangedSubview(button)
                    } else {print("bizarre bizarre.")}
                    
                    modifieActionsGen(button: button, shouldRecord: shouldRecord)
                }
            }
        }
    }
    
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        get {
            return [.bottom, .right]
        }
    }

    private func updateDeferringSystemGestures() {
        if #available(iOS 11.0, *) {
        self.navigationController?.setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
        } else {
            self.navigationController?.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    var player: AVPlayer?

    let PreferredFormats: [AnyHashable] = [
        XCDYouTubeVideoQuality.small240.rawValue as NSNumber,
        XCDYouTubeVideoQuality.medium360.rawValue as NSNumber,
        XCDYouTubeVideoQuality.HD720.rawValue as NSNumber,
        XCDYouTubeVideoQualityHTTPLiveStreaming
    ]

    func getVideoURL(video: XCDYouTubeVideo) -> URL? {
      for format in PreferredFormats {
        guard let bestURL = video.streamURLs[format] else { continue }
        return bestURL
      }
      return nil
    }
    
    func preparerSKScene(){
        if(globalVar.song!.showChords == 0){
            preparerSKSceneMelody()
        }else if(globalVar.song!.showChords == 1){
            preparerSKSceneAccords()
        } else if(globalVar.song!.showChords == 2){
            // todo : personalliser ?
            preparerSKSceneMelodyEtAccords()
        } else if(globalVar.song!.showChords == 3){
            // todo : personalliser ?
            preparerSKSceneMelodyEtAccords()
        }
    }
    
    func preparerSKSceneMelodyEtAccords(){
        scene!.spriteForScrollingGeometry!.removeAllChildren()
        for acc in globalVar.mesAccords{
            let ligne = acc.ligne
            let colonne = ((acc.rootKeyModulo12 - rootNote) + 120) % 12
            let debut = CGFloat(acc.start)
            scene!.ajouterRectangleChord(seconde: debut, colonne: colonne, tag: (12*ligne + colonne))
        }
        let liste = globalVar.sequencer.tracks[0].getMIDINoteData()
        for note in liste{
            let midiNote = Int(note.noteNumber)
            let colonne = noteColumn[((midiNote - globalVar.song!.rootNote)+1200) % 12]
            let debut = CGFloat(note.position.seconds)
            scene!.ajouterRond(seconde: debut, colonne: colonne, noteNumber: midiNote)
        }
    }
    
    func preparerSKSceneMelody(){
        let liste = globalVar.sequencer.tracks[0].getMIDINoteData()
        scene!.spriteForScrollingGeometry!.removeAllChildren()
        for note in liste{
            let midiNote = Int(note.noteNumber)
            let colonne = noteColumn[((midiNote - globalVar.song!.rootNote)+1200) % 12]
            let debut = CGFloat(note.position.seconds)
            scene!.ajouterRond(seconde: debut, colonne: colonne, noteNumber: midiNote)
        }
    }
    
    func preparerSKSceneAccords(){
        scene!.spriteForScrollingGeometry!.removeAllChildren()
        for acc in globalVar.mesAccords{
            let ligne = acc.ligne
            let colonne = ((acc.rootKeyModulo12 - rootNote) + 120) % 12
            let debut = CGFloat(acc.start)
            scene!.ajouterRectangleChord(seconde: debut, colonne: colonne, tag: (12*ligne + colonne))
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        adjustContent(scrollView: scrollView)
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return clearContentView
    }
    
    func scrollViewDidTransform(scrollView: UIScrollView) {
        adjustContent(scrollView: scrollView)
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        adjustContent(scrollView: scrollView)
    }
    
    func getTimeFormat(timeInt:Int) -> String {
        let seconds = timeInt % 60
        let minutes = (timeInt / 60) % 60
        let hours = (timeInt / 3600)
        var text = ""
        if(hours == 0){
            text = String(minutes) + ":" +
                   String(format: "%02d", seconds)
        }else{
            text = String(hours) + ":" +
                   String(format: "%02d", minutes) + ":" +
                   String(format: "%02d", seconds)
        }
        return text
    }
 
    @IBAction func notesOrChords(_ sender: Any) {
        let images = ["note","chords","chordsAndNotes1-2","chordsAndNotes2-2"]
        try! realm.write {
            globalVar.song!.showChords += 1
            globalVar.song!.showChords %= 4
            notesOrChordsButton.setBackgroundImage(UIImage(named: images[globalVar.song!.showChords]), for: .normal)
            globalVar.updateCurrentSampler(showChords: globalVar.song!.showChords % 2)
            if(globalVar.song!.showChords % 2 != 0){
                myChordNotes = globalVar.dbToSets(chordsNotes: globalVar.song!.chordsNotes)
                roots = globalVar.dbToRoots(rootsDb: globalVar.song!.chordsRoots)
                rootNote = globalVar.song!.rootNote
                rootNote = ((rootNote - 40) % 12) + 40
            }
            updateButtons()
            preparerSKScene()
        }
    }
    
    @IBAction func muteRecordedMidi(_ sender: Any) {
        recordedMidiIsMuted = !recordedMidiIsMuted
        let wasPlaying = isPlaying
        if(!recordedMidiIsMuted){
            muteRecordedMidiButton.setBackgroundImage(UIImage(named: "vinyl"), for: .normal)
            if(wasPlaying){
                pauseTime()
            }
            globalVar.track!.setMIDIOutput(globalVar.callbackInstr.midiIn)
            globalVar.trackChords!.setMIDIOutput(globalVar.callbackChords.midiIn)
            if(wasPlaying){
                playTime()
            }
        }else{
            muteRecordedMidiButton.setBackgroundImage(UIImage(named: "vinylOff"), for: .normal)
            if(wasPlaying){
                pauseTime()
            }
            globalVar.track!.setMIDIOutput(globalVar.emptyCallBack.midiIn)
            globalVar.trackChords!.setMIDIOutput(globalVar.emptyCallBack.midiIn)
            if(wasPlaying){
                playTime()
            }
        }
    }
    
    @IBAction func balanceNotesVsChords(_ sender: UISlider) {
        let val = sender.value
        globalVar.balanceNotesVsChords = val
    }
}
