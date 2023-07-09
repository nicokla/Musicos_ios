
import UIKit
import Kingfisher
import SwipeCellKit

class MySongsCell: SwipeTableViewCell{
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var myImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
