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


    @IBAction func hostGameButtonPressed(sender: AnyObject) {

    }

    @IBAction func joinGameButtonPressed(sender: AnyObject) {

    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @IBAction func unwindToMainMenu(sender: UIStoryboardSegue) {

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
