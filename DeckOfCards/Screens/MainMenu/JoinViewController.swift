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


    lazy var mcClient: MCClient = {
        let client = MCClient()
        client.delegate = self
        return client
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        mcClient.startSearchingForServers()

    }



}

extension JoinViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.mcClient.clientState == .Connected {
            return self.mcClient.connectedClients.count
        } else {
            return self.mcClient.availableServers.count
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = UITableViewCell()
        if self.mcClient.clientState == .Connected {
            cell.textLabel?.text = mcClient.connectedClients[indexPath.row].displayName
        } else {
            cell.textLabel?.text = mcClient.availableServers[indexPath.row].displayName
        }

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let peer = mcClient.availableServers[indexPath.row] as? MCPeerID {
            self.mcClient.connectToServer(peer)
        }
    }
}

extension JoinViewController: MatchmakingClientDelegate {

    func matchmakingClient(client: MCClient, serverBecameAvailable peerID: MCPeerID) {
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
            })

    }

    func matchmakingClient(client: MCClient, serverBecameUnavailable peerID: MCPeerID) {
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        })
    }

    func matchmakingClient(client: MCClient, didDisconnectFromServer peerID: MCPeerID?) {
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        })
    }

    func matchmakingClient(client: MCClient, didConnectToServer peerID: MCPeerID?) {
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        })
    }

    func matchmakingClientNoNetwork(client: MCClient) {

    }
}
