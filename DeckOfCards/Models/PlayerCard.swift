//
//  PlayerCard.swift
//  DeckOfCards
//
//  Created by John DeLong on 5/7/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation

class PlayerCard: Card {
    let owner: Player

    convenience init(owner: Player, card: Card) {
        self.init(rank: card.rank, suit: card.suit, owner: owner)
    }

    init(rank: Rank, suit: Suit, owner: Player) {
        self.owner = owner
        super.init(rank: rank, suit: suit)
    }

    required init?(coder aDecoder: NSCoder) {
        guard
            let owner = aDecoder.decodeObject(forKey: "owner") as? Player
        else {
            return nil
        }

        self.owner = owner

        super.init(coder: aDecoder)
    }

    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)

        aCoder.encode(self.owner, forKey: "owner")
    }
}
