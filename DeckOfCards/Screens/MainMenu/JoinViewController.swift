//
//  JoinViewController.swift
//  DeckOfCards
//
//  Created by John DeLong on 4/9/16.
//  Copyright © 2016 delong. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class JoinViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        MCClient.sharedInstance.delegate = self
        MCClient.sharedInstance.startSearchingForServers()

    }

    @IBAction func cancelButtonPressed(sender: AnyObject) {
        MCClient.sharedInstance.disconnectFromServer()
    }
}

extension JoinViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MCClient.sharedInstance.availableServers.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = MCClient.sharedInstance.availableServers[indexPath.row].displayName

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let peer = MCClient.sharedInstance.availableServers[indexPath.row] as? MCPeerID {
            MCClient.sharedInstance.connectToServer(peer)
        }
    }
}

extension JoinViewController: MCClientDelegate {

    func serverBecameAvailable(peerID: MCPeerID) {
        self.tableView.reloadData()
    }

    func serverBecameUnavailable(peerID: MCPeerID) {
        self.tableView.reloadData()
    }

    func didDisconnectFromServer(peerID: MCPeerID) {
        self.tableView.reloadData()
    }

    func didConnectToServer(peerID: MCPeerID) {
        let storyboard = UIStoryboard(name: "Game", bundle: nil)
        let gameViewController = storyboard.instantiateViewControllerWithIdentifier("GameViewController")
        self.presentViewController(gameViewController, animated: false, completion: nil)
    }

    func noNetwork() {

    }
}
