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
    private lazy var disposeBag = DisposeBag()

    lazy var state = Variable<GameState?>(nil)

    private let maxPlayers = 4

    static let shared = GameManager()
    private init() {
         NetworkManager.shared.communication.asObservable()
            .subscribe(onNext: { packet in
                guard let packet = packet else { return }

                if let state = packet as? GameState {
                    GameManager.shared.state.value = state
                }

            }).disposed(by: self.disposeBag)

        NetworkManager.shared.connectedPeers.asObservable()
            .subscribe(onNext: { [unowned self] peers in
                if peers.count == self.maxPlayers {
                    NetworkManager.shared.stopSearching()
                }
            }
        ).disposed(by: self.disposeBag)
    }

    func findGame() {
        NetworkManager.shared.startSearching()
    }

    func startGame() {
        var players = NetworkManager.shared.connectedPeers.value
        players.append(NetworkManager.shared.myPeerId)
        let state = GameState(
            players: players,
            dealer: NetworkManager.shared.myPeerId
        )
        NetworkManager.shared.send(packet: state)
        GameManager.shared.state.value = state
    }

    func leaveGame() {
        NetworkManager.shared.disconnect()
    }
}
