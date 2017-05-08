//
//  Card.swift
//  DeckOfcards
//
//  Created by John DeLong on 4/3/16.
//  Copyright © 2016 delong. All rights reserved.
//

import Foundation
import UIKit
import MultipeerConnectivity

// Resources
// http://byronknoll.blogspot.com/2011/03/vector-playing-cards.html
// https://code.google.com/archive/p/vector-playing-cards/
// http://opengameart.org/content/dice-trumps
// http://stackoverflow.com/questions/24007461/how-to-enumerate-an-enum-with-string-type
// http://opengameart.org/content/playing-cards-vector-png

class Card: NSObject, NSCoding {
    enum Suit: Int {
        case Diamonds = 1
        case Clubs, Hearts, Spades

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

    enum Rank: Int {
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

        static var count: Int {
            // Number of different cards in suit
            return 13
        }
    }

    /// Visible Rank of this card
    let rank: Rank

    /// Visible Suit of this card
    let suit: Suit

    init(_ rank: Rank, of suit: Suit) {
        self.rank = rank
        self.suit = suit
    }

    required init?(coder aDecoder: NSCoder) {
        guard
            let rank = Rank(rawValue: aDecoder.decodeInteger(forKey: "rank")),
            let suit = Suit(rawValue: aDecoder.decodeInteger(forKey: "suit"))
        else {
            return nil
        }

        self.rank = rank
        self.suit = suit
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.rank.rawValue, forKey: "rank")
        aCoder.encode(self.suit.rawValue, forKey: "suit")
    }

    func assetName() -> String {
        let suit = self.suit.toString().lowercased()
        let rank = self.rank.toString().lowercased()
        return "\(rank)_of_\(suit)"
    }

    func displayName() -> String {
        return "\(rank.toString()) of \(suit.toString())"
    }

    var faceUp: UIImage? {
        return UIImage(named: self.assetName())
    }

    static var faceDown: UIImage {
        return #imageLiteral(resourceName: "card_back")
    }
}

/// Comparison
extension Card {
    struct CompareOptions {
        var trump: Suit?
        var bowers = true
        var aceHigh = true
    }

    /// Calculated suit of this card. Is not necessarilly the same as the visible suit
    func isSuit(_ suit: Suit, options: CompareOptions) -> Bool {
        if self.suit == suit {
            return true
        }

        if let trump = options.trump, options.bowers {
            if trump == suit && self.isLeftBower(suit: trump) {
                return true
            }
        }

        return false
    }

    func compare(_ card: Card, options: CompareOptions) -> ComparisonResult {
        // Extrapolate card weights
        let cardVals = [self, card].map { card -> Int in
            var val = card.rank.rawValue

            // Ace High
            if card.rank == .Ace && options.aceHigh {
                val += Rank.count // 14
            }

            // Trump
            if let trump = options.trump {
                if card.isSuit(trump, options: options) {
                    val += Rank.count
                }

                // Bowers
                if card.isLeftBower(suit: trump) {
                    val += 4 // 15
                } else if card.isRightBower(suit: trump) {
                    val += 5 // 16
                }
            }

            return val
        }

        let lhs = cardVals.first! // swiftlint:disable:this force_unwrapping
        let rhs = cardVals.last! // swiftlint:disable:this force_unwrapping

        if lhs == rhs {
            return .orderedSame
        } else if lhs > rhs {
            return .orderedDescending
        } else {
            return .orderedAscending
        }
    }

    func implicitSuit(with options: CompareOptions) -> Suit {
        guard let trump = options.trump, options.bowers else { return self.suit }
        if self.isLeftBower(suit: trump) {
            return trump
        }

        return self.suit
    }
}

/// Trump Related Functions
extension Card {
    func isLeftBower(suit: Suit?) -> Bool {
        guard
            let suit = suit,
            self.rank == .Jack
        else { return false }

        let leftSuit: Suit
        switch suit {
        case .Diamonds:
            leftSuit = .Hearts
        case .Clubs:
            leftSuit = .Spades
        case .Hearts:
            leftSuit = .Diamonds
        case .Spades:
            leftSuit = .Clubs
        }

        return self.suit == leftSuit
    }

    func isRightBower(suit: Suit) -> Bool {
        return self.suit == suit && self.rank == .Jack
    }
}
