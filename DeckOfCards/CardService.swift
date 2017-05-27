//
//  CardCompareService.swift
//  DeckOfCards
//
//  Created by John DeLong on 5/19/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation

// add card ordering to this service
class CardService {

    private init() {}
    static let shared = CardService()

    struct CompareOptions {
        var trump: Card.Suit?
        var bowers = true
        var aceHigh = true
    }
    var options = CompareOptions()

    func card<T: CardType>(from hand: [T], thatBeats highCard: T) -> T? {
        var minCard: T?

        hand.forEach { card in
            if card.implicitSuit == highCard.implicitSuit {
                guard let min = minCard else {
                    minCard = card
                    return
                }

                if highCard.value < card.value && min.value > card.value {
                    minCard = card
                }
            }
        }

        return minCard
    }

    func getHighestCard<T: CardType>(from hand: [T], of suit: Card.Suit? = nil) -> T? {
        guard var highCard = hand.first else { return nil }

        hand.forEach {
            if let suit = suit {
                if
                    $0.implicitSuit == suit
                    && highCard.value < $0.value
                {
                    highCard = $0
                }
            } else {
                if highCard.value < $0.value {
                    highCard = $0
                }
            }

        }
        return highCard
    }

    func getLowestCard<T: CardType>(from hand: [T], of suit: Card.Suit? = nil) -> T? {
        guard var lowCard = hand.first else { return nil }

        hand.forEach {
            if let suit = suit {
                if
                    $0.implicitSuit == suit
                    && lowCard.value > $0.value
                {
                    lowCard = $0
                }
            } else {
                if lowCard.value > $0.value {
                    lowCard = $0
                }
            }
        }
        return lowCard
    }

    func canPlay(card: CardType, from hand: [CardType], whenCardsPlayed cardsInPlay: [CardType]) -> Bool {
        guard let firstCard = cardsInPlay.first else { return true }

        if card.implicitSuit == firstCard.implicitSuit {
            return true
        }

        let canFollowSuit = hand.contains { (card) -> Bool in
            return card.implicitSuit == firstCard.implicitSuit
        }

        if !canFollowSuit {
            return true
        }

        return false
    }
}

/// Trump Related Functions
extension CardService {
    func isLeftBower(_ card: CardType) -> Bool {
        guard card.rank == .Jack else { return false }

        let leftSuit: Card.Suit
        switch card.suit {
        case .Diamonds:
            leftSuit = .Hearts
        case .Clubs:
            leftSuit = .Spades
        case .Hearts:
            leftSuit = .Diamonds
        case .Spades:
            leftSuit = .Clubs
        }

        return self.options.trump == leftSuit
    }

    func isRightBower(_ card: CardType) -> Bool {
        return self.options.trump == card.suit && card.rank == .Jack
    }
}

extension CardService {
    func orderCards<T: CardType>(_ hand: [T]) -> [T] {
        return hand.sorted { (lhs, rhs) -> Bool in
            return lhs.implicitSuit.rawValue > rhs.implicitSuit.rawValue
                || (lhs.implicitSuit == rhs.implicitSuit && lhs.value > rhs.value)
        }
    }

    func determineWinnerOfTrick(_ cards: [PlayerCard]) -> Player? {
        guard let firstCard = cards.first else { return nil }

        let followSuit = firstCard.implicitSuit
        var highCard = firstCard

        for card in cards {
            var canUse = card.implicitSuit == followSuit

            if let trump = self.options.trump {
                canUse = canUse || card.implicitSuit == trump
            }

            if canUse && card.value > highCard.value {
                highCard = card
            }
        }

        return highCard.owner
    }
}

/// Helper
private extension CardType {
    var value: Int {
        var val = self.rank.rawValue
        let cardService = CardService.shared
        let options = cardService.options

        // Ace High
        if self.rank == .Ace && options.aceHigh {
            val += Card.Rank.count // 14
        }

        // Trump
        if let trump = options.trump {
            if  self.implicitSuit == trump {
                val += Card.Rank.count
            }

            // Bowers
            if cardService.isLeftBower(self) {
                val += 4 // 15
            } else if cardService.isRightBower(self) {
                val += 5 // 16
            }
        }

        return val
    }

    // When playing with bowers, if (lets says) spades are trump, then the jack of clubs
    // is actually a spade and not a club. Therefore, this method will report the left
    // bower to be the same suit as trump
    var implicitSuit: Card.Suit {
        let cardService = CardService.shared
        let options = cardService.options

        guard let trump = options.trump, options.bowers else { return self.suit }
        if cardService.isLeftBower(self) {
            return trump
        }

        return self.suit
    }
}
