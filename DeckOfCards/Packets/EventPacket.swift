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
        case madePrediction
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

    let playerCards: [PlayerID: [PlayerCard]]
    var kitty = [Card]()

    init(player: Player, deals number: Int? = nil, from deck: Deck, to players: [Player]) {

        // I'm not sure I like this logic in here. Maybe I should make another class that manages creating decks
        // for different games
        var playerCards = [PlayerID: [PlayerCard]]()
        let max = number ?? deck.cards.count
        for index in 0...deck.cards.count - 1 {
            let card = deck.cards[index]
            if index < max {
                let player = players[index % players.count]

                var hand = playerCards[player.id] ?? [PlayerCard]()
                hand.append(PlayerCard(owner: player, card: card))
                playerCards[player.id] = hand
            } else {
                self.kitty.append(card)
            }
        }

        self.playerCards = playerCards

        super.init(player: player, action: .dealt)
    }

    required init?(coder aDecoder: NSCoder) {
        guard
            let playerCards = aDecoder.decodeObject(forKey: "dealt_cards") as? [PlayerID: [PlayerCard]],
            let kitty = aDecoder.decodeObject(forKey: "kitty") as? [Card]
        else { return nil }

        self.playerCards = playerCards
        self.kitty = kitty
        super.init(coder: aDecoder)
    }

    override func encode(with aCoder: NSCoder) {
        aCoder.encode(self.playerCards, forKey: "dealt_cards")
        aCoder.encode(self.kitty, forKey: "kitty")

        super.encode(with: aCoder)
    }
}

class PlayCardPacket: ActionPacket {
    let card: PlayerCard
    let positionInHand: Int

    init(card: PlayerCard, position: Int) {
        self.card = card
        self.positionInHand = position

        super.init(player: card.owner, action: .playedCard)
    }

    required init?(coder aDecoder: NSCoder) {
        guard
            let card = aDecoder.decodeObject(forKey: "card") as? PlayerCard
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

class PlayerDecision: ActionPacket {
    enum DecisionType {
        case trump(Card.Suit?)

        // swiftlint:disable:next nesting
        enum Name: String {
            case trump
        }

        var name: Name {
            switch self {
            case .trump: return .trump
            }
        }
    }

    let decision: DecisionType

    init(player: Player, decides: DecisionType) {
        self.decision = decides
        super.init(player: player, action: .madePrediction)
    }

    required init?(coder aDecoder: NSCoder) {
        guard
            let rawDecisionType = aDecoder.decodeObject(forKey: "decision_type") as? String,
            let type = DecisionType.Name(rawValue: rawDecisionType)
        else {
            return nil
        }

        switch type {
        case .trump:
            let rawSuit = aDecoder.decodeInteger(forKey: "suit")
            let suit = Card.Suit(rawValue: rawSuit)
            self.decision = DecisionType.trump(suit)
        }

        super.init(coder: aDecoder)
    }

    override func encode(with aCoder: NSCoder) {
        aCoder.encode(self.decision.name.rawValue, forKey: "decision_type")

        switch self.decision {
        case .trump(let suit):
            guard let suit = suit else { break }
            aCoder.encode(suit.rawValue, forKey: "suit")
        }

        super.encode(with: aCoder)
    }
}
