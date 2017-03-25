//
//  Deck.swift
//  DeckOfCards
//
//  Created by John DeLong on 4/23/16.
//  Copyright © 2016 delong. All rights reserved.
//

import Foundation

class Deck {

    var cards = [Card]()
    let aceHigh: Bool

    init() {
        self.aceHigh = true
        createDeck()
        shuffle()
    }

    func createDeck() {
        var suitIndex = 1
        while let suit = Card.Suit(rawValue: suitIndex) {
            var rankIndex = 1
            while let rank = Card.Rank(rawValue: rankIndex) {
                let card = Card(rank: rank, suit: suit)
                self.cards.append(card)
                rankIndex += 1
            }
            suitIndex += 1
        }
    }

    func shuffle() {
        let count = self.cards.count - 1
        var shuffledCards = [Card]()
        for _ in 0...count {
            let pos = Int(arc4random()) % self.cards.count
            let card = self.cards[pos]
            shuffledCards.append(card)
            self.cards.remove(at: pos)
        }

        self.cards = shuffledCards
    }

    func printDeck() {
        for card in self.cards {
            print(card.displayName())
        }
    }

    static func euchre() -> Deck {
        let deck = Deck()
        var index = 0
        for card in deck.cards {
            var calculatedRank = card.rank.rawValue
            if card.rank.rawValue == 1 && deck.aceHigh {
                calculatedRank = 14
            }

            if calculatedRank < 9 {
                deck.cards.remove(at: index)
                continue
            }
            index += 1
        }
        return deck
    }
}
