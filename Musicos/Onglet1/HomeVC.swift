
import UIKit
import Tabman
import Pageboy

class HomeVC: TabmanViewController {
    let storyboard123 = UIStoryboard(name: "Main", bundle: nil)
    private var viewControllers:[UIViewController] = []
    let titles = ["My songs", "Favourites"]
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let ongletMySongs = storyboard123.instantiateViewController(withIdentifier: "MySongsVC123") as! MySongsVC123
        ongletMySongs.myTabBarVC = self.parent as? MyTabBarVC
        if(ongletMySongs.myTabBarVC == nil){
            print("c'est nil")
        }else{
            print("c'est pas nil")
        }
        viewControllers = [ongletMySongs, storyboard123.instantiateViewController(withIdentifier: "FavouriteSongsVC")]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        
        // Create bar
        let bar = TMBar.ButtonBar()
//        bar.backgroundColor = UIColor(red: 93.0/255, green: 188.0/255, blue: 210.0/255, alpha: 1)
        bar.layout.transitionStyle = .snap
        bar.layout.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        bar.layout.contentMode = .fit
//        bar.buttons.customize { (button) in
//            button.tintColor = .darkGray
//            button.selectedTintColor = .white
//        }

        // Add to view
        addBar(bar, dataSource: self, at: .top)
        
        
    }
}

extension HomeVC: PageboyViewControllerDataSource, TMBarDataSource {
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }

    func viewController(for pageboyViewController: PageboyViewController,
                        at index: PageboyViewController.PageIndex) -> UIViewController? {
        return viewControllers[index]
    }

    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return nil
    }

    func barItem(for bar: TMBar, at index: Int) -> TMBarItemable {
        let title = titles[index]
        return TMBarItem(title: title)
    }
//    let item = TMBarItem()
//    item.title = "Item 1"
//    item.image = UIImage(named: "item.png")
//    item.badgeValue = "New"

}

