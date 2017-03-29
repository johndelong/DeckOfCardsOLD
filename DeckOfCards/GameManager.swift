//
//  GameManager.swift
//  DeckOfCards
//
//  Created by John DeLong on 2/25/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import RxSwift

class GameManager {

    // Game Properties
    let requiredPlayers = 4
    let cardsInDeck = 24

    var state: GameStatePacket.State = .readyToStartGame

    // ====================================
    // Player Details
    // ====================================

    /**
        Designates the players playing in this game. The order of the players in this array designates
        their position around the table relative to me
    */
    var players = [Player.me]
    var turn: Player?
    /**
        The host is the designated state resolver. The host makes all of the decisions and updates to the game
        that should not be computed by all players.
    */
    var host: Player?
    var dealer: Player?

    // ====================================
    // Card Details
    // ====================================

    /// All the cards in each player's hand
    var playersCards = [PlayerID: [Card]]()

    /// All the cards played
    var cardsPlayed = [Card]()

    /// The cards currently in play on the table
    var cardsInPlay = [Card]()

    // Streams
    private lazy var disposeBag = DisposeBag()
    lazy var stateStream = ReplaySubject<GameStatePacket>.create(bufferSize: 1)
    lazy var playersStream = ReplaySubject<PlayerDetails>.create(bufferSize: 1)
    lazy var actionStream = ReplaySubject<ActionPacket>.create(bufferSize: 1)

    static let shared = GameManager()
    private init() {

         NetworkManager.shared.communication
            .subscribe(onNext: { [unowned self] packet in
                guard let packet = packet else { return }

                // State Packets
                if let state = packet as? GameStatePacket {
                    self.state = state.state
                    self.turn = state.turn
                    self.dealer = state.dealer
                    self.stateStream.onNext(state)
                }

                // Player Packets
                if let data = packet as? PlayerDetails {
                    self.players = data.positions
                    self.host = data.host
                    self.playersStream.onNext(data)
                }

                // Action Packets
                if let event = packet as? ActionPacket {
                    self.handleActionPacket(event)
                }
            }).disposed(by: self.disposeBag)

        NetworkManager.shared.connectedPeers.asObservable()
            .subscribe(onNext: { [unowned self] peers in
                guard !peers.isEmpty else { return }

                // If I am the host, I should let others know about player positions
                if self.host.isMe {
                    var positions = peers.map { Player(id: $0) }
                    positions.insert(Player.me, at: 0)
                    NetworkManager.shared.send(packet: PlayerDetails(host: Player.me, positions: positions))
                }
            }
        ).disposed(by: self.disposeBag)
    }

    func handleActionPacket(_ action: ActionPacket) {
        switch action.type {
        case .dealt:
            guard let action = action as? DealCardsPacket else { return }
            self.playersCards = action.cards
            self.state = .playing
        case .playedCard:
            guard let action = action as? PlayCardPacket else { return }
            self.cardsPlayed.append(action.card)
            self.cardsInPlay.append(action.card)
        case .wonTrick:
            self.turn = action.player

            // If everyone's cards are gone, we need to deal again
            print("Cards played: \(self.cardsPlayed.count)")
            if self.cardsPlayed.count == self.cardsInDeck {
                print("Updating dealer...")

                self.setDealer(player: action.player)
            }
        }

        // Update the players turn
        if let player = self.getNextPlayer(currentPlayer: action.player) {
            self.turn = player
        }

        self.actionStream.onNext(action)

        // Make additional calculations
        self.evaluateCurrentState()
    }

    func hostGame() {
        NetworkManager.shared.sendToMe(packet: PlayerDetails(host: Player.me, positions: [Player.me]))
        NetworkManager.shared.startSearching()
    }

    func findGame() {
        NetworkManager.shared.startSearching()
    }

    func startGame() {
        if self.players.count < self.requiredPlayers {
            let computerNames = ["Jim", "Dwight", "Pam"]
            for index in 0...(self.requiredPlayers - self.players.count - 1) {
                self.players.append(Player(computerName: computerNames[index]))
            }

            NetworkManager.shared.send(packet: PlayerDetails(
                    host: Player.me,
                    positions: self.players
                )
            )
        }

        self.setDealer()
    }

    /**
        Tells the players who the dealer is
     
        - Parameters:
            - player: The player who is the dealer. If not specified, a player will be choosen at random
    */
    func setDealer(player: Player? = nil) {
        let dealer: Player
        if let player = player {
            dealer = player
        } else {
            dealer = players[Int(arc4random_uniform(UInt32(players.count)))]
        }
        let state = GameStatePacket(state: .dealing, dealer: dealer, turn: dealer)
        NetworkManager.shared.send(packet: state)
    }

    func leaveGame() {
        NetworkManager.shared.disconnect()
    }

    /**
        Given the current situation, this method determines if any actions should be taken
    */
    func evaluateCurrentState() {
        // If everyone has played one card, then determine who wins this trick
        if
            self.cardsInPlay.count == self.players.count,
            let firstCard = self.cardsInPlay.first
        {
            let followSuit = firstCard.suit
            var highCard = firstCard
            for card in self.cardsInPlay {
                if card.compare(firstCard) == .orderedSame {
                    continue
                }

                if card.suit.rawValue == followSuit.rawValue {
                    if card.rank.rawValue > highCard.rank.rawValue {
                        highCard = card
                    }
                }
            }

            self.cardsInPlay.removeAll()
            if let player = highCard.owner {
                NetworkManager.shared.sendToMe(packet: ActionPacket(player: player, action: .wonTrick))
            }
        } else if (self.turn.isComputer && self.host.isMe) {
//            let hand = self.playersCards[
//            StrategyEngine.determineCardToPlay(from: <#T##[Card]#>)
        }
    }

    func dealCards() {
        NetworkManager.shared.send(packet: DealCardsPacket(player: Player.me, deals: Deck.euchre(), to: self.players))
    }

    func playCard(_ card: Card, fromPosition position: Int) {
        NetworkManager.shared.send(packet: PlayCardPacket(player: Player.me, card: card, position: position))
    }

    func getNextPlayer(currentPlayer: Player) -> Player? {
        guard let index = self.players.index(of: currentPlayer) else { return nil }

        if index == players.count - 1 {
            return players.first
        } else {
            return players[index.advanced(by: 1)]
        }
    }
}

extension GameManager {
    func cards(for playerID: PlayerID) -> [Card] {
        return self.playersCards[playerID] ?? []
    }

    var shouldDeal: Bool {
        return self.dealer.isMe || (self.dealer.isComputer && self.host.isMe)
    }
}
