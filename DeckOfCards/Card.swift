//
//  Card.swift
//  DeckOfcards
//
//  Created by John DeLong on 4/3/16.
//  Copyright © 2016 delong. All rights reserved.
//

import Foundation

// Resources
// http://opengameart.org/content/dice-trumps
// http://stackoverflow.com/questions/24007461/how-to-enumerate-an-enum-with-string-type

class Card {
    enum Suit:Int {
        case Hearts = 1
        case Diamonds, Clubs, Spades

        func toString() -> String {
            switch self {
            case .Spades:
                return "Spades"
            case .Hearts:
                return "Hearts"
            case .Diamonds:
                return "Diamonds"
            case .Clubs:
                return "Clubs"
            }
        }
    }

    enum Rank:Int {
        case Ace = 1
        case Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten
        case Jack, Queen, King

        func toString() -> String {
            switch self {
            case .Ace:
                return "Ace"
            case .Jack:
                return "Jack"
            case .Queen:
                return "Queen"
            case .King:
                return "King"
            default:
                return String(self.rawValue)
            }
        }
    }

    let rank:Rank
    let suit:Suit

    init(rank: Rank, suit: Suit) {
        self.rank = rank
        self.suit = suit
    }

    func assetName() -> String {
        let suit = self.suit.toString()
        let rank = self.rank.rawValue
        return (String(suit[suit.startIndex]).lowercased() + String(rank))
    }

    func displayName() -> String {
        return "\(rank.toString()) of \(suit.toString())"
    }
}
