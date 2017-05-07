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

class StrategyEngineTests: XCTestCase {

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

        var options = Card.CompareOptions(trump: .Spades, bowers: true, aceHigh: true)

        var cardsInPlay = [Card]()

        // Test Right Bower
        cardsInPlay = [
            Card(rank: .Queen, suit: .Spades, owner: player1),
            Card(rank: .King, suit: .Spades, owner: player2),
            Card(rank: .Jack, suit: .Spades, owner: player3),
            Card(rank: .Jack, suit: .Clubs, owner: player4),
        ]

        if let player = GameManager.determineWinnerOfTrick(cardsInPlay, options: options) {
            XCTAssert(player.id == player3.id)
        }

        // Test Left Bower
        cardsInPlay = [
            Card(rank: .Queen, suit: .Spades, owner: player1),
            Card(rank: .King, suit: .Spades, owner: player2),
            Card(rank: .Ace, suit: .Diamonds, owner: player3),
            Card(rank: .Jack, suit: .Clubs, owner: player4),
        ]

        if let player = GameManager.determineWinnerOfTrick(cardsInPlay, options: options) {
            XCTAssert(player.id == player4.id)
        }

        // Test no bower
        cardsInPlay = [
            Card(rank: .Queen, suit: .Spades, owner: player1),
            Card(rank: .King, suit: .Spades, owner: player2),
            Card(rank: .Ace, suit: .Diamonds, owner: player3),
            Card(rank: .Jack, suit: .Diamonds, owner: player4),
        ]

        if let player = GameManager.determineWinnerOfTrick(cardsInPlay, options: options) {
            XCTAssert(player.id == player2.id)
        }

        options = Card.CompareOptions(trump: .Diamonds, bowers: true, aceHigh: true)
        cardsInPlay = [
            Card(rank: .Ace, suit: .Clubs, owner: player1),
            Card(rank: .King, suit: .Diamonds, owner: player2),
            Card(rank: .Ten, suit: .Hearts, owner: player3),
            Card(rank: .Queen, suit: .Diamonds, owner: player4),
        ]

        if let player = GameManager.determineWinnerOfTrick(cardsInPlay, options: options) {
            XCTAssert(player.id == player2.id)
        }
    }

    func testTrump() {

    }

    func testFollowingSuit() {

    }
}
