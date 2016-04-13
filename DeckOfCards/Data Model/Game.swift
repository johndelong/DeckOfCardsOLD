//
//  Game.swift
//  DeckOfCards
//
//  Created by John DeLong on 4/12/16.
//  Copyright © 2016 delong. All rights reserved.
//


/*
 
 This class manages the entire game
 
*/



import Foundation
import MultipeerConnectivity

enum NetworkRole {
    case Host, Client
}

enum GameState {
    case WaitingForSignIn,
    WaitingForReady,
    Dealing,
    Playing,
    GameOver,
    Quitting
}

class Game: NSObject {

    var state: GameState
    var networkRole: NetworkRole

    init(role: NetworkRole) {
        self.state = .WaitingForReady
        self.networkRole = role
    }

}

extension Game : MCSessionDelegate {

    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        switch state {
        case .Connected:
            print("Connected")
        case .Connecting:
            print("Connecting...")
        case .NotConnected:
            print("Not connected")
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
