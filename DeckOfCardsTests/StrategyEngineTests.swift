//
//  StrategyEngineTests.swift
//  DeckOfCards
//
//  Created by John DeLong on 5/26/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation

import XCTest
@testable import DeckOfCards

class StrategyEngineTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDetermineCardToPlay() {
        let cs = CardService.shared
        cs.options = CardService.CompareOptions(trump: .Diamonds, bowers: true, aceHigh: true)

        let hand = [
            Card(.Ace, of: .Hearts),
            Card(.Jack, of: .Hearts),
            Card(.Queen, of: .Diamonds),
            Card(.Ten, of: .Diamonds),
            Card(.Ten, of: .Spades),
        ]

        let inPlay = [
            Card(.Ace, of: .Diamonds),
            Card(.King, of: .Diamonds),
            Card(.Nine, of: .Spades),
        ]

        let card = StrategyEngine.shared.determineCardToPlay(from: hand, whenCardsPlayed: inPlay)

        XCTAssert(card == Card(.Jack, of: .Hearts))
    }

}
