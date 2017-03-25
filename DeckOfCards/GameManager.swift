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
    let maxPlayers = 4

    var players = [MCPeerID]()

    // who played the card
    // the order in which the cards were played
    // the card played
    var cardsPlayed = [Card]()

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
                    if event.action == .dealt {
                        self.state = .playing
                    }

                    if
                        event.action == .playedCard,
                        let data = event.value,
                        let card = NSKeyedUnarchiver.unarchiveObject(with: data) as? Card
                    {
                        self.cardsPlayed.append(card)
                    }

                    if event.action == .wonTrick {
                        self.turn = event.player
                    } else if let player = self.getNextPlayer(currentPlayer: event.player) {
                        self.turn = player
                    }

                    self.eventStream.value = event
                    self.evaluateSituation()
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

//        // Make calculations after the UI has had a chance to draw
//        self.eventStream.asObservable()
//            .delay(1, scheduler: MainScheduler.instance)
//            .subscribe(onNext: { [unowned self] packet in
//
//
//            }).disposed(by: self.disposeBag)
    }

    func hostGame() {
        self.playersStream.value = PlayerDetails(host: NetworkManager.me, positions: [NetworkManager.me])
        NetworkManager.shared.startSearching()
    }

    func findGame() {
        NetworkManager.shared.startSearching()
    }

    func startGame() {
        guard let players = self.playersStream.value?.positions else { return }

        // Let the other players know we are starting the game
        let dealer = players[Int(arc4random_uniform(UInt32(players.count)))]
        let state = GameStatePacket(state: .dealing, dealer: dealer, turn: dealer)

        NetworkManager.shared.send(packet: state)
    }

    func leaveGame() {
        NetworkManager.shared.disconnect()
    }

    /**
        Given the current situation, this method determines if any actions should be taken
    */
    func evaluateSituation() {
        // If everyone has played one card, then determine who wins this trick
        if
            self.cardsPlayed.count == self.players.count,
            let firstCard = self.cardsPlayed.first
        {
            let followSuit = firstCard.suit
            var highCard = firstCard
            for card in self.cardsPlayed {
                if card.compare(firstCard) == .orderedSame {
                    continue
                }

                if card.suit.rawValue == followSuit.rawValue {
                    if card.rank.rawValue > highCard.rank.rawValue {
                        highCard = card
                    }
                }
            }

            self.cardsPlayed.removeAll()
            if let player = highCard.owner {
                NetworkManager.shared.sendToMe(packet: ActionPacket(player: player, action: .wonTrick))
            }
        }
    }

    func dealCards() {
        NetworkManager.shared.send(packet: ActionPacket.dealCards(to: self.players))
    }

    func playCard(_ card: Card) {
        NetworkManager.shared.send(packet: ActionPacket.player(NetworkManager.me, played: card))
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
