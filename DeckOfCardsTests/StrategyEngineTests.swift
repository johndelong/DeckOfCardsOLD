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
        cs.options = CardService.CompareOptions(trump: .diamonds, bowers: true, aceHigh: true)

        let hand = [
            Card(.ace, of: .hearts),
            Card(.jack, of: .hearts),
            Card(.queen, of: .diamonds),
            Card(.ten, of: .diamonds),
            Card(.ten, of: .spades),
        ]

        let inPlay = [
            Card(.ace, of: .diamonds),
            Card(.king, of: .diamonds),
            Card(.nine, of: .spades),
        ]

        let card = StrategyEngine.shared.determineCardToPlay(from: hand, whenCardsPlayed: inPlay)

        XCTAssert(card == Card(.jack, of: .hearts))
    }

}
