//
//  ViewController.swift
//  DeckOfCards
//
//  Created by John DeLong on 4/2/16.
//  Copyright © 2016 delong. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {

    // Setup an array to store all accepted client connections
    
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var dataTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.dataTextField.delegate = self

        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(self.didReceiveData(_:)),
            name:HostManager.DataReceivedNotification,
            object: nil
        )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func didReceiveData(notification: NSNotification) {
        print(notification.object)
        if let msg = notification.object as? String {
            self.tempLabel.text = msg
        }
    }

    @IBAction func hostButtonPressed(sender: AnyObject) {
        if !HostManager.manager.isRunning {
            HostManager.manager.start()
            self.statusLabel.text = "Host Started"
        } else {
            HostManager.manager.stop()
            self.statusLabel.text = "Host Stopped"
        }
    }

    @IBAction func clientButtonPressed(sender: AnyObject) {
        ClientManager.manager.startSocket(self.dataTextField.text!)
    }
    
    @IBAction func sendButtonPressed(sender: AnyObject) {

        ClientManager.manager.writeData(self.dataTextField.text!)
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

