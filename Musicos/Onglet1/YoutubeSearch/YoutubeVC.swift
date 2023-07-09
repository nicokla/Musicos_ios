import UIKit
//import YoutubeEngine
import ReactiveSwift
import PopupDialog

private let _defaultEngine: Engine = {
    // AIzaSyDkwZzpuw-7C2U-ZGUvBRGSUbdjtn0VrKo
    // AIzaSyCgwWIve2NhQOb5IHMdXxDaRHOnDrLdrLg
    let engine = Engine(authorization: .key("AIzaSyDkwZzpuw-7C2U-ZGUvBRGSUbdjtn0VrKo"))
   //engine.logEnabled = true
   return engine
}()

extension Engine {
   static var defaultEngine: Engine {
      return _defaultEngine
   }
}

final class YoutubeViewModel {
   let keyword = MutableProperty("")
}

final class YoutubeVC: UIViewController {

   @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet weak var myActivityIndicator: UIActivityIndicatorView!
    
   fileprivate let model = YoutubeViewModel()

	override func viewWillAppear(_ animated: Bool) {
		let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
		textFieldInsideSearchBar?.attributedPlaceholder = NSAttributedString(string: "Search videos here",
			  attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        textFieldInsideSearchBar?.textColor = UIColor.darkGray
        reactIfYoutubeSucked(self)
	}
	
   override func viewDidLoad() {
      super.viewDidLoad()
    
        //myActivityIndicator.sizeToFit()
    
      self.navigationItem.titleView = self.searchBar
      self.automaticallyAdjustsScrollViewInsets = false
   }

   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      guard let contentController = segue.destination as? SearchItemsVC else {
         return
      }
    
    contentController.parentVC = self
    
      contentController.model.mutableProvider <~ self.model.keyword.signal
         .debounce(0.5, on: QueueScheduler.main)
         .map { keyword -> AnyItemsProvider<SearchItem>? in
            if keyword.isEmpty {
               return nil
            }
            return AnyItemsProvider { token, limit in
                let request: SearchRequest = .search(
                                        withTerm: keyword,
                                        requiredVideoParts: [.statistics, .contentDetails],
                                        requiredChannelParts: [.statistics],
                                        requiredPlaylistParts: [.snippet],
                                        limit: limit,
                                        pageToken: token
                                    )
               return Engine.defaultEngine
                  .search(request)
                  .map { page in (page.items, page.nextPageToken) }
            }
      }
    
    
   }
}

extension YoutubeVC: UISearchBarDelegate {
   func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
      // self.model.keyword.value = searchText
   }

   func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
      self.model.keyword.value = searchBar.text!
      //myActivityIndicator.startAnimating()
      searchBar.resignFirstResponder()
   }
    func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {
        //self.model.keyword.value = searchBar.text!
    }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        //self.model.keyword.value = searchBar.text!
    }
}
