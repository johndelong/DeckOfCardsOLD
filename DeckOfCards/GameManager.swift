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

    enum State {
        case unknown
        case joining
        case hosting
        case playing
    }
//    lazy var state = Variable<State>(.unknown)

    static let shared = GameManager()
    private init() {
         NetworkManager.shared.communication.asObservable()
            .subscribe(onNext: { packet in
                guard let packet = packet else { return }

                if let state = packet as? GameState {
                    GameManager.shared.state.value = state
                }

            }).disposed(by: self.disposeBag)
    }

    func hostGame() {
//        self.state.value = .hosting
        NetworkManager.shared.startSearching()
    }

    func joinGame() {
//        self.state.value = .joining
        NetworkManager.shared.startSearching()
    }

    func startGame() {
//        self.state.value = .playing
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
//        self.state.value = .unknown
        NetworkManager.shared.disconnect()
    }
}
