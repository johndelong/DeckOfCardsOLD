//
//  ViewController.swift
//  DeckOfCards
//
//  Created by John DeLong on 2/25/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PlayersViewController: UIViewController, StoryboardBased {

    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var exitButton: UIButton!
    @IBOutlet private weak var startGameButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!

    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = self
        self.tableView.delegate = self

//        if GameManager.shared.state.value == .joining {
//            self.startGameButton.isHidden = true
//        }

//        let me = NetworkManager.shared.myPeerId

        NetworkManager.shared.connectedPeers.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { peers in
                self.tableView.reloadData()
            }).disposed(by: self.disposeBag)

        self.startGameButton.rx.tap.subscribe(onNext: {
            GameManager.shared.startGame()

            let gameController = GameViewController.instantiate()
            self.present(gameController, animated: true, completion: nil)
        }).disposed(by: self.disposeBag)

        self.exitButton.rx.tap.subscribe(onNext: {
            GameManager.shared.leaveGame()
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: self.disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        GameManager.shared.state.asObservable()
            .takeUntil(self.rx.deallocated)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] state in
                guard let _ = state else { return }

                let storyboard = GameViewController.instantiate()
                self.present(storyboard, animated: true, completion: nil)

            }).disposed(by: self.disposeBag)

    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.disposeBag = DisposeBag()
    }
}

extension PlayersViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return NetworkManager.shared.connectedPeers.value.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let peer = NetworkManager.shared.connectedPeers.value[indexPath.row]
        cell.textLabel?.text = "\(peer.displayName) - \(peer)"
        return cell
    }
}
