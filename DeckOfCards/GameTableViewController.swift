//
//  GameViewController.swift
//  DeckOfCards
//
//  Created by John DeLong on 2/27/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import UIKit
import RxSwift
import RxCocoa

class GameTableViewController: UIViewController, StoryboardBased {

    @IBOutlet private weak var myNameLabel: UILabel!
    @IBOutlet private weak var exitButton: UIButton!
    @IBOutlet private weak var playButton: UIButton!

    fileprivate var playerLabels = [UIView]()

    let disposeBag = DisposeBag()

    var playerPositions = [Int: String]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.myNameLabel.text = NetworkManager.me.displayName
        self.playButton.isEnabled = GameManager.isHost

        GameManager.shared.stateStream.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] state in
                guard let state = state else { return }

                if state.state == .dealing {
                    if state.dealer.isMe {
                        self.playButton.isEnabled = true
                    }
                }
            }
        ).disposed(by: self.disposeBag)

        GameManager.shared.playersStream.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] players in
                guard let players = players else { return }
                self.updatePlayerLabels(players.positions)
            }
        ).disposed(by: self.disposeBag)

        GameManager.shared.eventStream.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] event in
                guard let event = event else { return }

                if GameManager.isMyTurn {
                    self.playButton.isEnabled = true
                }
            }
        )

        self.playButton.rx.tap.subscribe(onNext: {
            self.playButton.isEnabled = false

            let game = GameManager.shared

            if GameManager.shared.stateStream.value == nil {
                GameManager.shared.startGame()
            } else if GameManager.isDealer && game.state == .dealing {
                game.dealCards()
            } else {
                game.playCard()
            }
        }).disposed(by: self.disposeBag)
    }

    @IBAction func exitPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    func updatePlayerLabels(_ positions: [MCPeerID]) {

        // Clear previous player labels
        for view in self.playerLabels {
            view.removeFromSuperview()
        }

        // Draw new player labels
        let margins = self.view.layoutMarginsGuide
        var index = 0
        for player in positions {
            if player == NetworkManager.me {
                continue
            }

            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = player.displayName
            self.view.addSubview(label)

            switch index {
            case 0: // Left side
                label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: 8.0).isActive = true
                label.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 8.0).isActive = true
            case 1: // Top
                label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 8.0).isActive = true
                label.topAnchor.constraint(equalTo: margins.topAnchor, constant: 8.0).isActive = true
            case 2: // Right side
                label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: 8.0).isActive = true
                label.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: 8.0).isActive = true
            default:
                continue
            }

            self.playerLabels.append(label)

            index += 1
        }
    }
}

extension MCPeerID {
    var isMe: Bool {
        return self == NetworkManager.me
    }
}
