//
//  GameViewController.swift
//  DeckOfCards
//
//  Created by John DeLong on 2/27/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class GameTableViewController: UIViewController, StoryboardBased {

    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var playButton: UIButton!

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.playButton.isEnabled = false

        GameManager.shared.state.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] state in
                guard let state = state else { return }

                self.playButton.isEnabled = (state.dealer == NetworkManager.shared.myPeerId)
            }).disposed(by: self.disposeBag)

        self.playButton.rx.tap.subscribe(onNext: {
            if
                let state = GameManager.shared.state.value,
                var index = state.players.index(of: NetworkManager.shared.myPeerId)
            {

                index = (index + 1 >= state.players.count) ? 0 : index + 1

                state.dealer = state.players[index]
                GameManager.shared.state.value = state
                NetworkManager.shared.send(packet: state)
            }

        }).disposed(by: self.disposeBag)
    }

    @IBAction func exitPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
