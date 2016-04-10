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
//    func hostViewController(controller: HostViewController, startGameWithSession session: MCSession, playerName name: NSString, andClients clients: NSArray);
}

class HostViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var delegate:HostViewControllerDelegate?
    var quitReason:QuitReason?

    lazy var mcServer: MCServer = {
        let server = MCServer()
        server.delegate = self
        return server
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        mcServer.startAcceptingConnections()
    }

    @IBAction func startButtonPressed(sender: AnyObject) {

        if self.mcServer.connectedClients.count > 0 {
            let name = mcServer.session.myPeerID.displayName


//            self.delegate?.hostViewController(self, startGameWithSession: mcServer.session, playerName: name, andClients: mcServer.connectedClients)
        }
    }
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        self.quitReason = .UserQuit
        self.mcServer.endSession()
        self.delegate?.hostViewControllerDidCancel(self)
    }
}

extension HostViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mcServer.connectedClients.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = self.mcServer.connectedClients[indexPath.row].displayName
        return cell
    }
}

extension HostViewController: MatchmakingServerDelegate {
    func matchmakingServer(server: MCServer, clientDidConnect peerID: NSString) {
        self.tableView.reloadData()
    }

    func matchmakingServer(server: MCServer, clientDidDisconnect peerID: NSString) {

    }

    func matchmakingServerSessionDidEnd(server: MCServer) {

    }

    func matchmakingServerNoNetwork(server: MCServer) {

    }
}