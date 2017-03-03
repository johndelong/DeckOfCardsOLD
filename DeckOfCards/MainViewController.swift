//
//  MainViewController.swift
//  DeckOfCards
//
//  Created by John DeLong on 2/27/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class MainViewController: UIViewController {

    @IBOutlet private weak var joinButton: UIButton!
    @IBOutlet private weak var hostButton: UIButton!

    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.joinButton.rx.tap.subscribe(onNext: {
            GameManager.shared.joinGame()

            self.presentPlayersStoryboard()
        }).disposed(by: self.disposeBag)

        self.hostButton.rx.tap.subscribe(onNext: {
            GameManager.shared.hostGame()

            self.presentPlayersStoryboard()
        }).disposed(by: self.disposeBag)
    }

    func presentPlayersStoryboard() {
        let storyboard = PlayersViewController.instantiate()
        self.present(storyboard, animated: true, completion: nil)
    }
}
