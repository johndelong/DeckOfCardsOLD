//
//  MainMenu.swift
//  DeckOfcards
//
//  Created by John DeLong on 4/3/16.
//  Copyright © 2016 delong. All rights reserved.
//

import UIKit

class MainMenuViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var hostGame: UIButton!
    @IBOutlet weak var joinGame: UIButton!
    @IBOutlet weak var hostNameTextField: UITextField!
    @IBOutlet weak var startGame: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var connectedPlayersTextView: UITextView!

    var isHost = false
    var isClient = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func hostGameButtonPressed(sender: AnyObject) {

    }

    @IBAction func joinGameButtonPressed(sender: AnyObject) {

    }

    @IBAction func startGameButtonPressed(sender: AnyObject) {

    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @IBAction func unwindToMainMenu(sender: UIStoryboardSegue)
    {
//        let sourceViewController = sender.sourceViewController
        // Pull any data from the view controller which initiated the unwind segue.
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let hostViewController = segue.destinationViewController as? HostViewController {
            hostViewController.delegate = self;
        }
    }

}

extension MainMenuViewController : HostViewControllerDelegate {
    func hostViewControllerDidCancel(controller: HostViewController) {
        // do nothing???
    }

    func hostViewController(controller: HostViewController, didEndSessionWithReason reason: QuitReason) {
        // maybe show a popup
    }
}



extension MainMenuViewController : ColorServiceManagerDelegate {

    func connectedDevicesChanged(manager: ColorServiceManager, connectedDevices: [String]) {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            print("Connections: \(connectedDevices)")
        }
    }

    func colorChanged(manager: ColorServiceManager, colorString: String) {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            
//            switch colorString {
//            case "red":
////                self.changeColor(UIColor.redColor())
//            case "yellow":
//                self.changeColor(UIColor.yellowColor())
//            default:
//                NSLog("%@", "Unknown color value received: \(colorString)")
//            }
        }
    }

}
