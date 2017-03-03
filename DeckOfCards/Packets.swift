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

        let classes = [GameState.classForCoder(), NSArray.classForCoder(), MCPeerID.classForCoder()]
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
    var players: [MCPeerID]
    var dealer: MCPeerID

    init(players: [MCPeerID], dealer: MCPeerID) {
        self.players = players
        self.dealer = dealer
    }

    required init?(coder aDecoder: NSCoder) {

        guard
            let players = aDecoder.decodeObject(forKey: "players") as? [MCPeerID],
            let dealer = aDecoder.decodeObject(forKey: "dealer") as? MCPeerID
        else {
            return nil
        }

        self.players = players
        self.dealer = dealer
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.players, forKey: "players")
        aCoder.encode(self.dealer, forKey: "dealer")
    }

    static var supportsSecureCoding: Bool {
        return true
    }
}
