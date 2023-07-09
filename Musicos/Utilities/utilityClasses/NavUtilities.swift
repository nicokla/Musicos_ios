
import UIKit

func pushVC(identifier: String){
    let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    let addSongVC = storyBoard.instantiateViewController(withIdentifier: identifier)

//    let keyWindow = UIApplication.shared.connectedScenes
//            .filter({$0.activationState == .foregroundActive})
//            .map({$0 as? UIWindowScene})
//            .compactMap({$0})
//            .first?.windows
//            .filter({$0.isKeyWindow}).first
    let keyWindow = UIApplication.shared.windows.first!
    guard let navigationController = keyWindow.rootViewController as? UINavigationController else { return }
    navigationController.pushViewController(addSongVC, animated: true)
}

func popVC(){
//    let keyWindow = UIApplication.shared.connectedScenes
//            .filter({$0.activationState == .foregroundActive})
//            .map({$0 as? UIWindowScene})
//            .compactMap({$0})
//            .first?.windows
//            .filter({$0.isKeyWindow}).first
    let keyWindow = UIApplication.shared.windows.first!
    guard let navigationController = keyWindow.rootViewController as? UINavigationController else { return }

    navigationController.popViewController(animated: true)
}


func popAll(){
//    let keyWindow = UIApplication.shared.connectedScenes
//            .filter({$0.activationState == .foregroundActive})
//            .map({$0 as? UIWindowScene})
//            .compactMap({$0})
//            .first?.windows
//            .filter({$0.isKeyWindow}).first
    let keyWindow = UIApplication.shared.windows.first!
    guard let navigationController = keyWindow.rootViewController as? UINavigationController else { return }

    navigationController.popToRootViewController(animated: true)
}
