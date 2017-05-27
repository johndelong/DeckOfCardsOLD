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

protocol CardType {
    var rank: Card.Rank { get }
    var suit: Card.Suit { get }
}

class Card: NSObject, CardType, NSCoding {
    enum Suit: Int {
        case diamonds = 1
        case clubs, hearts, spades

        func toString() -> String {
            switch self {
            case .spades:
                return "Spades"
            case .hearts:
                return "Hearts"
            case .diamonds:
                return "Diamonds"
            case .clubs:
                return "Clubs"
            }
        }
    }

    enum Rank: Int {
        case ace = 1
        case two, three, four, five, six, seven, eight, nine, ten
        case jack, queen, king

        func toString() -> String {
            switch self {
            case .ace:
                return "Ace"
            case .jack:
                return "Jack"
            case .queen:
                return "Queen"
            case .king:
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

    override public func isEqual(_ object: Any?) -> Bool {
        return self.suit == (object as? Card)?.suit && self.rank == (object as? Card)?.rank
    }
}
