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

        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(self.didReceiveData(_:)),
            name:HostManager.DataReceivedNotification,
            object: nil
        )
        self.hostNameTextField.delegate = self
        self.startGame.enabled = false

        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(self.connectionEstablished(_:)),
            name:HostManager.ConnectionEstablishedNotification,
            object: nil
        )

        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(self.connectionLost(_:)),
            name:HostManager.ConnectionLostNotification,
            object: nil
        )

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func didReceiveData(notification: NSNotification) {
        print(notification.userInfo)
        if let msg = notification.userInfo?["data"] as? String {
            if msg == "start" {
                self.performSegueWithIdentifier("PresentGameSegue", sender: self)
            }
        }
    }

    func connectionEstablished(notification: NSNotification) {
        print(notification.userInfo)
        if let msg = notification.userInfo?["data"] as? String {
            self.connectedPlayersTextView.text = self.connectedPlayersTextView.text + "\n" + msg + " joined"
        }
    }

    func connectionLost(notification: NSNotification) {
        print("connection lost")
    }

    @IBAction func hostGameButtonPressed(sender: AnyObject) {
        if HostManager.sharedInstance.start() {
            self.hostGame.enabled = false
            self.joinGame.enabled = false
            self.hostNameTextField.enabled = false
            self.hostGame.enabled = false
            self.startGame.enabled = true
            self.connectedPlayersTextView.hidden = false

            self.statusLabel.text = "You are hosting a new game.\nPress Start Game when ready."
        }
    }

    @IBAction func joinGameButtonPressed(sender: AnyObject) {
        self.hostGame.enabled = false
        self.joinGame.enabled = false
        self.hostNameTextField.enabled = false
        self.hostGame.enabled = false
        self.startGame.enabled = false
        self.statusLabel.text = "You joined a new game.\nWaiting for host to start the game."

        ClientManager.sharedInstance.connectToHost(self.hostNameTextField.text!)
    }

    @IBAction func startGameButtonPressed(sender: AnyObject) {
        HostManager.sharedInstance.writeData("start")
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}
