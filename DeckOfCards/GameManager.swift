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

    var eventStream = ReplaySubject<PacketProtocol>.create(bufferSize: 1)

    static let shared = GameManager()
    private init() {

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

         NetworkManager.shared.communication
            .subscribe(onNext: { [unowned self] packet in
                guard let packet = packet else { return }

                // State Packets
                if let state = packet as? GameStatePacket {
                    self.state = state.state
                    self.turn = state.turn
                    self.eventStream.onNext(state)
                }

                // Player Packets
                if let data = packet as? PlayerDetails {
                    self.players = data.positions
                    self.host = data.host
                    self.eventStream.onNext(data)
                }

                // Action Packets
                if let event = packet as? ActionPacket {
                    // Update properties
                    self.updateProperties(event)
                    self.eventStream.onNext(event)
                }

                // Make additional calculations
                self.postCalculations()
            }).disposed(by: self.disposeBag)

    }

    func postCalculations() {
        // Is round over? (i.e. all cards have been played)
        // If yes, determine what should happen next
        if self.handleGameStateUpdates() {
            return
        }

        // If is computer's turn, then play as the computer
        if self.handlePlayingAsComputer() {
            return
        }
    }

    /**
        Analyzes the current situation and determine of updates should be made
    */
    func handleGameStateUpdates() -> Bool {

        if self.state == .playing {
            // If everyone has played a card, determine who the winner is
            if self.cardsInPlay.count == self.players.count {
                if let player = self.determineWinnerOfTrick() {
                    self.cardsInPlay.removeAll()
                    NetworkManager.shared.sendToMe(packet: ActionPacket(player: player, action: .wonTrick))
                    return true
                }
            }

            // If all cards have been played, then update the dealer and start again
            if self.cardsPlayed.count == self.cardsInDeck {
                // Reset round dependant properties

                self.cardsPlayed.removeAll()
                self.playersCards.removeAll()
                self.cardsInPlay.removeAll()

                self.setDealer(player: self.turn)
                return true
            }
        }

        return false
    }

    /**
        If it is the computer's turn, then this function will determine what the computer should do
    */
    func handlePlayingAsComputer() -> Bool {
        guard
            self.turn.isComputer && self.host.isMe,
            let computer = self.turn
        else { return false }

        if self.state == .playing {
            if
                let hand = self.playersCards[computer.id],
                let card = StrategyEngine.determineCardToPlay(from: hand),
                let index = hand.index(of: card)
            {
                self.player(computer, playedCard: card, fromPosition: index)
                return true
            }
        }

        if self.state == .dealing {
            self.deal(as: computer)
        }

        return false
    }

    func updateProperties(_ action: ActionPacket) {
        switch action.type {
        case .dealt:
            guard let action = action as? DealCardsPacket else { return }
            self.turn = self.getNextPlayer(currentPlayer: action.player) ?? Player.me
            action.cards.forEach { (player, cards) in
                self.playersCards[player] = self.orderCards(cards)
            }

            self.state = .playing
        case .playedCard:
            guard let action = action as? PlayCardPacket else { return }
            self.turn = self.getNextPlayer(currentPlayer: action.player) ?? Player.me
            self.playersCards[action.player.id]?.remove(at: action.positionInHand)
            self.cardsPlayed.append(action.card)
            self.cardsInPlay.append(action.card)
        case .wonTrick:
            self.turn = action.player
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

    func determineWinnerOfTrick() -> Player? {
        guard let firstCard = self.cardsInPlay.first else { return nil }
        let followSuit = firstCard.suit
        var highCard = firstCard
        for card in self.cardsInPlay {
            if card.suit == followSuit && card.compare(highCard) == .orderedDescending {
                highCard = card
            }
        }

        return highCard.owner
    }

    func orderCards(_ cards: [Card]) -> [Card] {
        return cards.sorted { (lhs, rhs) -> Bool in
            return lhs.suit.rawValue > rhs.suit.rawValue ||
                (lhs.suit.rawValue == rhs.suit.rawValue && lhs.compare(rhs) == .orderedDescending)
        }
    }

    func deal(as player: Player) {
        NetworkManager.shared.send(packet: DealCardsPacket(player: player, deals: Deck.euchre(), to: self.players))
    }

    func player(_ player: Player, playedCard card: Card, fromPosition position: Int) {
        NetworkManager.shared.send(packet: PlayCardPacket(player: player, card: card, position: position))
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
}
