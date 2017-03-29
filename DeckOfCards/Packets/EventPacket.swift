//
//  EventPacket.swift
//  DeckOfCards
//
//  Created by John DeLong on 3/17/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation
import MultipeerConnectivity

/**
    This packet describes a Player taking an Action of some kind
 */
class ActionPacket: NSObject, PacketProtocol {
    enum ActionType: String {
        case dealt
        case playedCard
        case wonTrick
    }

    let player: Player // The player that took a specific action
    let type: ActionType

    init(player: Player, action: ActionType) {
        self.player = player
        self.type = action
    }

    required init?(coder aDecoder: NSCoder) {
        guard
            let player = aDecoder.decodeObject(forKey: "player") as? Player,
            let actionRaw = aDecoder.decodeObject(forKey: "action_type") as? String,
            let type = ActionType(rawValue: actionRaw)
        else {
            return nil
        }

        self.player = player
        self.type = type
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.player, forKey: "player")
        aCoder.encode(self.type.rawValue, forKey: "action_type")
    }

}

class DealCardsPacket: ActionPacket {

    let cards: [PlayerID: [Card]]

    init(player: Player, deals deck: Deck, to players: [Player]){
        var cards = [PlayerID: [Card]]()
        var index = 0
        for card in deck.cards {
            let player = players[index % players.count]
            card.owner = player

            var hand = cards[player.id] ?? [Card]()
            hand.append(card)
            cards[player.id] = hand

            index += 1
        }

        self.cards = cards

        super.init(player: player, action: .dealt)
    }

    required init?(coder aDecoder: NSCoder) {
        guard
            let cards = aDecoder.decodeObject(forKey: "dealt_cards") as? [PlayerID: [Card]]
        else { return nil }

        self.cards = cards
        super.init(coder: aDecoder)
    }

    override func encode(with aCoder: NSCoder) {
        aCoder.encode(self.cards, forKey: "dealt_cards")

        super.encode(with: aCoder)
    }
}

class PlayCardPacket: ActionPacket {
    let card: Card
    let positionInHand: Int

    init(player: Player, card: Card, position: Int) {
        self.card = card
        self.positionInHand = position

        super.init(player: player, action: .playedCard)
    }

    required init?(coder aDecoder: NSCoder) {
        guard
            let card = aDecoder.decodeObject(forKey: "card") as? Card
        else {
            return nil
        }

        self.card = card
        self.positionInHand = aDecoder.decodeInteger(forKey: "position")

        super.init(coder: aDecoder)
    }

    override func encode(with aCoder: NSCoder) {
        aCoder.encode(self.card, forKey: "card")
        aCoder.encode(self.positionInHand, forKey: "position")

        super.encode(with: aCoder)
    }
}
