//
//  HostViewController.swift
//  DeckOfCards
//
//  Created by John DeLong on 4/9/16.
//  Copyright © 2016 delong. All rights reserved.
//

import UIKit
import MultipeerConnectivity

protocol HostViewControllerDelegate {
    func hostViewControllerDidCancel(controller: HostViewController)
    func hostViewController(controller: HostViewController, didEndSessionWithReason reason: QuitReason)
}

class HostViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var delegate:HostViewControllerDelegate?
    var quitReason:QuitReason?

    override func viewDidLoad() {
        super.viewDidLoad()

        MCServer.sharedInstance.delegate = self
        MCServer.sharedInstance.startAcceptingConnections()
    }

    @IBAction func startButtonPressed(sender: AnyObject) {

        if MCServer.sharedInstance.connectedClients.count > 0 {
            let name = MCServer.sharedInstance.session.myPeerID.displayName

            Game.sharedInstance.setupCommunication(MCServer.sharedInstance)
            Game.sharedInstance.startGame()
        }
    }
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        self.quitReason = .UserQuit
        MCServer.sharedInstance.endSession()
        self.delegate?.hostViewControllerDidCancel(self)
    }
}

extension HostViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MCServer.sharedInstance.connectedClients.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = MCServer.sharedInstance.connectedClients[indexPath.row].displayName
        return cell
    }
}

extension HostViewController: MCServerDelegate {
    func clientDidConnect(peerID: MCPeerID) {
        self.tableView.reloadData()
    }

    func clientDidDisconnect(peerID: MCPeerID) {
        self.tableView.reloadData()
    }

    func sessionDidEnd() {

    }

    func serverNoNetwork() {

    }
}