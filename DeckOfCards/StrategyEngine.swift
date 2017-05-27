//
//  File.swift
//  DeckOfCards
//
//  Created by John DeLong on 3/25/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation

class StrategyEngine {

    static let shared = StrategyEngine()
    private init() {}

    let cs = CardService.shared

    /**
        - TODO:
            - Lay high if can win
            - Trump if cannot follow suit
            - Use teams to determine when to "lay low" if a partner already has the trick
     */
    func determineCardToPlay<T: CardType>(from hand: [T], whenCardsPlayed cardsInPlay: [T]) -> T? {
        guard !hand.isEmpty else { return nil }

        if let firstCard = cardsInPlay.first {
            if
                let winningCard = self.cs.getHighestCard(from: cardsInPlay, of: firstCard.suit),
                let card = self.cs.card(from: hand, thatBeats: winningCard)
            {
                return card
            }

            return self.cs.getLowestCard(from: hand, of: firstCard.suit) ?? self.cs.getLowestCard(from: hand)
        } else {
            // Player is leading
            return self.cs.getHighestCard(from: hand)
        }
    }
}
