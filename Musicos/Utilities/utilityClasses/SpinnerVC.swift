
//https://www.hackingwithswift.com/example-code/uikit/how-to-use-uiactivityindicatorview-to-show-a-spinner-when-work-is-happening

import UIKit

class SpinnerVC: UIViewController {
    var spinner = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)

    override func loadView() {
        view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.7)
        view.addSubview(spinner)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        spinner.tintColor = .white
        spinner.color = .white
        spinner.backgroundColor = .blue
        
        spinner.startAnimating()
    }
}


/*
 func createSpinnerView() {
     let child = SpinnerVC()

     // add the spinner view controller
     addChild(child)
     child.view.frame = view.frame
     view.addSubview(child.view)
     child.didMove(toParent: self)

     // wait two seconds to simulate some work happening
     DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
         // then remove the spinner view controller
         child.willMove(toParent: nil)
         child.view.removeFromSuperview()
         child.removeFromParent()
     }
 }

 */
