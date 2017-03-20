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

    @IBOutlet private weak var exitButton: UIButton!
    @IBOutlet private weak var playButton: UIButton!

    fileprivate var playerPhysicalPositions = [MCPeerID: CGPoint]()
    fileprivate var playerLabels = [UIView]()
    fileprivate var cardImages = [UIImageView]()

    let disposeBag = DisposeBag()

    var playerPositions = [Int: String]()

    override func viewDidLoad() {
        super.viewDidLoad()

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
                self.updatePlayerPhysicalPositions(players.positions)
            }
        ).disposed(by: self.disposeBag)

        GameManager.shared.eventStream.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] event in
                guard let event = event else { return }

                if GameManager.isMyTurn {
                    self.playButton.isEnabled = true
                }

                if
                    event.action == .dealt,
                    let data = event.value,
                    let cards = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: [Card]],
                    let myCards = cards[NetworkManager.me.displayName]
                {
                    self.updatePlayerCards(cards: myCards)
                }

                if
                    event.action == .playedCard,
                    let data = event.value,
                    let card = NSKeyedUnarchiver.unarchiveObject(with: data) as? Card
                {

                }
            }
        ).disposed(by: self.disposeBag)

        self.playButton.rx.tap.subscribe(onNext: {
            self.playButton.isEnabled = false

            let game = GameManager.shared

            if GameManager.shared.stateStream.value == nil {
                GameManager.shared.startGame()
            } else if GameManager.isDealer && game.state == .dealing {
                game.dealCards()
            }
        }).disposed(by: self.disposeBag)
    }

    @IBAction func exitPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    func orderCards(_ cards: [Card]) -> [Card] {
        return cards.sorted { (lhs, rhs) -> Bool in
            return lhs.suit.rawValue > rhs.suit.rawValue ||
                (lhs.suit.rawValue == rhs.suit.rawValue && lhs.rank.rawValue > rhs.rank.rawValue)
        }
    }

    func playMyCard(sender: UITapGestureRecognizer) {
        guard let cardView = sender.view as? CardView else { return }
        GameManager.shared.playCard(cardView.card)
    }

    func playCard(player: MCPeerID, cardView: CardView) {
        guard let point2 = self.playerPhysicalPositions[player] else { return }

        var frame = cardView.frame

        let point1 = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
        let padding: CGFloat = 1

        let distance = sqrt(pow(point2.x - point1.x, 2) + pow(point2.y - point1.y, 2))
        let radius = padding / distance

        let x = radius * point2.x + (1 - radius) * point1.x
        let y = radius * point2.y + (1 - radius) * point1.y

        let destination = CGPoint(x: x, y: y)

        UIView.animate(withDuration: 5) {
            frame.origin = destination
            cardView.frame = frame
        }

        GameManager.shared.playCard(cardView.card)
    }

    func updatePlayerPhysicalPositions(_ positions: [MCPeerID]) {

        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let padding: CGFloat = 16

        // start with me and then go clockwise around positions
        guard let startIndex = positions.index(of: NetworkManager.me) else { return }

        for index in 0...positions.count - 1 {
            var playerIndex = startIndex + index
            if playerIndex > positions.count - 1 {
                playerIndex -= positions.count
            }
            let player = positions[playerIndex]

            var point: CGPoint

            switch index {
            case 0:
                point = CGPoint(x: screenWidth / 2, y: screenHeight - padding)
            case 1:
                point = CGPoint(x: padding, y: screenHeight / 2)
            case 2:
                point = CGPoint(x: screenWidth / 2, y: padding)
            case 3:
                point = CGPoint(x: screenWidth - padding, y: screenHeight / 2)
            default:
                continue
            }

            self.playerPhysicalPositions[player] = point

        }

        // update labels
        self.updatePlayerLabels()

        // update cards
    }

    func updatePlayerLabels() {
        // Clear previous player labels
        self.playerLabels.forEach { $0.removeFromSuperview() }
        self.playerLabels.removeAll()

        for (player, position) in self.playerPhysicalPositions {
            let label = UILabel()
            label.text = player.displayName
            label.sizeToFit()

            var frame = label.frame
            frame.origin = position
            label.frame = frame

            self.view.addSubview(label)
            self.playerLabels.append(label)
        }
    }

    func updatePlayerCards(cards: [Card]) {
        for card in self.cardImages {
            card.removeFromSuperview()
        }
        self.cardImages.removeAll()

        let maxHandWidth: CGFloat = 350
        let cardWidth: CGFloat = 80
        let cardHeight: CGFloat = 116
        //        let padding: CGFloat = 32
        let yPos = self.view.frame.maxY - (cardHeight / 2)
        let positions = cards.count
        let offset = (maxHandWidth - cardWidth) / CGFloat(positions)

        var currentPos = 0
        let startXPos = (self.view.frame.width / 2) - CGFloat(maxHandWidth / 2)
        for card in orderCards(cards) {
            let imageView = card.view
            let gesture = UITapGestureRecognizer(target: self, action: #selector(playMyCard(sender:)))
            imageView.addGestureRecognizer(gesture)
            imageView.isUserInteractionEnabled = true

            imageView.contentMode = .scaleAspectFit
            let xPos = startXPos + CGFloat(currentPos) * offset
            let frame = CGRect(x: xPos, y: yPos, width: cardWidth, height: cardHeight)
            imageView.frame = frame

            self.cardImages.append(imageView)
            self.view.addSubview(imageView)
            currentPos += 1
        }
    }
}

extension GameTableViewController {
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if (size.width > size.height)
        {
            // Position elements for Landscape
        } else {
            // Position elements for Portrait
        }
    }
}

extension MCPeerID {
    var isMe: Bool {
        return self == NetworkManager.me
    }
}
