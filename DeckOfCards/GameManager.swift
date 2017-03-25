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

    var players = [MCPeerID]()

    // who played the card
    // the order in which the cards were played
    // the card played

    var cardsInPlay = [Card]()
    var cardsPlayed = [Card]()
    var myCards = [Card]()

    var state: GameStatePacket.State
    var turn: MCPeerID
    var dealer: MCPeerID

    // Streams
    private lazy var disposeBag = DisposeBag()
    lazy var stateStream = Variable<GameStatePacket?>(nil)
    lazy var playersStream = Variable<PlayerDetails?>(nil)
    lazy var eventStream = Variable<ActionPacket?>(nil)

    static let shared = GameManager()
    private init() {

        // Set an initial value
        self.state = .unknown
        self.turn = NetworkManager.me
        self.dealer = NetworkManager.me
        self.players.append(NetworkManager.me)

         NetworkManager.shared.communication
            .subscribe(onNext: { [unowned self] packet in
                guard let packet = packet else { return }

                // State Packets
                if let state = packet as? GameStatePacket {
                    self.state = state.state
                    self.turn = state.turn
                    self.dealer = state.dealer
                    self.stateStream.value = state
                }

                // Player Packets
                if let players = packet as? PlayerDetails {
                    self.players = players.positions
                    self.playersStream.value = players
                }

                // Action Packets
                if let event = packet as? ActionPacket {
                    if
                        event.action == .dealt,
                        let data = event.value,
                        let cards = NSKeyedUnarchiver.unarchiveObject(with: data) as? [MCPeerID: [Card]],
                        let myCards = cards[NetworkManager.me]
                    {
                        self.myCards = myCards
                        self.state = .playing
                    }

                    if
                        event.action == .playedCard,
                        let data = event.value,
                        let payload = NSKeyedUnarchiver.unarchiveObject(with: data) as? CardPlayedPayload
                    {
                        self.cardsPlayed.append(payload.card)
                        self.cardsInPlay.append(payload.card)
                    }

                    if event.action == .wonTrick {
                        self.turn = event.player

                        // If everyone's cards are gone, we need to deal again
                        print("Cards played: \(self.cardsPlayed.count)")
                        if self.cardsPlayed.count == self.cardsInDeck {
                            print("Updating dealer...")

                            self.setDealer(player: event.player)
                        }
                    } else if let player = self.getNextPlayer(currentPlayer: event.player) {
                        self.turn = player
                    }

                    self.eventStream.value = event
                    self.evaluateCurrentState()
                }
            }).disposed(by: self.disposeBag)

        NetworkManager.shared.connectedPeers.asObservable()
            .subscribe(onNext: { [unowned self] peers in
                guard !peers.isEmpty else { return }

                // If I am the host, I should let others know about player positions
                if self.playersStream.value?.host == NetworkManager.me {
                    var positions = [MCPeerID]()
                    positions.append(NetworkManager.me)
                    for peer in peers {
                        positions.append(peer)
                    }

                    NetworkManager.shared.send(packet: PlayerDetails(host: NetworkManager.me, positions: positions))
                }
            }
        ).disposed(by: self.disposeBag)
    }

    func hostGame() {
        NetworkManager.shared.sendToMe(packet: PlayerDetails(host: NetworkManager.me, positions: [NetworkManager.me]))
        NetworkManager.shared.startSearching()
    }

    func findGame() {
        NetworkManager.shared.startSearching()
    }

    func startGame() {
        if self.players.count < self.requiredPlayers {
            let computerNames = ["Jim", "Dwight", "Pam"]
            var computers = [Player]()
            var positions = self.playersStream.value?.positions ?? [Player]()
            for index in 0...(self.requiredPlayers - self.players.count - 1) {
                let computer = Player(displayName: computerNames[index])
                computers.append(computer)
                positions.append(computer)
            }

            NetworkManager.shared.send(packet: PlayerDetails(
                    host: NetworkManager.me,
                    positions: positions,
                    computers: computers
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
    func setDealer(player: MCPeerID? = nil) {
        let dealer: MCPeerID
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
        }
    }

    func dealCards() {
        NetworkManager.shared.send(packet: ActionPacket.dealCards(to: self.players))
    }

    func playCard(_ card: Card, fromPosition position: Int) {
        NetworkManager.shared.send(packet: ActionPacket.player(
            NetworkManager.me,
            played: card,
            fromPosition: position)
        )
    }

    func getNextPlayer(currentPlayer: MCPeerID) -> MCPeerID? {
        guard
            let players = self.playersStream.value?.positions,
            let index = players.index(of: currentPlayer)
        else { return nil }

        if index == players.count - 1 {
            return players.first
        } else {
            return players[index.advanced(by: 1)]
        }
    }

    static var isMyTurn: Bool {
        return GameManager.shared.turn == NetworkManager.me
    }

    static var isDealer: Bool {
        return GameManager.shared.dealer == NetworkManager.me
    }

    static var isHost: Bool {
        return GameManager.shared.playersStream.value?.host == NetworkManager.me
    }
}
