//
//  ClientManager.swift
//  DeckOfCards
//
//  Created by John DeLong on 4/2/16.
//  Copyright © 2016 delong. All rights reserved.
//

import Foundation
import MultipeerConnectivity

enum ClientState {
    case Idle,
    SearchingForServers,
    Connecting,
    Connected
}

protocol MatchmakingClientDelegate {
    func matchmakingClient(client: MCClient, serverBecameAvailable peerID: MCPeerID)
    func matchmakingClient(client: MCClient, serverBecameUnavailable peerID: MCPeerID)
    func matchmakingClient(client: MCClient, didDisconnectFromServer peerID: MCPeerID?)
    func matchmakingClient(client: MCClient, didConnectToServer peerID: MCPeerID?)
    func matchmakingClientNoNetwork(client: MCClient)
}

class MCClient: NSObject {

    var availableServers:NSMutableArray = []
    var connectedClients:NSMutableArray = []
    var clientState:ClientState = .Idle
    var serverPeerID:MCPeerID?
    var delegate:MatchmakingClientDelegate?

    private lazy var serviceBrowser: MCNearbyServiceBrowser = {
        return MCNearbyServiceBrowser(peer: ColorServiceManager.peerId, serviceType: ColorServiceManager.serviceType)
    }()

    lazy var session: MCSession = {
        let session = MCSession(peer: ColorServiceManager.peerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.Required)
        session.delegate = self
        return session
    }()

    override init() {
        super.init()
        self.serviceBrowser.delegate = self
    }

    deinit {
        self.serviceBrowser.stopBrowsingForPeers()
    }


    func startSearchingForServers() {
        self.clientState = .SearchingForServers
        self.serviceBrowser.startBrowsingForPeers()
        print("Started searching for servers")
    }

    func stopSearchingForServers() {
        self.serviceBrowser.stopBrowsingForPeers()
        print("Stopped searching for servers")
    }

    func disconnectFromServer() {
        print("Disconnected from server")

        self.clientState = .Idle
        self.session.disconnect()
        self.connectedClients.removeAllObjects();
        self.delegate?.matchmakingClient(self, didDisconnectFromServer: self.serverPeerID)
        self.serverPeerID = nil
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
    }

    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")

        if !self.availableServers.containsObject(peerID) {
            self.availableServers.addObject(peerID)
            self.delegate?.matchmakingClient(self, serverBecameAvailable: peerID)
        }
    }

    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
        if self.availableServers.containsObject(peerID) {
            self.availableServers.removeObject(peerID)
            self.delegate?.matchmakingClient(self, serverBecameUnavailable: peerID)
        }
    }
}

extension MCClient : MCSessionDelegate {

    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.stringValue())")
        //        self.delegate?.connectedDevicesChanged(self, connectedDevices: session.connectedPeers.map({$0.displayName}))

        // the nearby peer declined the invitation, the connection could not be established,
        // or a previously connected peer is no longer connected
        switch state {
        case .Connected:
            if self.clientState == .Connecting {
                self.clientState = .Connected
            }

            if !self.connectedClients.containsObject(peerID) {
                self.connectedClients.addObject(peerID)
                self.delegate?.matchmakingClient(self, didConnectToServer: peerID)
            }

        case .Connecting:
            if self.clientState == .SearchingForServers {
                self.clientState = .Connecting
            }
            print("Connecting...")
        case .NotConnected:
            print("Not connected")
            // Is this the server we're currently trying to connect with?
            if self.clientState == .Connecting && peerID.isEqual(self.serverPeerID) {
                self.disconnectFromServer()
            }
        }

    }

    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data.length) bytes")
        let str = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
        //        self.delegate?.colorChanged(self, colorString: str)
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