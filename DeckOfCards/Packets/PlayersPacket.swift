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
    let host: Player
    var positions: [Player]
    let computers: [Player]

    init(host: MCPeerID, positions: [MCPeerID], computers: [Player] = []) {
        self.host = host
        self.positions = positions
        self.computers = computers
    }

    required init?(coder aDecoder: NSCoder) {
        guard
            let host = aDecoder.decodeObject(forKey: "game_host") as? Player,
            let positions = aDecoder.decodeObject(forKey: "player_positions") as? [Player],
            let computers = aDecoder.decodeObject(forKey: "computers") as? [Player]
        else {
            return nil
        }

        self.host = host
        self.positions = positions
        self.computers = computers
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.host, forKey: "game_host")
        aCoder.encode(self.positions, forKey: "player_positions")
        aCoder.encode(self.computers, forKey: "computers")
    }
}
