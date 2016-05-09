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

    var comm: MCNetworking
    var session: MCSession

    var euchre = Dictionary<Scenario.ScenarioType, Scenario>();

    init(networking: MCNetworking) {
        self.comm = networking
        self.session = self.comm.session

        super.init()

        self.session.delegate = self
    }

    func startGame() {
        // Send start game signal
        let packet = Packet(type: .NewGame, payload: nil)
        let data = NSKeyedArchiver.archivedDataWithRootObject(packet)

        do {
            try self.session.sendData(data, toPeers: self.session.connectedPeers, withMode: .Reliable)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }

    func setupGame() {
        // the deal
        if let theDeal = euchre[.TheDeal] {
            // give each player x number of cards
//            let cardsPerPlayer: Int = theDeal.rules[.NumberOfCardsInHand]

        }
    }

    func theDeal() -> Scenario {
        let scenario = Scenario(type: .TheDeal)
//        scenario.rules[.NumberOfCardsInHand] = Rule.NumberOfCards.Even.rawValue
        return scenario
    }

//    func constantRules() -> Scenario {
//        let scenario = Scenario(type: .ConstantRules)
//        let rule1 = HandOrientationRule(value: .FaceUp)
//        scenario.rules[rule1.type] = rule1
//        scenario.rules[
//        return scenario
//    }
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