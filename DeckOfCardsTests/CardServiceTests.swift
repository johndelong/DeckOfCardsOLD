//
//  StrategyEngineTests.swift
//  DeckOfCards
//
//  Created by John DeLong on 4/8/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation

import XCTest
@testable import DeckOfCards

class CardServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testBowers() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        let player1 = Player(computerName: "com1")
        let player2 = Player(computerName: "com2")
        let player3 = Player(computerName: "com3")
        let player4 = Player(computerName: "com4")

        let cs = CardService.shared
        cs.options = CardService.CompareOptions(trump: .spades, bowers: true, aceHigh: true)

        var cardsInPlay = [PlayerCard]()

        // Test Right Bower
        cardsInPlay = [
            PlayerCard(owner: player1, card: Card(.queen, of: .spades)),
            PlayerCard(owner: player2, card: Card(.king, of: .spades)),
            PlayerCard(owner: player3, card: Card(.jack, of: .spades)),
            PlayerCard(owner: player4, card: Card(.jack, of: .clubs)),
        ]

        if let player = cs.determineWinnerOfTrick(cardsInPlay) {
            XCTAssert(player.id == player3.id)
        }

        // Test Left Bower
        cardsInPlay = [
            PlayerCard(owner: player1, card: Card(.queen, of: .spades)),
            PlayerCard(owner: player2, card: Card(.king, of: .spades)),
            PlayerCard(owner: player3, card: Card(.ace, of: .diamonds)),
            PlayerCard(owner: player4, card: Card(.jack, of: .clubs)),
        ]

        if let player = cs.determineWinnerOfTrick(cardsInPlay) {
            XCTAssert(player.id == player4.id)
        }

        // Test no bower
        cardsInPlay = [
            PlayerCard(owner: player1, card: Card(.queen, of: .spades)),
            PlayerCard(owner: player2, card: Card(.king, of: .spades)),
            PlayerCard(owner: player3, card: Card(.ace, of: .diamonds)),
            PlayerCard(owner: player4, card: Card(.jack, of: .diamonds)),
        ]

        if let player = cs.determineWinnerOfTrick(cardsInPlay) {
            XCTAssert(player.id == player2.id)
        }
    }

    func testTrump() {
        let player1 = Player(computerName: "com1")
        let player2 = Player(computerName: "com2")
        let player3 = Player(computerName: "com3")
        let player4 = Player(computerName: "com4")

        let cs = CardService.shared
        cs.options = CardService.CompareOptions(trump: .diamonds, bowers: true, aceHigh: true)
        var cardsInPlay = [PlayerCard]()

        cardsInPlay = [
            PlayerCard(owner: player1, card: Card(.ten, of: .hearts)),
            PlayerCard(owner: player2, card: Card(.queen, of: .diamonds)),
            PlayerCard(owner: player3, card: Card(.king, of: .hearts)),
            PlayerCard(owner: player4, card: Card(.jack, of: .spades)),
        ]

        if let player = cs.determineWinnerOfTrick(cardsInPlay) {
            XCTAssert(player.id == player2.id)
        }
    }

    func testFollowingSuit() {
        let player1 = Player(computerName: "com1")
        let player2 = Player(computerName: "com2")
        let player3 = Player(computerName: "com3")
        let player4 = Player(computerName: "com4")

        let cs = CardService.shared
        cs.options = CardService.CompareOptions(trump: .spades, bowers: true, aceHigh: true)
        var cardsInPlay = [PlayerCard]()

        cardsInPlay = [
            PlayerCard(owner: player1, card: Card(.ten, of: .clubs)),
            PlayerCard(owner: player2, card: Card(.king, of: .diamonds)),
            PlayerCard(owner: player3, card: Card(.ace, of: .hearts)),
            PlayerCard(owner: player4, card: Card(.queen, of: .clubs)),
        ]

        if let player = cs.determineWinnerOfTrick(cardsInPlay) {
            XCTAssert(player.id == player4.id)
        }
    }

    func testOrderCardsInHand() {
        let cs = CardService.shared
        cs.options = CardService.CompareOptions(trump: .spades, bowers: true, aceHigh: true)

        let hand = [
            Card(.ten, of: .diamonds),
            Card(.ace, of: .spades),
            Card(.jack, of: .clubs),
            Card(.jack, of: .spades),
            Card(.nine, of: .hearts),
            Card(.ten, of: .clubs),
            Card(.king, of: .diamonds),
        ]

        let ordered = cs.orderCards(hand)
        XCTAssert(ordered[0] == Card(.jack, of: .spades))
        XCTAssert(ordered[1] == Card(.jack, of: .clubs))
        XCTAssert(ordered[2] == Card(.ace, of: .spades))
        XCTAssert(ordered[3] == Card(.nine, of: .hearts))
        XCTAssert(ordered[4] == Card(.ten, of: .clubs))
        XCTAssert(ordered[5] == Card(.king, of: .diamonds))
        XCTAssert(ordered[6] == Card(.ten, of: .diamonds))
    }

    func testCanPlayCard() {
        let cs = CardService.shared
        cs.options = CardService.CompareOptions(trump: .hearts, bowers: true, aceHigh: true)

        let inPlay = [
            Card(.king, of: .hearts),
        ]

        let hand = [
            Card(.jack, of: .clubs),
            Card(.ten, of: .clubs),
            Card(.nine, of: .clubs),
            Card(.king, of: .diamonds),
            Card(.jack, of: .diamonds),
        ]

        XCTAssert(cs.canPlay(card: Card(.ace, of: .diamonds), from: hand, whenCardsPlayed: inPlay) == false)
        XCTAssert(cs.canPlay(card: Card(.king, of: .diamonds), from: hand, whenCardsPlayed: inPlay) == false)
        XCTAssert(cs.canPlay(card: Card(.jack, of: .diamonds), from: hand, whenCardsPlayed: inPlay) == true)
    }
}
