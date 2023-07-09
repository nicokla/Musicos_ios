import UIKit
import SpriteKit
import AudioKit
import RealmSwift
import Foundation
import GameplayKit
import CoreMotion
import AVKit
import XCDYouTubeKit
import PopupDialog

class OtherUserSongVC: UIViewController, UIScrollViewDelegate {
    let realm = try! Realm()
    var allSongs: Results<Song>?

    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    
    @IBOutlet weak var youtubePlayerView: UIView!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var mySKView: SKView!
    
    @IBOutlet weak var stackViewUp: UIStackView!
    @IBOutlet weak var stackViewMiddle: UIStackView!
    @IBOutlet weak var stackViewDown: UIStackView!
    @IBOutlet weak var notesOrChordsButton: UIButton!
    @IBOutlet weak var muteRecordedMidiButton: UIButton!
    @IBOutlet weak var sliderVolume: UISlider!
    @IBOutlet weak var sliderVolumeMidi: UISlider!
    
    var myTimeObserver : Any?
    
    var spinnerVC : SpinnerVC?
//    var sequencer : AKAppleSequencer = AKAppleSequencer()
    var lastNoteOn:[AKDuration] = Array(repeating: AKDuration(seconds: 0), count: 100)
    var events:[MidiEvent] = []

    var scene: OtherUserScene?
    weak var clearContentView: UIView?
    weak var scrollView: UIScrollView?
    
    var stackviews = Array<UIStackView>()
    let noteColumn = [0,1,1,2,2,3,4,4,5,5,6,6]
    let noteLine =   [0,1,0,1,0,0,1,0,1,0,1,0]

//    let realm = try! Realm()
    var recordedMidiIsMuted = false

//    var currentVelocity:UInt8 = 100
//    var velocityRecording:UInt8 = 90
    var duration:CGFloat = 1
    var isRecording = false
    var myChordNotes = Array<Set<Int>>()
    var roots = Array<Bool>()
    var rootNote:Int = 48
    
    var sawIt = false
    var isPlaying = false

    var buttonColors = [
        [UIColor(red: 1, green: 147.0/255, blue: 147.0/255, alpha: 1),
         UIColor(red: 181.0/255, green: 0, blue: 0, alpha: 1)],
        [UIColor(red: 202.0/255, green: 1, blue: 198.0/255, alpha: 1),
         UIColor(red: 12.0/255, green: 183.0/255, blue: 0, alpha: 1)],
        [UIColor(red: 168.0/255, green: 214.0/255, blue: 1, alpha: 1),
         UIColor(red: 0, green: 112.0/255, blue: 214.0/255, alpha: 1)]
    ]
    
    deinit{
        self.player!.removeObserver(self, forKeyPath: "status")
        self.player!.removeObserver(self, forKeyPath: "timeControlStatus")
        self.player!.removeTimeObserver(myTimeObserver!)
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
        allSongs = realm.objects(Song.self)
        
        sliderVolumeMidi.setValue(Float(globalVar.songFirebase.songPourFile.volumePlayer), animated: true)

        createSpinnerView()

        XCDYouTubeClient.default().getVideoWithIdentifier(globalVar.songFirebase.songPourDb.videoID) { [weak self] (video, error) in
            guard let self = self else {return}
            guard video != nil else {
                globalVar.explainsThatYoutubeSucks = true
                self.deleteSpinnerView()
                popVC()
                return
            }
            
            let myUrl = self.getVideoURL(video: video!)
            self.player = AVPlayer(url: myUrl!)

            self.player!.addObserver(self, forKeyPath: "status", options: .new, context: nil)
            self.player!.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)

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
        globalVar.modeAffichage = 2
        globalVar.currentVelocity = UInt8(globalVar.songFirebase.songPourFile.volumePlayer)
        globalVar.velocityRecording = UInt8(globalVar.songFirebase.songPourFile.volumeRecording)
        globalVar.balanceNotesVsChords = 0.5
        
        globalVar.loadInstrumentsInSampler(instru:globalVar.songFirebase.songPourFile.instru1_n, instruChords: globalVar.songFirebase.songPourFile.instru2_n, showChords: globalVar.songFirebase.songPourFile.showChords)

        stackviews = [stackViewUp,stackViewMiddle,stackViewDown]
        
        let volumeYoutube = globalVar.songFirebase.songPourFile.volumeYoutube
        if (0 <= volumeYoutube && volumeYoutube <= 1){
            sliderVolume.value = globalVar.songFirebase.songPourFile.volumeYoutube
        }
        
        if(globalVar.songFirebase.songPourFile.showChords % 2 != 0){
            myChordNotes = globalVar.songFirebase.songPourFile.chordsNotes
                //globalVar.dbToSets(chordsNotes: )
            roots = globalVar.songFirebase.songPourFile.chordsRoots
                //globalVar.dbToRoots(rootsDb: )
            rootNote = globalVar.songFirebase.songPourFile.rootNote
            rootNote = ((rootNote - 40) % 12) + 40
        }
        updateButtons()

        globalVar.setSequencerFromSong(firebaseNotRealm: true)

        duration = CGFloat(globalVar.songFirebase.songPourDb.duration)
        self.totalTimeLabel.text = self.getTimeFormat(timeInt: Int(duration))
        timeSlider.setValue(0, animated: false)
        playButton.tintColor = UIColor.black
        
        globalVar.firebaseSongsManager.checkIfSongIsLiked(song: globalVar.songFirebase.songPourDb, completionFunction: firebaseToldMeItWasActuallyLiked)
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
            
            scene = OtherUserScene(size: mySKView.frame.size)
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
        
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if player != nil{
            if(object as! NSObject == player! && keyPath == "status"){
                if player!.status == .readyToPlay {
                    deleteSpinnerView()
                    player!.volume = globalVar.songFirebase.songPourFile.volumeYoutube
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
        
        popVC()
    }
    
    // ------------------------
    
    @IBAction func sliderVolumeAction(_ sender: UISlider) {
        if player != nil{
            player?.volume = sender.value / sender.maximumValue
            
            // TODO: https://stackoverflow.com/questions/9390298/iphone-how-to-detect-the-end-of-slider-drag
            globalVar.songFirebase.songPourFile.volumeYoutube = player!.volume
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
    }
    
    @IBAction func unwindToOtherUserSongVC(segue:UIStoryboardSegue) {
        globalVar.loadInstrumentsInSampler(instru:globalVar.songFirebase.songPourFile.instru1_n, instruChords: globalVar.songFirebase.songPourFile.instru2_n, showChords: globalVar.songFirebase.songPourFile.showChords)

        globalVar.currentVelocity = UInt8(globalVar.songFirebase.songPourFile.volumePlayer)
        globalVar.velocityRecording = UInt8(globalVar.songFirebase.songPourFile.volumeRecording)

        if(globalVar.songFirebase.songPourFile.showChords % 2 != 0){
            myChordNotes = globalVar.songFirebase.songPourFile.chordsNotes
//                globalVar.dbToSets(chordsNotes: )
            roots = globalVar.songFirebase.songPourFile.chordsRoots
            //globalVar.dbToRoots(rootsDb: )
            rootNote = globalVar.songFirebase.songPourFile.rootNote
            rootNote = ((rootNote - 40) % 12) + 40
        }
        updateButtons()
        
        preparerSKScene()
        let sec = globalVar.sequencer.currentPosition.seconds
        print(sec)
        scene!.bougerPianoRoll(seconds:CGFloat(sec))
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
                    modifieActionsGen(button: myButton2)
                }
            }
        }
    }
    
    func modifieActionsMelody(button:UIButton){
        button.removeTarget(nil, action: nil, for: .allEvents)

        button.addTarget(self,
            action: #selector(buttonNoteClickedWithoutRecording),
            for: .touchDown)
        button.addTarget(self,
            action: #selector(buttonNoteReleasedWithoutRecording),
            for: .touchUpInside)
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

    func modifieActionsChords(button:UIButton){
        button.removeTarget(nil, action: nil, for: .allEvents)
        
        button.addTarget(self,
                         action: #selector(rootButtonWithoutRecording),
                         for: .touchDown)
        button.addTarget(self,
                         action: #selector(rootButtonUpWithoutRecording),
                         for: .touchUpInside)
    }
    
    func modifieActionsGen(button:UIButton){
        if(globalVar.songFirebase.songPourFile.showChords % 2 == 0){
            modifieActionsMelody(button: button)
        } else {
            modifieActionsChords(button: button)
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
            
            if(globalVar.songFirebase.songPourFile.showChords % 2 == 0){
                condition = globalVar.songFirebase.songPourFile.scale[i]
            }else{
                condition = globalVar.songFirebase.songPourFile.chordsRoots[i]
            }
            
            if(condition) {
                for (index, stack) in stackviews.enumerated() {
                    let button = UIButton(type: UIButton.ButtonType.system)
                    
                    if(globalVar.songFirebase.songPourFile.showChords % 2 == 0){
                        noteNumber = globalVar.songFirebase.songPourFile.rootNote + i + (index * 12)
                    }else{
                        noteNumber = i + (index * 12)
                    }
                    button.tag = noteNumber
                    
                    button.layer.cornerRadius = 5
                    button.layer.borderColor = UIColor.black.cgColor
                    button.layer.borderWidth = 2
                    
                    button.backgroundColor = buttonColors[index][noteLine[i]]
                    
                    if(globalVar.songFirebase.songPourFile.showChords % 2 != 0){ // si chords
                        buttonName = globalVar.notesRoman[i % 12]
                        switch(globalVar.songFirebase.songPourFile.noteNames){
                        case 0: buttonName = globalVar.notesUSAccords[(rootNote+noteNumber) % 12]
                        case 1: buttonName = globalVar.notesFrenchAccords[(rootNote+noteNumber) % 12]
                        case 2: buttonName = globalVar.notesRoman[i % 12]
                        case 3: buttonName = globalVar.notesLatin[i % 12]
                        case 4: buttonName = ""
                        default: buttonName = globalVar.notesRoman[i % 12]
                        }
                        buttonName += globalVar.songFirebase.songPourFile.chordNames[noteNumber]
                    }else{ // si melodie
                        switch(globalVar.songFirebase.songPourFile.noteNames){
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
                    
                    modifieActionsGen(button: button)
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
        if(globalVar.songFirebase.songPourFile.showChords == 0){
            preparerSKSceneMelody()
        }else if(globalVar.songFirebase.songPourFile.showChords == 1){
            preparerSKSceneAccords()
        } else if(globalVar.songFirebase.songPourFile.showChords == 2){
            // todo : personaliser ?
            preparerSKSceneMelodyEtAccords()
        } else if(globalVar.songFirebase.songPourFile.showChords == 3){
            // todo : personaliser ?
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
            let colonne = noteColumn[((midiNote - globalVar.songFirebase.songPourFile.rootNote)+1200) % 12]
            let debut = CGFloat(note.position.seconds)
            scene!.ajouterRond(seconde: debut, colonne: colonne, noteNumber: midiNote)
        }
    }
    
    func preparerSKSceneMelody(){
        let liste = globalVar.sequencer.tracks[0].getMIDINoteData()
        scene!.spriteForScrollingGeometry!.removeAllChildren()
        for note in liste{
            let midiNote = Int(note.noteNumber)
            let colonne = noteColumn[((midiNote - globalVar.songFirebase.songPourFile.rootNote)+1200) % 12]
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
    
    @IBAction func sliderVolumeMidiAction(_ sender: UISlider) {
        globalVar.songFirebase.songPourFile.volumePlayer = Int(sender.value)
        globalVar.currentVelocity = UInt8(globalVar.songFirebase.songPourFile.volumePlayer)
        
        globalVar.songFirebase.songPourFile.volumeRecording = Int(sender.value)
        globalVar.velocityRecording = UInt8(globalVar.songFirebase.songPourFile.volumeRecording)
    }
    
    
    @IBAction func notesOrChords(_ sender: Any) {
        let images = ["note","chords","chordsAndNotes1-2","chordsAndNotes2-2"]
        globalVar.songFirebase.songPourFile.showChords += 1
        globalVar.songFirebase.songPourFile.showChords %= 4
        notesOrChordsButton.setBackgroundImage(UIImage(named: images[globalVar.songFirebase.songPourFile.showChords]), for: .normal)
        globalVar.updateCurrentSampler(showChords: globalVar.songFirebase.songPourFile.showChords)
        if(globalVar.songFirebase.songPourFile.showChords % 2 != 0){
            myChordNotes = globalVar.songFirebase.songPourFile.chordsNotes
            roots = globalVar.songFirebase.songPourFile.chordsRoots
            rootNote = globalVar.songFirebase.songPourFile.rootNote
            rootNote = ((rootNote - 40) % 12) + 40
        }
        updateButtons()
        preparerSKScene()
    
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

    
    @IBOutlet weak var likeButton: UIButton!
    var liked = false
    
    func firebaseToldMeItWasActuallyLiked(){
        liked = true
        updateLikeButton()
    }
    
    func updateLikeButton(){
        if(liked) {
            likeButton.setBackgroundImage(UIImage(named: "heartFull"), for: .normal)
        } else {
            likeButton.setBackgroundImage(UIImage(named: "heart"), for: .normal)
        }
    }
    
    @IBAction func likeButtonAction(_ sender: Any) {
        liked = !liked
        updateLikeButton()
        if(liked) {
            globalVar.firebaseSongsManager.likeSongInFirebase(song: globalVar.songFirebase.songPourDb)
        } else {
            globalVar.firebaseSongsManager.dislikeSongInFirebase(song: globalVar.songFirebase.songPourDb)
        }
    }
    
    @IBOutlet weak var importButton: UIButton!
    
    @IBAction func importButtonAction(_ sender: Any) {
        setupAndShowPopupImport(userId: globalVar.userId, currentVC: self, completionFunction: actuallyDoImportButtonAction)
    }
    
    func actuallyDoImportButtonAction(){
        do {
            try globalVar.gemsManager.subGems(10)
            
            // CRUD : Create
            globalVar.songFirebase.songPourDb.ownerID = globalVar.userId
            let songID = UUID().uuidString
            let oldSongId : String = globalVar.songFirebase.songPourDb.objectID.copy() as! String
            globalVar.songFirebase.songPourDb.objectID = songID
            globalVar.songFirebase.songPourDb.ownerName = globalVar.userName
            globalVar.songFirebase.songPourDb.originalID = oldSongId
            globalVar.firebaseSongsManager.saveSongStructAllToFirebase(song:globalVar.songFirebase, id: songID)
            // TODO : check it is written correctly in Firebase
            // before displaying success popup.
            
            // Save to Realm
            let song = Song()
            song.title = globalVar.songFirebase.songPourDb.title
            song.duration = globalVar.songFirebase.songPourDb.duration
            song.videoID = globalVar.songFirebase.songPourDb.videoID
            song.imageUrl = globalVar.songFirebase.songPourDb.imageUrl
            song.scale.append(objectsIn: globalVar.songFirebase.songPourFile.scale)
            song.id = songID
            song.originalID = oldSongId
            try! realm.write {
                realm.add(song)
            }
                
                // don't need the following line because we use Firebase
                // to populate realm songPourFile fields each time:
        //        globalVar.firebaseSongsManager.songFirebaseToSongRealm(songFirebase: globalVar.songFirebase.songPourFile, songRealm: song)
                
                // Success popup
            successfullyImportedPopup()
        } catch GemsManagerError.insufficientFunds(let coinsNeeded) {
            proposeGemsPurchase(self)
        } catch {
            print("Unknown error")
        }
    }
    
    func successfullyImportedPopup(){
        let title = "Success"
        let message = "The song was imported successfully."
        let popup = PopupDialog(title: title, message: message)
        let button = DefaultButton(title: "OK") {
        }
        button.backgroundColor = .green
        popup.addButton(button)
        self.present(popup, animated: true, completion: nil)
    }
    
    func askUserIfHeWantsToGoPremium(){
        let popup = getMoreGemsPopup()
        self.present(popup, animated: true, completion: nil)
    }

}
