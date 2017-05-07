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
    static func determineCardToPlay(from hand: [PlayerCard]) -> PlayerCard? {
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

    static private func card(from hand: [PlayerCard], thatBeats highCard: Card) -> PlayerCard? {
        var minCard: PlayerCard?

        hand.forEach {
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

    static private func getHighestCard(from hand: [PlayerCard], of suit: Card.Suit? = nil) -> PlayerCard? {
        guard var highCard = hand.first else { return nil }

        hand.forEach {
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

    static private func getLowestCard(from hand: [PlayerCard], of suit: Card.Suit? = nil) -> PlayerCard? {
        guard var lowCard = hand.first else { return nil }

        hand.forEach {
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

    /**
     Determines whether a card can be played or not. 
     
     Assumes the following rules.
        - Must follow suit
    */
    static func canPlay(card: PlayerCard, from hand: [PlayerCard]) -> Bool {
        guard let firstCard = GameManager.shared.cardsInPlay.first else { return true }

        if card.suit == firstCard.suit {
            return true
        }

        let canFollowSuit = hand.contains { (card) -> Bool in
            return card.suit == firstCard.suit
        }

        if !canFollowSuit {
            return true
        }

        return false
    }
}
