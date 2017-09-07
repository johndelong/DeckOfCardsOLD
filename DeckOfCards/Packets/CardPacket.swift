//
//  CardPacket.swift
//  DeckOfCards
//
//  Created by John DeLong on 8/29/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class CardPacket: NSObject, PacketProtocol {

    let playerCards: [PlayerID: [PlayerCard]]
    let kitty: [Card]
    let cardsPlayed: [PlayerCard]
    let cardsInPlay: [PlayerCard]

    init(
        playerCards: [PlayerID: [PlayerCard]],
        kitty: [Card],
        cardsPlayed: [PlayerCard],
        cardsInPlay: [PlayerCard]
    ) {
        self.playerCards = playerCards
        self.kitty = kitty
        self.cardsPlayed = cardsPlayed
        self.cardsInPlay = cardsInPlay
    }

    required init?(coder aDecoder: NSCoder) {

        guard
            let playerCards = aDecoder.decodeObject(forKey: "player_cards") as? [PlayerID: [PlayerCard]],
            let kitty = aDecoder.decodeObject(forKey: "kitty") as? [Card],
            let cardsPlayed = aDecoder.decodeObject(forKey: "cards_played") as? [PlayerCard],
            let cardsInPlay = aDecoder.decodeObject(forKey: "cards_in_play") as? [PlayerCard]
        else {
            return nil
        }

        self.playerCards = playerCards
        self.kitty = kitty
        self.cardsPlayed = cardsPlayed
        self.cardsInPlay = cardsInPlay
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.playerCards, forKey: "player_cards")
        aCoder.encode(self.kitty, forKey: "kitty")
        aCoder.encode(self.cardsPlayed, forKey: "cards_played")
        aCoder.encode(self.cardsInPlay, forKey: "cards_in_play")
    }

    static var supportsSecureCoding: Bool {
        return true
    }
}
