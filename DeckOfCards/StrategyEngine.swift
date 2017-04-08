//
//  File.swift
//  DeckOfCards
//
//  Created by John DeLong on 3/25/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation

class StrategyEngine {

    var teams = [[Player]]()

    /**
        - TODO:
            - Lay high if can win
            - Trump if cannot follow suit
            - Use teams to determine when to "lay low" if a partner already has the trick
     */
    static func determineCardToPlay(from hand: [Card]) -> Card? {
        guard !hand.isEmpty else { return nil }

        let cardsInPlay = GameManager.shared.cardsInPlay
        if let firstCard = cardsInPlay.first {

            if
                let winningCard = self.getHighestCard(from: cardsInPlay, of: firstCard.suit),
                let card = self.card(from: hand, thatBeats: winningCard)
            {
                return card
            }

            return self.getLowestCard(from: hand, of: firstCard.suit) ?? self.getLowestCard(from: hand)
        } else {
            // Player is leading
            return self.getHighestCard(from: hand)
        }
    }

    static private func card(from cards: [Card], thatBeats highCard: Card) -> Card? {
        var minCard: Card?

        cards.forEach {
            if $0.suit == highCard.suit
                && highCard.compare($0) == .orderedAscending
                // swiftlint:disable:next opening_brace
                && ( minCard?.compare($0) == .orderedDescending || minCard == nil )
            {
                minCard = $0
            }
        }

        return minCard
    }

    static private func getHighestCard(from cards: [Card], of suit: Card.Suit? = nil) -> Card? {
        guard var highCard = cards.first else { return nil }

        cards.forEach {
            if let suit = suit {
                if $0.suit == suit && highCard.compare($0) == .orderedAscending {
                    highCard = $0
                }
            } else {
                if highCard.compare($0) == .orderedAscending {
                    highCard = $0
                }
            }

        }
        return highCard
    }

    static private func getLowestCard(from cards: [Card], of suit: Card.Suit? = nil) -> Card? {
        guard var lowCard = cards.first else { return nil }

        cards.forEach {
            if let suit = suit {
                if $0.suit == suit && lowCard.compare($0) == .orderedDescending {
                    lowCard = $0
                }
            } else {
                if lowCard.compare($0) == .orderedDescending {
                    lowCard = $0
                }
            }
        }
        return lowCard
    }
}
