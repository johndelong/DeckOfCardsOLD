//
//  HostManager.swift
//  DeckOfCards
//
//  Created by John DeLong on 4/2/16.
//  Copyright © 2016 delong. All rights reserved.
//

import Foundation
import MultipeerConnectivity

enum ServerState {
    case Idle,
    AcceptingConnections,
    IgnoringNewConnections
}


protocol MCServerDelegate {
    func clientDidConnect(peerID: MCPeerID)
    func clientDidDisconnect(peerID: MCPeerID)
    func sessionDidEnd()
    func serverNoNetwork()
}

class MCServer: MCNetworking {

    static let sharedInstance = MCServer()

    var connectedClients:NSMutableArray = []
    var delegate: MCServerDelegate?
    var serverState:ServerState = .Idle

    private lazy var serviceAdvertiser: MCNearbyServiceAdvertiser = {
        return MCNearbyServiceAdvertiser(peer: self.peerId, discoveryInfo: nil, serviceType: self.serviceType)
    }()

    override init() {
        super.init()
        self.serviceAdvertiser.delegate = self
        self.session.delegate = self
    }

    deinit {
        self.stopAcceptingConnections()
    }

    func startAcceptingConnections() {
        self.serverState = .AcceptingConnections
        self.serviceAdvertiser.startAdvertisingPeer()
        print("Started listening for connections")
    }

    func stopAcceptingConnections() {
        self.serverState = .IgnoringNewConnections
        self.serviceAdvertiser.stopAdvertisingPeer()
        print("Stopped listening for connections")
    }

    func endSession() {
        self.session.disconnect()
    }
}

extension MCServer : MCSessionDelegate {

    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.stringValue())")

        switch state {
        case .Connected:
            if self.serverState == .AcceptingConnections {
                if !self.connectedClients.containsObject(peerID) {
                    self.connectedClients.addObject(peerID)

                    NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                        self.delegate?.clientDidConnect(peerID)
                    }
                }
            }
        case .Connecting:
            print("Connecting...")
        case .NotConnected:
            // the nearby peer declined the invitation,
            // the connection could not be established,
            // or a previously connected peer is no longer connected
            print("Not connected")

            if self.connectedClients.containsObject(peerID) {
                self.connectedClients.removeObject(peerID)

                NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                    self.delegate?.clientDidDisconnect(peerID)
                }
            }
        }
    }

    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data.length) bytes")
//        let str = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
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

extension MCServer : MCNearbyServiceAdvertiserDelegate {

    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }

    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: ((Bool, MCSession) -> Void)) {

        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
    }

}
