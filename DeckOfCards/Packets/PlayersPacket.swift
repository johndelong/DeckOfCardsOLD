//
//  PlayersPacket.swift
//  DeckOfCards
//
//  Created by John DeLong on 3/19/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation
import MultipeerConnectivity

/**
 *
 * Informaiton about players in this game
 *
 **/
class PlayerDetails: NSObject, PacketProtocol {
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