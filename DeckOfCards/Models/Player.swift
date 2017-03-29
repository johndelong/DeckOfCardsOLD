//
//  Player.swift
//  DeckOfCards
//
//  Created by John DeLong on 3/28/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//
import MultipeerConnectivity

typealias PlayerID = MCPeerID

class Player: NSObject, NSCoding {

    enum PlayerType: Int {
        case human
        case computer
    }

    let id: PlayerID
    let type: PlayerType
    let displayName: String

    convenience init(computerName: String) {
        let id = PlayerID(displayName: computerName)
        self.init(id: id, type: .computer)
    }

    init(id: PlayerID, type: PlayerType = .human) {
        self.id = id
        self.displayName = id.displayName
        self.type = type
    }

    required init?(coder aDecoder: NSCoder) {
        guard
            let playerID = aDecoder.decodeObject(forKey: "player_id") as? PlayerID,
            let displayName = aDecoder.decodeObject(forKey: "display_name") as? String,
            let type = PlayerType(rawValue: aDecoder.decodeInteger(forKey: "player_type"))
        else { return nil }

        self.id = playerID
        self.displayName = displayName
        self.type = type
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.id, forKey: "player_id")
        aCoder.encode(self.type.rawValue, forKey: "player_type")
        aCoder.encode(self.displayName, forKey: "display_name")
    }

    static var me: Player = {
        Player(id: PlayerID(displayName: UIDevice.current.name))
    }()
}

extension Optional where Wrapped: Player {
    var isMe: Bool {
        return self?.id == Player.me.id
    }

    var isComputer: Bool {
        return self?.type == .computer
    }
}
