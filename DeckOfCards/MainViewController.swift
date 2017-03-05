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

    @IBOutlet private weak var playEuchre: UIButton!

    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.playEuchre.rx.tap.subscribe(onNext: {
            GameManager.shared.findGame()
            self.goToTable()
        }).disposed(by: self.disposeBag)
    }

    func goToTable() {
        let storyboard = GameTableViewController.instantiate()
        self.present(storyboard, animated: true, completion: nil)
    }
}
