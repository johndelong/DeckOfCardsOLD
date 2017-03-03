//
//  Deck.swift
//  DeckOfCards
//
//  Created by John DeLong on 4/23/16.
//  Copyright © 2016 delong. All rights reserved.
//

import Foundation

class Deck {

    var cards = Array<Card>()

    init() {
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
                rankIndex = rankIndex + 1
            }
            suitIndex = suitIndex + 1
        }
    }

    func shuffle() {
        let count = self.cards.count - 1
        var shuffledCards = Array<Card>()
        for _ in 0...count {
            let pos = random() % self.cards.count
            let card = self.cards[pos]
            shuffledCards.append(card)
            self.cards.removeAtIndex(pos)
        }

        self.cards = shuffledCards
    }

    func printDeck() {
        for card in self.cards {
            print(card.displayName())
        }
    }
}
