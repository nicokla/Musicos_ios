
import UIKit
//import YoutubeEngine
import ReactiveSwift
import RealmSwift
import FirebaseAuth

//import enum Result.NoError

final class SearchItemsVC: UITableViewController {
    
    let realm = try! Realm()
    var parentVC:YoutubeVC?

    @IBOutlet private var searchBar: UISearchBar!

   let model = MutableItemsViewModel<SearchItem>()
   override func viewDidLoad() {
      super.viewDidLoad()

      self.tableView.keyboardDismissMode = .onDrag

      self.model
         .provider
         .producer
         .flatMap(.latest) {
            provider -> SignalProducer<Void, Never> in
            if let pageLoader = provider?.pageLoader {
            // self.parentVC!.myActivityIndicator.stopAnimating()
               return pageLoader
                  .on(failed: {
                     [weak self] error in
                     self?.presentError(error)
                  })
                  .flatMapError { _ in .empty }
            }
            return .empty
         }
         .startWithCompleted{}

      self.model
         .provider
         .producer.flatMap(.latest) {
            provider -> SignalProducer<[SearchItem], Never> in
            guard let provider = provider else {
               return SignalProducer(value: [])
            }
            return provider.items.producer
         }
         .startWithValues {
            [weak self] _ in
            self?.tableView.reloadData()
            //self?.parentVC!.myActivityIndicator.stopAnimating()
      }
    }

   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return self.model.items.count
   }

   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let item = self.model.items[indexPath.row]
      switch item {
      case .video(let video):
          // swiftlint:disable:next force_cast
          let cell = tableView.dequeueReusableCell(withIdentifier: "VideoCell", for: indexPath) as! VideoCell
          cell.video = video
          return cell
      case .playlist(_):
        return UITableViewCell()
      case .channel(_):
        return UITableViewCell()
    }
   }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)  {
        do {
            try globalVar.gemsManager.subGems(6)
            performSegue(withIdentifier: "showContent", sender: tableView.cellForRow(at: indexPath))
            //content = contents[indexPath.row]
            //tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        } catch GemsManagerError.insufficientFunds(let coinsNeeded) {
            let popup = getMoreGemsPopup()
            present(popup, animated: true, completion: nil)
        } catch {
            print("Unknown Error")
        }
    }


   override func scrollViewDidScroll(_ scrollView: UIScrollView) {
      guard let provider = self.model.provider.value, !provider.items.value.isEmpty && !provider.isLoadingPage else {
         return
      }

      let lastCellIndexPath = IndexPath(row: provider.items.value.count - 1, section: 0)
      if tableView.cellForRow(at: lastCellIndexPath) == nil {
         return
      }

      provider.pageLoader?.startWithFailed {
         [weak self] error in
         self?.presentError(error)
      }
   }

    
    func getDuration(date:DateComponents) -> Float{
        let hour = date.hour ?? 0
        let minute =  date.minute ?? 0
        let second =  date.second ?? 0
        let nanosecond = date.nanosecond ?? 0 // in practice zero ??
        return Float(3600*hour + 60*minute + second) + (Float(nanosecond)/1e9)
    }

    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let controller = segue.destination as? PlayerVC,
        let cell = sender as? VideoCell,
        let video = cell.video else {
            return
        }

        let song = Song()
    
        song.imageUrl = video.snippet!.defaultImage.url.absoluteString
        song.title = video.snippet!.title
        song.videoID = video.id
        song.duration = getDuration(date: video.contentDetails!.duration)
        print("duration: \(song.duration)")
        song.scale.removeAll()
        song.scale.append(objectsIn: [true, true, true, true, true, true, true, true, true, true, true, true])
        song.id = UUID().uuidString
       
        try! realm.write {
            realm.add(song)
        }
        
        // CRUD : Create song
        globalVar.firebaseSongsManager.createSongRealmToFirebase(song: song)
        
    
        globalVar.song = song

        globalVar.setsToDb(myChordNotes: globalVar.defaultConfig!, chordsNotes: globalVar.song!.chordsNotes)
        globalVar.rootsToDb(roots: globalVar.defaultRoots, rootsDb: globalVar.song!.chordsRoots)
        globalVar.namesToDb(names: globalVar.defaultChordNames!, namesDb: globalVar.song!.chordNames)
        
        
        //controller.song = song

   }

   private func presentError(_ error: NSError) {
      let alert = UIAlertController(title: "Request failed",
                                    message: error.localizedDescription,
                                    preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
      self.present(alert, animated: true, completion: nil)
   }
}
