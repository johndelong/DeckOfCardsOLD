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

         NetworkManager.shared.communication.asObservable()
            .subscribe(onNext: { [unowned self] packet in
                guard let packet = packet else { return }

                if let state = packet as? GameStatePacket {
                    self.update(from: state)
                }

                if let event = packet as? ActionPacket {
                    self.update(from: event)
                }

                if let players = packet as? PlayerDetails {
                    self.playersStream.value = players
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

                    let players = PlayerDetails(host: NetworkManager.me, positions: positions)
                    self.playersStream.value = players
                    NetworkManager.shared.send(packet: players)
                }
            }
        ).disposed(by: self.disposeBag)
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

        self.update(from: state)
        NetworkManager.shared.send(packet: state)
    }

    func update(from state: GameStatePacket) {
        self.state = state.state
        self.turn = state.turn
        self.dealer = state.dealer
        self.stateStream.value = state
    }

    func leaveGame() {
        NetworkManager.shared.disconnect()
    }

    func dealCards() {
        guard let players = self.playersStream.value?.positions else { return }
        let event = ActionPacket.dealCards(to: players)
        self.update(from: event)
        NetworkManager.shared.send(packet: event)
    }

    func playCard() {
        let event = ActionPacket(player: NetworkManager.me, action: .playedCard)

        self.update(from: event)
        NetworkManager.shared.send(packet: event)
    }

    func update(from event: ActionPacket) {
        if event.action == .dealt {
            self.state = .playing
            if let data = event.value {
                let cards = NSKeyedUnarchiver.unarchiveObject(with: data)
                print(cards ?? nil)
            }
        }

        if event.action == .playedCard {
            print("\(event.player.displayName) played a card")
        }

        if let player = self.getNextPlayer(currentPlayer: event.player) {
            self.turn = player
        }

        self.eventStream.value = event
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
