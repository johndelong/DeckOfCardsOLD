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
    var state: GameState?

    enum State {
        case unknown
        case joining
        case hosting
        case playing
    }
//    lazy var state = Variable<State>(.unknown)

    static let shared = GameManager()
    private init() {
//        self.state.asObservable().subscribe(onNext: { state in
//
//
//        }).disposed(by: self.disposeBag)
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
        NetworkManager.shared.send(packet: GameState(
            players: NetworkManager.shared.connectedPeers.value,
            dealer: NetworkManager.shared.myPeerId
        ))
    }

    func leaveGame() {
//        self.state.value = .unknown
        NetworkManager.shared.disconnect()
    }
}
