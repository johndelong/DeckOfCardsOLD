//
//  Packets.swift
//  DeckOfCards
//
//  Created by John DeLong on 3/1/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation
import UIKit
import MultipeerConnectivity

let packetModelKay = "doc_packet"

extension Data {
    /**
     * https://gist.github.com/zorgiepoo/ac3092b1a8c235b6f7625a10eeb569d9
     * http://stackoverflow.com/questions/40712106/encode-decoding-date-with-nscoder-in-swift-3
     */
    func decode() -> PacketProtocol? {
        let unarchiver = NSKeyedUnarchiver(forReadingWith: self)
        unarchiver.requiresSecureCoding = true

        let classes = [
            GameState.classForCoder(),
            PlayerDetails.classForCoder(),
            ActionPacket.classForCoder(),
            TurnDetails.classForCoder(),
            Card.self,
            NSArray.classForCoder(),
            MCPeerID.classForCoder()
        ]
        let packet = unarchiver.decodeObject(of: classes, forKey: packetModelKay) as? PacketProtocol
        unarchiver.finishDecoding()

        return packet
    }
}

protocol PacketProtocol: NSSecureCoding {}

extension PacketProtocol {
    func encode() -> Data {
        let encodedData = NSMutableData()
        let keyedArchiver = NSKeyedArchiver(forWritingWith: encodedData)
        keyedArchiver.requiresSecureCoding = true // make sure secure coding is enabled
        keyedArchiver.encode(self, forKey: packetModelKay)
        keyedArchiver.finishEncoding()

        return encodedData as Data
    }
}



/**
 * Maybe rename to GameState
 */
class GameState: NSObject, NSSecureCoding, PacketProtocol {
    enum State: String {
        case start
    }

    var state: State

    init(state: State) {
        self.state = state
    }

    required init?(coder aDecoder: NSCoder) {

        guard
            let stateValue = aDecoder.decodeObject(forKey: "state") as? String,
            let state = State(rawValue: stateValue)
        else {
            return nil
        }

        self.state = state
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.state.rawValue, forKey: "state")
    }

    static var supportsSecureCoding: Bool {
        return true
    }
}

/**
 *
 * Informaiton about players in this game
 *
 **/
class PlayerDetails: NSObject, NSSecureCoding, PacketProtocol {
    let host: MCPeerID
    var positions: [MCPeerID]

    init(host: MCPeerID, positions: [MCPeerID]) {
        self.host = host
        self.positions = positions
    }

    required init?(coder aDecoder: NSCoder) {
        guard
            let host = aDecoder.decodeObject(forKey: "game_host") as? MCPeerID,
            let positions = aDecoder.decodeObject(forKey: "player_positions") as? [MCPeerID]
        else {
            return nil
        }

        self.host = host
        self.positions = positions
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.host, forKey: "game_host")
        aCoder.encode(self.positions, forKey: "player_positions")
    }

    static var supportsSecureCoding: Bool {
        return true
    }
}

// player, action, value
class ActionPacket: NSObject, NSSecureCoding, PacketProtocol {
    enum Action: String {
        case deal
        case playCard
    }

    let player: MCPeerID // The player that took a specific action
    let action: Action
    let value: Data?

    init(player: MCPeerID, action: Action, value: Data? = nil) {
        self.player = player
        self.action = action
        self.value = value
    }

    required init?(coder aDecoder: NSCoder) {
        guard
            let player = aDecoder.decodeObject(forKey: "player") as? MCPeerID,
            let actionRaw = aDecoder.decodeObject(forKey: "action") as? String,
            let action = Action(rawValue: actionRaw)
        else {
            return nil
        }

        self.player = player
        self.action = action

        let value = aDecoder.decodeObject(forKey: "value") as? Data
        self.value = value
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.player, forKey: "player")
        aCoder.encode(self.action.rawValue, forKey: "action")
        aCoder.encode(self.value, forKey: "value")
    }

    static var supportsSecureCoding: Bool {
        return true
    }
}


class TurnDetails: NSObject, NSSecureCoding, PacketProtocol {
    let player: MCPeerID // The player whose turn this class describes
    let card: Card

    init(player: MCPeerID, card: Card) {
        self.player = player
        self.card = card
    }

    required init?(coder aDecoder: NSCoder) {
        guard
            let player = aDecoder.decodeObject(forKey: "player") as? MCPeerID,
            let card = aDecoder.decodeObject(forKey: "card") as? Card
        else {
            return nil
        }

        self.player = player
        self.card = card
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.player, forKey: "player")
        aCoder.encode(self.card, forKey: "card")
    }

    static var supportsSecureCoding: Bool {
        return true
    }
}
