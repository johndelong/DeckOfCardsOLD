//
//  Game.swift
//  DeckOfCards
//
//  Created by John DeLong on 5/9/16.
//  Copyright © 2016 delong. All rights reserved.
//

import Foundation

class Game {

    enum PlayerRelativeToDealer {
        case Dealer
        case Left
        case Right
        case Across
    }

    enum GamePlayState {
        case StartOfGame
        case EndOfGame
        case StartOfRound
        case EndOfRound
    }

    enum Direction {
        case Left
        case Right
    }

    // ==========================================
    // Teams
    // ==========================================
    var numOfTeams: Int?
    var playersPerTeam: Int?
    var offenseVersusDefense: Bool?

    // ==========================================
    // The Deck
    // ==========================================
    var numOfDecks = 1
//    var hasCustomizedDeck: Bool = false
    var cardsInDeck = [Int]() // specify what cards should be included in the deck (1-13)
    var hasJokers: Bool = false

    // ==========================================
    // Card Values
    // ==========================================
    var aceHigh: Bool = true
    var hasTrump: Bool = false
    var hasBowers: Bool?

    // ==========================================
    // General Game Settings
    // ==========================================

    // Rounds: A new "round" begins everytime the cards are delt
    // Assumptions:
    // - Round ends when all cards have been played
    var numOfRounds: Int? = 1
    var roundsEndWhenScore: Int?


    var playerToStartRound: PlayerRelativeToDealer = .Left

    // Description:
    // - The player who lays the highest card wins
    //
    // Assumptions:
    // - Winner of trick is next to lead
    var hasTricks: Bool = false

    var playDirection: Direction = .Left

    var mustFollowSuit: Bool = true
    var numOfCardsInHand: Int = 13

    // ==========================================
    // Scoring
    // ==========================================
    var evaluateScoreWhen: GamePlayState = .EndOfRound
    var scoreEvaluationRules: Array = [Condition];

    
}
