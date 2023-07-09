import PopupDialog

func getMoreGemsPopup() -> PopupDialog {
    let title = "Not enough gems!"
    let message = "You don't have enough gems left to do this. Click \"Learn more\" to learn about gems."
    let popup = PopupDialog(title: title, message: message)
    let buttonOne = CancelButton(title: "Not now") {
        print("You canceled the dialog.")
    }
//    IAPService.shared.getProducts()
    let buttonTwo = DefaultButton(title: "Learn more") {
//        let seconds = 1.0
//        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
//            IAPService.shared.purchase(product: .nonConsumable)
//        }
        pushVC(identifier: "BuyGemsVC")
    }
    buttonTwo.backgroundColor = .green
    popup.addButtons([buttonOne, buttonTwo])
    return popup
}


func proposeGemsPurchase(_ currentVC: UIViewController){
    let popup = getMoreGemsPopup()
    currentVC.present(popup, animated: true, completion: nil)
}

func reactIfYoutubeSucked(_ currentVC: UIViewController){
    if globalVar.explainsThatYoutubeSucks {
        globalVar.explainsThatYoutubeSucks = false
        let title = "This video is blocked"
        let message = "Sadly Youtube blocks this video from our app :'( Only about half of youtube videos are made available to other apps by Youtube. Please try to find another youtube video with the song you are searching."
        let popup = PopupDialog(title: title, message: message)
        let button = DefaultButton(title: "OK") {
        }
        button.backgroundColor = .blue
        popup.addButton(button)
        currentVC.present(popup, animated: true, completion: nil)
    }
}
