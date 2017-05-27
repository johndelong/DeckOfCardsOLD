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
        cs.options = CardService.CompareOptions(trump: .Spades, bowers: true, aceHigh: true)

        var cardsInPlay = [PlayerCard]()

        // Test Right Bower
        cardsInPlay = [
            PlayerCard(owner: player1, card: Card(.Queen, of: .Spades)),
            PlayerCard(owner: player2, card: Card(.King, of: .Spades)),
            PlayerCard(owner: player3, card: Card(.Jack, of: .Spades)),
            PlayerCard(owner: player4, card: Card(.Jack, of: .Clubs)),
        ]

        if let player = cs.determineWinnerOfTrick(cardsInPlay) {
            XCTAssert(player.id == player3.id)
        }

        // Test Left Bower
        cardsInPlay = [
            PlayerCard(owner: player1, card: Card(.Queen, of: .Spades)),
            PlayerCard(owner: player2, card: Card(.King, of: .Spades)),
            PlayerCard(owner: player3, card: Card(.Ace, of: .Diamonds)),
            PlayerCard(owner: player4, card: Card(.Jack, of: .Clubs)),
        ]

        if let player = cs.determineWinnerOfTrick(cardsInPlay) {
            XCTAssert(player.id == player4.id)
        }

        // Test no bower
        cardsInPlay = [
            PlayerCard(owner: player1, card: Card(.Queen, of: .Spades)),
            PlayerCard(owner: player2, card: Card(.King, of: .Spades)),
            PlayerCard(owner: player3, card: Card(.Ace, of: .Diamonds)),
            PlayerCard(owner: player4, card: Card(.Jack, of: .Diamonds)),
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
        cs.options = CardService.CompareOptions(trump: .Diamonds, bowers: true, aceHigh: true)
        var cardsInPlay = [PlayerCard]()

        cardsInPlay = [
            PlayerCard(owner: player1, card: Card(.Ten, of: .Hearts)),
            PlayerCard(owner: player2, card: Card(.Queen, of: .Diamonds)),
            PlayerCard(owner: player3, card: Card(.King, of: .Hearts)),
            PlayerCard(owner: player4, card: Card(.Jack, of: .Spades)),
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
        cs.options = CardService.CompareOptions(trump: .Spades, bowers: true, aceHigh: true)
        var cardsInPlay = [PlayerCard]()

        cardsInPlay = [
            PlayerCard(owner: player1, card: Card(.Ten, of: .Clubs)),
            PlayerCard(owner: player2, card: Card(.King, of: .Diamonds)),
            PlayerCard(owner: player3, card: Card(.Ace, of: .Hearts)),
            PlayerCard(owner: player4, card: Card(.Queen, of: .Clubs)),
        ]

        if let player = cs.determineWinnerOfTrick(cardsInPlay) {
            XCTAssert(player.id == player4.id)
        }
    }

    func testOrderCardsInHand() {
        let cs = CardService.shared
        cs.options = CardService.CompareOptions(trump: .Spades, bowers: true, aceHigh: true)

        let hand = [
            Card(.Ten, of: .Diamonds),
            Card(.Ace, of: .Spades),
            Card(.Jack, of: .Clubs),
            Card(.Jack, of: .Spades),
            Card(.Nine, of: .Hearts),
            Card(.Ten, of: .Clubs),
            Card(.King, of: .Diamonds),
        ]

        let ordered = cs.orderCards(hand)
        XCTAssert(ordered[0] == Card(.Jack, of: .Spades))
        XCTAssert(ordered[1] == Card(.Jack, of: .Clubs))
        XCTAssert(ordered[2] == Card(.Ace, of: .Spades))
        XCTAssert(ordered[3] == Card(.Nine, of: .Hearts))
        XCTAssert(ordered[4] == Card(.Ten, of: .Clubs))
        XCTAssert(ordered[5] == Card(.King, of: .Diamonds))
        XCTAssert(ordered[6] == Card(.Ten, of: .Diamonds))
    }

    func testCanPlayCard() {
        let cs = CardService.shared
        cs.options = CardService.CompareOptions(trump: .Hearts, bowers: true, aceHigh: true)

        let inPlay = [
            Card(.King, of: .Hearts),
        ]

        let hand = [
            Card(.Jack, of: .Clubs),
            Card(.Ten, of: .Clubs),
            Card(.Nine, of: .Clubs),
            Card(.King, of: .Diamonds),
            Card(.Jack, of: .Diamonds),
        ]

        XCTAssert(cs.canPlay(card: Card(.Ace, of: .Diamonds), from: hand, whenCardsPlayed: inPlay) == false)
        XCTAssert(cs.canPlay(card: Card(.King, of: .Diamonds), from: hand, whenCardsPlayed: inPlay) == false)
        XCTAssert(cs.canPlay(card: Card(.Jack, of: .Diamonds), from: hand, whenCardsPlayed: inPlay) == true)
    }
}
