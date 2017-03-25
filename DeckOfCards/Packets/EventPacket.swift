//
//  EventPacket.swift
//  DeckOfCards
//
//  Created by John DeLong on 3/17/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation
import MultipeerConnectivity

// IDEA: Make subclass of this class for every event type
// player, action, value
class ActionPacket: NSObject, PacketProtocol {
    enum Action: String {
        case dealt
        case playedCard
        case wonTrick
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

    static func dealCards(to players: [MCPeerID]) -> ActionPacket {
        let deck = Deck.euchre()
        var cards = [MCPeerID: [Card]]()
        var index = 0
        for card in deck.cards {
            let player = players[index % players.count]
            card.owner = player

            var hand = cards[player] ?? [Card]()
            hand.append(card)
            cards[player] = hand

            index += 1
        }
        let data = NSKeyedArchiver.archivedData(withRootObject: cards)
        return ActionPacket(player: NetworkManager.me, action: .dealt, value: data)
    }

    static func player(_ player: MCPeerID, played card: Card, fromPosition position: Int) -> ActionPacket {
        let payload = CardPlayedPayload(card: card, position: position)
        let data = NSKeyedArchiver.archivedData(withRootObject: payload)
        return ActionPacket(player: player, action: .playedCard, value: data)
    }
}

class CardPlayedPayload: NSObject, NSCoding {
    let card: Card
    let positionInHand: Int

    init(card: Card, position: Int) {
        self.card = card
        self.positionInHand = position
    }

    required init?(coder aDecoder: NSCoder) {
        guard
            let card = aDecoder.decodeObject(forKey: "card") as? Card
        else {
            return nil
        }

        self.card = card
        self.positionInHand = aDecoder.decodeInteger(forKey: "position")
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.card, forKey: "card")
        aCoder.encode(self.positionInHand, forKey: "position")
    }
}
