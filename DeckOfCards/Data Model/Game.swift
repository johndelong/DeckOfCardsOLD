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

class Game: NSObject {

    static let sharedInstance = Game()

    var communication:MCNetworking?
    

//    var networkRole: NetworkRole

//    override init() {
//
//    }

//    override init() {
//
//    }

    func setupCommunication(communication: MCNetworking) {
        self.communication = communication
        communication.session.delegate = self
    }

    func startGame() {
        // Send start game signal
        let packet = Packet(type: .NewGame, msg: "Testing")
        let data = NSKeyedArchiver.archivedDataWithRootObject(packet)

        if let com = self.communication {
            do {
                try com.session.sendData(data, toPeers: com.session.connectedPeers, withMode: .Reliable)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }

}

extension Game : MCSessionDelegate {
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.stringValue())")

        switch state {
        case .Connecting:
            print("Connecting...")
        case .Connected:
            print("Connected")
        case .NotConnected:
            print("Not connected")
        }
    }

    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data.length) bytes")

        guard let packet = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Packet else {
            print("Data received was not a reconizable packet")
            return
        }

        print(packet.type.rawValue)
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