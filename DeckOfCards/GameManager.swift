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

    var ai = StrategyEngine.shared
    var cs = CardService.shared
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
    private var dealer: Player?
    /**
        The host is the designated state resolver. The host makes all of the decisions and updates to the game
        that should not be computed by all players.
    */
    var host: Player?

    // ====================================
    // Card Details
    // ====================================

    /// All the cards in each player's hand
    var playerCards = [PlayerID: [PlayerCard]]()

    /// Remining Cards not dealt to players
    var kitty = [Card]()

    /// All the cards played
    var cardsPlayed = [PlayerCard]()

    /// The cards currently in play on the table
    var cardsInPlay = [PlayerCard]()

    // ====================================
    // Decisions
    // ====================================
    var availableDecisions = [Any]()

    // ====================================
    // Game Play
    // ====================================

    var trump: Card.Suit?

    // Streams
    private lazy var disposeBag = DisposeBag()

    var eventStream = ReplaySubject<PacketProtocol>.create(bufferSize: 1)

    static let shared = GameManager()
    private init() {

        NetworkManager.shared.connectedPeers.asObservable()
            .subscribe(onNext: { [weak self] peers in
                guard let _self = self else { return }

                // If I am the host, I should let others know about player positions
                if _self.host.isMe {
                    var connectedPlayers = peers.map { Player(id: $0) }
                    connectedPlayers.insert(Player.me, at: 0)

                    var updatedPlayers = connectedPlayers

                    // If we lost a player, insert a computer in their place
                    if _self.players.count > connectedPlayers.count {
                        updatedPlayers = _self.players
                        for (index, player) in _self.players.enumerated() {
                            if player.isHuman && !connectedPlayers.contains(player) {
                                let computer = Player(computerName: "Computer \(index)")
                                updatedPlayers[index] = computer

                                _self.playerCards[computer.id] = _self.playerCards[player.id]?.map({ card in
                                    return PlayerCard(owner: computer, card: card)
                                })
                                _self.playerCards[player.id] = nil
                            }
                        }
                    }

                    NetworkManager.shared.queue(packet: PlayerDetails(host: Player.me, positions: updatedPlayers))
                }

                NetworkManager.shared.sendQueuedPackets()
            }).disposed(by: self.disposeBag)

         NetworkManager.shared.communication
            .subscribe(onNext: { [weak self] packet in
                guard let _self = self else { return }
                guard let packet = packet else { return }

                // State Packets
                if let state = packet as? GameStatePacket {
                    _self.state = state.state
                    _self.turn = state.turn
                    _self.dealer = state.dealer
                }

                // Player Packets
                if let data = packet as? PlayerDetails {
                    _self.players = data.positions
                    _self.host = data.host
                }

                // Action Packets
                if let event = packet as? ActionPacket {
                    _self.handleAction(event)
                }

                // Check the current state of the game and make adjustments if needed
                _self.evaluateState()

                // If adjustments have not been made, check to see if it is the computers turn and take action
                if NetworkManager.shared.unsentPackets.isEmpty {
                    _self.handlePlayingAsComputer()
                }

                _self.eventStream.onNext(packet)

                NetworkManager.shared.sendQueuedPackets()
            }).disposed(by: self.disposeBag)

    }

    func handleAction(_ action: ActionPacket) {
        switch action.type {
        case .dealt:
            defer { self.setNextPlayer(currentPlayer: action.player) }
            guard let action = action as? DealCardsPacket else { break }

            action.playerCards.forEach { (player, cards) in
                self.playerCards[player] = self.cs.orderCards(cards)
            }
            self.kitty = action.kitty

            // Now that the cards have been dealt, it's time to start making predictions
            self.state = .decisions

            if let topCard = self.kitty.first {
                self.availableDecisions = [topCard.suit, "Pass"]
            }

        case .madePrediction:
            defer { self.setNextPlayer(currentPlayer: action.player) }
            guard let action = action as? PlayerDecision else { break }

            if case let .trump(suit) = action.decision {
                // Player did not make a decision (they passed)
                guard let suit = suit else { break }

                self.cs.options.trump = suit
                self.state = .playing

                for (playerId, hand) in self.playerCards {
                    self.playerCards[playerId] = self.cs.orderCards(hand)
                }
            }
        case .playedCard:
            defer { self.setNextPlayer(currentPlayer: action.player) }
            guard let action = action as? PlayCardPacket else { break }

            self.playerCards[action.player.id]?.remove(at: action.positionInHand)
            self.cardsPlayed.append(action.card)
            self.cardsInPlay.append(action.card)
        case .wonTrick:
            self.turn = action.player
        }
    }

    func evaluateState() {
        // if making a decision
        if self.state == .decisions {
            if self.turn == self.dealer {
                var decisions = [Card.Suit.diamonds, Card.Suit.clubs, Card.Suit.hearts, Card.Suit.spades]
                decisions = decisions.filter { suit in
                    return !self.availableDecisions.contains(where: { (choice) -> Bool in
                        guard let choice = choice as? Card.Suit else { return false }
                        return suit == choice
                    })
                }
                self.availableDecisions = decisions
            }
        } else if self.state == .playing {
            if self.cardsInPlay.count == self.players.count {

                if let player = self.cs.determineWinnerOfTrick(self.cardsInPlay) {
                    self.cardsInPlay.removeAll()

                    if self.host.isMe {
                        NetworkManager.shared.queue(packet: ActionPacket(player: player, action: .wonTrick))
                    }
                }
            }

            // If all cards have been played, then update the dealer and start again
            print("cards played: \(self.cardsPlayed.count)")
            if self.cardsPlayed.count == (self.cardsInDeck - self.kitty.count) {
                if self.host.isMe {
                    print("updating the dealer...")
                    NetworkManager.shared.queue(packet: self.getDealerPacket(player: self.turn))
                }

                // Reset round dependant properties
                self.cardsPlayed.removeAll()
                self.playerCards.removeAll()
                self.cardsInPlay.removeAll()
                self.kitty.removeAll()
            }
        }
    }

    /**
        If it is the computer's turn, then this function will determine what the computer should do
    */
    func handlePlayingAsComputer() {
        guard
            self.turn.isComputer && self.host.isMe,
            let computer = self.turn
        else { return }

        switch self.state {
        case .playing:
            if
                let hand = self.playerCards[computer.id],
                let card = ai.determineCardToPlay(from: hand, whenCardsPlayed: self.cardsInPlay),
                let index = hand.index(of: card)
            {
                NetworkManager.shared.queue(packet: PlayCardPacket(card: card, position: index))
            }
        case .dealing:
            NetworkManager.shared.queue(packet: DealCardsPacket(
                player: computer,
                deals: 20,
                from: Deck.euchre(),
                to: self.players)
            )
        case .decisions:
            NetworkManager.shared.queue(packet: PlayerDecision(player: computer, decides: .trump(nil)))
        default:
            break
        }
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

        NetworkManager.shared.send(packet: self.getDealerPacket())
    }

    /**
        Tells the players who the dealer is
     
        - Parameters:
            - player: The player who is the dealer. If not specified, a player will be choosen at random
    */
    func getDealerPacket(player: Player? = nil) -> PacketProtocol {
        let dealer: Player
        if let player = player {
            dealer = player
        } else {
            dealer = players[Int(arc4random_uniform(UInt32(players.count)))]
        }
        return GameStatePacket(state: .dealing, dealer: dealer, turn: dealer)
    }

    func leaveGame() {
        // Reset game state
        NetworkManager.shared.disconnect()
    }

    func deal(as player: Player) {
        NetworkManager.shared.send(packet: DealCardsPacket(
            player: player,
            deals: 20,
            from: Deck.euchre(),
            to: self.players)
        )
    }

    func player(played card: PlayerCard, fromPosition position: Int) {
        NetworkManager.shared.send(packet: PlayCardPacket(card: card, position: position))
    }

    private func getNextPlayer(currentPlayer: Player) -> Player? {
        guard let index = self.players.index(of: currentPlayer) else { return nil }

        if index == players.count - 1 {
            return players.first
        } else {
            return players[index.advanced(by: 1)]
        }
    }

    private func setNextPlayer(currentPlayer: Player) {
        self.turn = self.getNextPlayer(currentPlayer: currentPlayer) ?? Player.me
    }
}

extension GameManager {
    func cards(for playerID: PlayerID) -> [PlayerCard] {
        return self.playerCards[playerID] ?? []
    }
}
