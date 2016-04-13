//
//  ClientManager.swift
//  DeckOfCards
//
//  Created by John DeLong on 4/2/16.
//  Copyright © 2016 delong. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol MCClientDelegate {
    func serverBecameAvailable(peerID: MCPeerID)
    func serverBecameUnavailable(peerID: MCPeerID)
    func didDisconnectFromServer(peerID: MCPeerID)
    func didConnectToServer(peerID: MCPeerID)
    func noNetwork()
}

class MCClient: MCNetworking {

    static let sharedInstance = MCClient()

    var isBrowsing = false
    var availableServers:NSMutableArray = []

    var serverPeerID:MCPeerID?
    var delegate:MCClientDelegate?

    private lazy var serviceBrowser: MCNearbyServiceBrowser = {
        return MCNearbyServiceBrowser(peer: self.peerId, serviceType: self.serviceType)
    }()

    override init() {
        super.init()
        self.serviceBrowser.delegate = self
        self.session.delegate = self
    }

    func startSearchingForServers() {
        if !self.isBrowsing {
            self.isBrowsing = true
            self.serviceBrowser.startBrowsingForPeers()
            print("Started searching for available servers")
        }
    }

    func stopSearchingForServers() {
        if self.isBrowsing {
            self.isBrowsing = false
            self.serviceBrowser.stopBrowsingForPeers()
            print("Stopped searching for available servers")
        }
    }

    func disconnectFromServer() {
        self.stopSearchingForServers()
        self.session.disconnect()
        self.availableServers.removeAllObjects()

        if let serverPeerID = self.serverPeerID {
            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                self.delegate?.didDisconnectFromServer(serverPeerID)
            }

            self.serverPeerID = nil
        }

        print("Disconnected from server")
    }

    func connectToServer(peerID: MCPeerID) {
        NSLog("%@", "invitePeer: \(peerID)")
        self.serverPeerID = peerID
        self.serviceBrowser.invitePeer(peerID, toSession: self.session, withContext: nil, timeout: 10)
    }

}

extension MCClient : MCNearbyServiceBrowserDelegate {

    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.delegate?.noNetwork()
        }
    }

    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")

        if !self.availableServers.containsObject(peerID) {
            self.availableServers.addObject(peerID)

            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                self.delegate?.serverBecameAvailable(peerID)
            }
        }
    }

    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")

        if self.availableServers.containsObject(peerID) {
            self.availableServers.removeObject(peerID)

            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                self.delegate?.serverBecameUnavailable(peerID)
            }
        }

        // Is this the server we're currently trying to connect with?
        if peerID.isEqual(self.serverPeerID) {
            print("The server we have been trying to connect to has been lost")
            self.disconnectFromServer()
        }
    }
}

extension MCClient : MCSessionDelegate {

    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.stringValue())")

        switch state {
        case .Connecting:
            print("Connecting...")
        case .Connected:
            print("Connected")
            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                self.delegate?.didConnectToServer(peerID)
            }
        case .NotConnected:
            // the nearby peer declined the invitation, 
            // the connection could not be established,
            // or a previously connected peer is no longer connected
            print("Not connected")

            // Is this the server we're currently trying to connect with?
            if peerID.isEqual(self.serverPeerID) {
                print("We have been disconnected from the server")
                self.disconnectFromServer()
            }
        }
    }

    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data.length) bytes")
    }

    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }

    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }

    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    
}