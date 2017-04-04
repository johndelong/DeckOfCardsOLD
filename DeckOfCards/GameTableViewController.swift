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

    fileprivate var playerPhysicalPositions = [PlayerID: CGPoint]()
    fileprivate var playerLabels = [UIView]()
    fileprivate var playerCards = [PlayerID: [CardView]]()
    fileprivate var cardsPlayed = [CardView]()
    fileprivate var animationQueue = AnimationQueue()

    let disposeBag = DisposeBag()

    var playerPositions = [Int: String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let game = GameManager.shared

        self.playButton.isEnabled = game.host.isMe
        self.playButton.titleLabel?.text = "Start Game"

        GameManager.shared.stateStream.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] state in
                if state.state == .dealing {
                    if game.dealer.isMe {
                        self.playButton.titleLabel?.text = "Deal"
                        self.playButton.isEnabled = true
                    }
                }
            }
        ).disposed(by: self.disposeBag)

        GameManager.shared.playersStream.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] players in
                self.updatePlayerPhysicalPositions(players.positions)
            }
        ).disposed(by: self.disposeBag)

        GameManager.shared.actionStream.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] action in

                if game.turn.isMe {
                    self.playButton.titleLabel?.text = "Take Turn"
                    self.playButton.isEnabled = true
                } else {
                    self.playButton.titleLabel?.text = "Waiting..."
                    self.playButton.isEnabled = false
                }

                if action.type == .dealt {
                    // Reset variables
                    self.clearTable()

                    // assign cards
                    game.playersCards.forEach { (player, cards) in
                        self.playerCards[player] = self.orderCards(cards).map { CardView(card: $0) }
                    }

                    // deal cards
                    self.animationQueue.animate(withDuration: 1, animations: {
                        self.dealCards()
                    })
                } else if let action = action as? PlayCardPacket {
                    // Animate the card being played
                    if let cardView = self.playerCards[action.player.id]?[action.positionInHand] {
                        self.playerCards[action.player.id]?.remove(at: action.positionInHand)

                        print("\(action.player.displayName) played the \(action.card.displayName())")
                        self.cardsPlayed.append(cardView)
                        self.playCard(player: action.player, cardView: cardView)
                    }
                } else if action.type == .wonTrick {
                    print("\(action.player.displayName) won the trick!")
                    let cards = self.cardsPlayed
                    self.cardsPlayed.removeAll()

                    self.animationQueue.animate(withDuration: 1, animations: {
                        cards.forEach { $0.alpha = 0 }
                    }, completion: {
                        cards.forEach { $0.removeFromSuperview() }
                    })
                }
            }
        ).disposed(by: self.disposeBag)

        self.playButton.rx.tap.subscribe(onNext: {
            if game.state == .readyToStartGame {
                GameManager.shared.startGame()
            } else if GameManager.shared.shouldDeal && game.state == .dealing {
                game.deal(as: Player.me)
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
}

// Drawing UI components and animation
extension GameTableViewController {
    func updatePlayerPhysicalPositions(_ positions: [Player]) {

        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let padding: CGFloat = 16

        // start with me and then go clockwise around positions
        guard let startIndex = positions.index(of: Player.me) else { return }

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

            self.playerPhysicalPositions[player.id] = point

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

    /**
        Deal cards to every player at the table
    */
    func dealCards() {
        let maxHandWidth: CGFloat = 350

        for (playerID, playerPos) in self.playerPhysicalPositions {
            let cardViews = self.playerCards[playerID] ?? []

            let increment = (maxHandWidth - CardView.size.width) / CGFloat(cardViews.count)

            // Determine the orientation of how to deal the cards
            let horizontal = abs(playerPos.x - self.view.center.x) < abs(playerPos.y - self.view.center.y)

            let startXPos = horizontal ? (self.view.frame.width / 2) - CGFloat(maxHandWidth / 2) : playerPos.x
            let startYPos = horizontal ? playerPos.y : (self.view.frame.height / 2) - CGFloat(maxHandWidth / 2)

            var index = 1

            for cardView in cardViews {
                cardView.delegate = self

                if playerID == Player.me.id {
                    cardView.flipCard()
                }

                let offset = (CGFloat(index) * increment)
                let xPos = (horizontal ? startXPos + offset : playerPos.x) - (CardView.size.width / 2)
                let yPos = (horizontal ? playerPos.y : startYPos + offset) - (CardView.size.height / 2)
                cardView.frame = CGRect(origin: CGPoint(x: xPos, y: yPos), size: CardView.size)

                if !horizontal {
                    cardView.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
                }

                self.view.addSubview(cardView)
                index += 1
            }
        }

        print("Finished animating cards being delt")
    }

    func clearTable() {
        self.playerCards.values.forEach { $0.forEach { $0.removeFromSuperview() } }
        self.playerCards.removeAll()
    }

    /**
        Animates a card from a player's hand to the center of the table
 
        - Parameters:
            - player: The person who played the card
            - cardView: The view representing the card that was played
    */
    func playCard(player: Player, cardView: CardView) {
        guard let point2 = self.playerPhysicalPositions[player.id] else { return }

        var frame = cardView.frame

        let point1 = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
        let padding: CGFloat = 100

        let distance = sqrt(pow(point2.x - point1.x, 2) + pow(point2.y - point1.y, 2))
        let radius = padding / distance

        let x = (radius * point2.x + (1 - radius) * point1.x) - (CardView.size.width / 2)
        let y = (radius * point2.y + (1 - radius) * point1.y) - (CardView.size.height / 2)

        let destination = CGPoint(x: x, y: y)

        self.animationQueue.animate(withDuration: 0.5, animations: {
            if !cardView.isFaceUp {
                cardView.flipCard()
            }

            frame.origin = destination
            cardView.frame = frame
        })
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

extension GameTableViewController: CardViewDelegate {
    func didTapCard(_ cardView: CardView) {
        guard
            GameManager.shared.turn.isMe,
            let card = cardView.card,
            card.owner == Player.me,
            let position = self.playerCards[Player.me.id]?.index(of: cardView)
        else { return }

        GameManager.shared.player(Player.me, playedCard: card, fromPosition: position)
    }
}
