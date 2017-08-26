//
//  JoinViewController.swift
//  DeckOfCards
//
//  Created by John DeLong on 2/28/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import MultipeerConnectivity

class JoinViewController: UIViewController, StoryboardBased {

    @IBOutlet weak var tableView: UITableView!
    fileprivate lazy var disposeBag = DisposeBag()
    fileprivate var connectedPeers = [MCPeerID]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = 44

        NetworkManager.shared.connectedPeers.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] peers in
                self.connectedPeers = peers
                self.tableView.reloadData()
            }).disposed(by: self.disposeBag)
    }


    @IBAction func startPressed(_ sender: Any) {
        
    }

    @IBAction func exitPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension JoinViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.connectedPeers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = self.connectedPeers[indexPath.row].displayName
        return cell
    }
}

extension JoinViewController: UITableViewDelegate {

}
