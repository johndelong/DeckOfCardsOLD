//
//  GameStatePacket.swift
//  DeckOfCards
//
//  Created by John DeLong on 3/19/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation
import MultipeerConnectivity

/**
 * Information that is useful at any point in the game
 *   - Is the game finished? (State)
 *   - Who is the dealer
 *   - Whose turn is it
 *   - What is the score
 *   - What round is it
 */
class GameStatePacket: NSObject, PacketProtocol {
    enum State: String {
        //        case start
        case dealing
        case playing
        case unknown
    }

    let state: State
    let dealer: MCPeerID
    let turn: MCPeerID

    init(state: State, dealer: MCPeerID, turn: MCPeerID) {
        self.state = state
        self.dealer = dealer
        self.turn = turn
    }

    required init?(coder aDecoder: NSCoder) {

        guard
            let stateValue = aDecoder.decodeObject(forKey: "state") as? String,
            let state = State(rawValue: stateValue),
            let dealer = aDecoder.decodeObject(forKey: "dealer") as? MCPeerID,
            let turn = aDecoder.decodeObject(forKey: "turn") as? MCPeerID
            else {
                return nil
        }

        self.state = state
        self.dealer = dealer
        self.turn = turn
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.state.rawValue, forKey: "state")
        aCoder.encode(self.dealer, forKey: "dealer")
        aCoder.encode(self.turn, forKey: "turn")
    }

    static var supportsSecureCoding: Bool {
        return true
    }
}