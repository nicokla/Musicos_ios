import UIKit
import SwipeCellKit
import RealmSwift

class ChordConfigurationListVC: UIViewController, UITableViewDataSource, UITableViewDelegate, SwipeTableViewCellDelegate {
    let realm = try! Realm()
    var myIndex:Int = 0
    var rootNote:Int = 48
    
    @IBOutlet weak var boutonAdd: UIButton!
    @IBOutlet weak var myTableView: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeTableOptions {
        var options = SwipeTableOptions()
        options.expansionStyle = .destructive
        return options
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            self.updateModel(at: indexPath)
        }
        
        // customize the action appearance
        deleteAction.image = UIImage(named: "delete-icon")
        
        return [deleteAction]
    }
    
    func updateModel(at indexPath: IndexPath) {
        
        if let songForDeletion = globalVar.chordConfigs?[indexPath.row]{
            do {
                try self.realm.write {
                    self.realm.delete(songForDeletion)
                }
            } catch {
                print("Error deleting song, \(error)")
            }
        }
    }
    

    //var listConfigs:[ChordConfiguration]
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //print("voili voila \(globalVar.chordConfigs?.count)")
        return globalVar.chordConfigs?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chordConfigurationCell", for: indexPath) as! ChordConfigurationCell
        
        cell.delegate = self
        
        if let listConfigs = globalVar.chordConfigs?[indexPath.row]{
            cell.titleLabel.text = listConfigs.title
            cell.detailLabel.text = listConfigs.detail
        }
        
        return cell
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        //if let parentVC = parent as? SettingsScaleVC2{
          //  if let grandParent = parentVC.parent as? SettingsScaleVC{
                //rootNote = grandParent.song!.rootNote
                rootNote = globalVar.song!.rootNote
            //}
        //}
        //myTableView.reloadData()
        // Do any additional setup after loading the view.
    }
    



    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // print(globalVar.songs[indexPath.row].title)
        myIndex = indexPath.row
        performSegue(withIdentifier: "openConfig", sender: tableView.cellForRow(at: indexPath))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //if segue.identifier == "openConfig" { //
        if let mySender = sender as? UITableViewCell{
            if let nextVC = segue.destination as? ChordConfigVC{ // on va la bas
                nextVC.fromWhere = 1
                nextVC.numList = myIndex
                let chordConf = globalVar.chordConfigs![myIndex]
                nextVC.myChordConfig2 = chordConf
                nextVC.myChordNotes = globalVar.dbToSets(chordsNotes: chordConf.chordsNotes)
                nextVC.roots = globalVar.dbToRoots(rootsDb: chordConf.roots)
                nextVC.myChordNames = globalVar.dbToNames(namesDb: chordConf.chordNames)
                nextVC.myTitle = chordConf.title
            }
        } else if let nextVC = segue.destination as? ChordConfigVC{
            // on va aussi la bas, mais pas a cause du table view --> on ajoute
            // ( necessaire pour exclure le cas du rewind )
            nextVC.fromWhere = 2
            nextVC.myChordNotes = globalVar.defaultConfig!
            nextVC.roots = globalVar.defaultRoots
            nextVC.myChordNames = globalVar.defaultChordNames!
            nextVC.myTitle = "New configuration"
        }
    }

    
    @IBAction func newChordConfig(_ sender: Any) {
        performSegue(withIdentifier: "openConfig", sender: self)

    }
    
    

    @IBAction func unwindToConfigList(segue:UIStoryboardSegue) {
        myTableView.reloadData()
    }
    
    @IBAction func goBack(_ sender: Any) {
        performSegue(withIdentifier: "unwindToMaster", sender: self)
    }
    
}



