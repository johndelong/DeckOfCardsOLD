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
    var turn: MCPeerID? = nil
    var dealer: MCPeerID? = nil

    // Streams
    private lazy var disposeBag = DisposeBag()
    lazy var state = Variable<GameState?>(nil)
    
    // TODO: Make this not optional. Players have to exist if game is to be played. Maybe wrap in GamePacket object.
    lazy var playersStream = Variable<PlayerDetails?>(nil)

    static private(set) var players: PlayerDetails? {
        get {
            return GameManager.shared.playersStream.value
        }
        set {
            GameManager.shared.playersStream.value = newValue
        }
    }

    lazy var eventStream = Variable<ActionPacket?>(nil)


    static let shared = GameManager()
    private init() {
         NetworkManager.shared.communication.asObservable()
            .subscribe(onNext: { [unowned self] packet in
                guard let packet = packet else { return }

                if let state = packet as? GameState {
                    self.state.value = state
                }

                if let event = packet as? ActionPacket {
                    if event.action == .deal {
                        self.dealer = event.player
                        self.turn = self.determineNextTurn(currentPlayer: self.dealer!)
                    }

                    if event.action == .playCard {
                        self.turn = self.determineNextTurn(currentPlayer: self.turn!)
                    }

                    self.eventStream.value = event
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
        guard let players = GameManager.players?.positions else { return }

        // Let the other players know we are starting the game
        let state = GameState(state: .start)
        NetworkManager.shared.send(packet: state)
        self.state.value = state

        // Tell the other players who the dealer is
        let dealer = players[Int(arc4random_uniform(UInt32(players.count)))]
        self.dealer = dealer
        self.turn = self.determineNextTurn(currentPlayer: self.dealer!)
        let event = ActionPacket(player: dealer, action: .deal)
        NetworkManager.shared.send(packet: event)
        self.eventStream.value = event
    }

    func leaveGame() {
        NetworkManager.shared.disconnect()
    }
}

extension GameManager {
    func determineNextTurn(currentPlayer: MCPeerID) -> MCPeerID? {
        guard let playersList = GameManager.players?.positions else { return nil }

        var player: MCPeerID? = nil
        let players = Array(playersList)
        for i in 0...players.count - 1 {
            if currentPlayer == players[i] {
                if i == players.count - 1 {
                    player = players[0]
                } else {
                    player = players[i + 1]
                }
            }
        }

        return player
    }

    func playCard() {
        let event = ActionPacket(player: NetworkManager.me, action: .playCard)
        NetworkManager.shared.send(packet: event)
        self.eventStream.value = event
    }
}
