//
//  File.swift
//  DeckOfCards
//
//  Created by John DeLong on 3/25/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation

class StrategyEngine {


    var options = Card.CompareOptions()

    /**
        - TODO:
            - Lay high if can win
            - Trump if cannot follow suit
            - Use teams to determine when to "lay low" if a partner already has the trick
     */
    func determineCardToPlay(from hand: [PlayerCard]) -> PlayerCard? {
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

    private func card(from hand: [PlayerCard], thatBeats highCard: Card) -> PlayerCard? {
        var minCard: PlayerCard?

        hand.forEach {
            if (
                $0.suit == highCard.suit
                && highCard.compare($0, options: self.options) == .orderedAscending
                && ( minCard?.compare($0, options: self.options) == .orderedDescending || minCard == nil )
            ) {
                minCard = $0
            }
        }

        return minCard
    }

    private func getHighestCard(from hand: [PlayerCard], of suit: Card.Suit? = nil) -> PlayerCard? {
        guard var highCard = hand.first else { return nil }

        hand.forEach {
            if let suit = suit {
                if (
                    $0.isSuit(suit, options: self.options)
                    && highCard.compare($0, options: self.options) == .orderedAscending
                ) {
                    highCard = $0
                }
            } else {
                if highCard.compare($0, options: self.options) == .orderedAscending {
                    highCard = $0
                }
            }

        }
        return highCard
    }

    private func getLowestCard(from hand: [PlayerCard], of suit: Card.Suit? = nil) -> PlayerCard? {
        guard var lowCard = hand.first else { return nil }

        hand.forEach {
            if let suit = suit {
                if $0.suit == suit && lowCard.compare($0, options: self.options) == .orderedDescending {
                    lowCard = $0
                }
            } else {
                if lowCard.compare($0, options: self.options) == .orderedDescending {
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
    func canPlay(card: PlayerCard, from hand: [PlayerCard]) -> Bool {
        guard let firstCard = GameManager.shared.cardsInPlay.first else { return true }

        if card.isSuit(firstCard.suit, options: self.options) {
            return true
        }

        let canFollowSuit = hand.contains { (card) -> Bool in
            return card.isSuit(firstCard.suit, options: self.options)
        }

        if !canFollowSuit {
            return true
        }

        return false
    }

    func determineWinnerOfTrick(_ cards: [PlayerCard]) -> Player? {
        guard let firstCard = cards.first else { return nil }

        let followSuit = firstCard.suit
        var highCard = firstCard

        for card in cards {
            var canUse = card.isSuit(followSuit, options: self.options)

            if let trump = self.options.trump {
                canUse = canUse || card.isSuit(trump, options: self.options)
            }

            if canUse && card.compare(highCard, options: options) == .orderedDescending {
                highCard = card
            }
        }

        return highCard.owner
    }
}

// Non-ai methods
extension StrategyEngine {
    func orderCards(_ hand: [PlayerCard]) -> [PlayerCard] {
        return hand.sorted { (lhs, rhs) -> Bool in
            let lhsSuit = lhs.implicitSuit(with: self.options)
            let rhsSuit = rhs.implicitSuit(with: self.options)

            return lhsSuit.rawValue > rhsSuit.rawValue ||
                (
                    lhsSuit == rhsSuit
                    && lhs.compare(rhs, options: self.options) == .orderedDescending
                )
        }
    }
}
