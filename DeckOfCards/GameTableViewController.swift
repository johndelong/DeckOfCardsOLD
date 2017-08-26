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

        self.playButton.isEnabled = GameManager.shared.host.isMe
        self.playButton.setTitle("Start Game", for: .normal)

        GameManager.shared.eventStream.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] event in
                guard let _self = self else { return }

                if let action = event as? ActionPacket {
                    _self.handleActionEvent(action)
                } else if let players = event as? PlayerDetails {
                    _self.updatePlayerPhysicalPositions(players.positions)
                } else if let state = event as? GameStatePacket {
                    if state.state == .dealing {
                        print("\(state.dealer.displayName) is now dealing")
                        if GameManager.shared.turn.isMe {
                            _self.playButton.setTitle("Deal", for: .normal)
                            _self.playButton.isEnabled = true
                        }
                    }
                }

                if GameManager.shared.state == .decisions {
//                    print("\(GameManager.shared.turn?.displayName ?? "Nobodies") turn")
                    if GameManager.shared.turn.isMe {
                        let alert = UIAlertController(
                            title: "Choose Trump",
                            message: nil,
                            preferredStyle: .actionSheet
                        )

                        GameManager.shared.availableDecisions.forEach { item in
                            if let suit = item as? Card.Suit {
                                let action = UIAlertAction(title: suit.toString(), style: .default) { _ in
                                    NetworkManager.shared.send(
                                        packet: PlayerDecision(player: Player.me, decides: .trump(suit))
                                    )
                                }
                                alert.addAction(action)
                            } else if let string = item as? String {
                                let action = UIAlertAction(title: string, style: .default) { _ in
                                    NetworkManager.shared.send(
                                        packet: PlayerDecision(player: Player.me, decides: .trump(nil))
                                    )
                                }
                                alert.addAction(action)
                            }
                        }

                        _self.animationQueue.animate(withDuration: 0, animations: {
                            _self.present(alert, animated: true, completion: nil)
                        })
                    }
                }

            }
        ).disposed(by: self.disposeBag)

        self.playButton.rx.tap.subscribe(onNext: {
            if GameManager.shared.state == .readyToStartGame {
                GameManager.shared.startGame()
            } else if GameManager.shared.turn.isMe && GameManager.shared.state == .dealing {
                GameManager.shared.deal(as: Player.me)
            }
        }).disposed(by: self.disposeBag)
    }

    // Actions taken by OTHER players.
    func handleActionEvent(_ action: ActionPacket) {
        if GameManager.shared.turn.isMe {
            self.playButton.setTitle("Take Turn", for: .normal)
            self.playButton.isEnabled = true
        } else {
            self.playButton.setTitle("Waiting", for: .normal)
            self.playButton.isEnabled = false
        }

        if action.type == .dealt {
            // assign cards
            GameManager.shared.playersCards.forEach { (player, cards) in
                self.playerCards[player] = cards.map { CardView(card: $0) }
            }

            // deal cards
            let cards = self.playerCards
            let playersInPosition = self.playerPhysicalPositions
            self.animationQueue.animate(withDuration: 1, animations: {
                self.player(action.player, deal: cards, to: playersInPosition)
            })

            // Show top card of kitty
            self.animationQueue.animate(withDuration: 1, animations: {
                if let card = GameManager.shared.kitty.first {
                    let cardView = CardView(card: card)
                    cardView.flipCard()
                    self.view.addSubview(cardView)
                    cardView.center = self.view.center
                }
            })
        } else if let action = action as? PlayerDecision {
            if case let .trump(suit) = action.decision {
                if let suit = suit {
                    print("\(action.player.displayName) chose \(suit.toString())")
                    self.updateCardPositions()
                } else {
                    print("\(action.player.displayName) passed")
                }
            }
        } else if let action = action as? PlayCardPacket {
            if let cardView = self.playerCards[action.player.id]?[action.positionInHand] {

                print("\(action.player.displayName) played the \(action.card.displayName())")

                self.playerCards[action.player.id]?.remove(at: action.positionInHand)

                self.cardsPlayed.append(cardView)

                // Animate the card being played
                self.player(action.player, playedCard: cardView)
            }
        } else if action.type == .wonTrick {
            print("\(action.player.displayName) won the trick!")
            self.clearTable()
        }
    }

    @IBAction func exitPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

// Drawing UI components and animation
extension GameTableViewController {

    func clearTable() {
        let cards = self.cardsPlayed
        self.cardsPlayed.removeAll()

        self.animationQueue.animate(withDuration: 1, animations: {
            cards.forEach { $0.alpha = 0 }
        }, completion: {
            cards.forEach { $0.removeFromSuperview() }
            print("table was cleared")
            print("\n\n")
        })
    }

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
    func player(
        _ player: Player,
        deal cards: [PlayerID: [CardView]],
        to players: [PlayerID: CGPoint],
        animated: Bool = true
    ) {
        let maxHandWidth: CGFloat = 350

        for (playerID, playerPos) in players {
            let cardViews = cards[playerID] ?? []

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
                cardView.frame.origin = CGPoint(x: xPos, y: yPos)

                if !horizontal {
                    cardView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
                }

                self.view.addSubview(cardView)
                index += 1
            }
        }
    }

    /**
        Update card positions in hand
    */
    func updateCardPositions() {
        for (playerId, hand) in self.playerCards {
            guard let ordered = GameManager.shared.playersCards[playerId] else { continue }
            for index in 0...ordered.count - 1 where hand[index].card != ordered[index] {
                hand[index].card = ordered[index]
            }
            self.playerCards[playerId] = hand
        }
    }

    /**
        Animates a card from a player's hand to the center of the table
 
        - Parameters:
            - player: The person who played the card
            - cardView: The view representing the card that was played
    */
    func player(_ player: Player, playedCard cardView: CardView, animated: Bool = true) {
        guard let playerPos = self.playerPhysicalPositions[player.id] else { return }

        let centerOfScreen = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
        let distanceFromCenter: CGFloat = CardView.size.height / 2

        let distance = sqrt(pow(playerPos.x - centerOfScreen.x, 2) + pow(playerPos.y - centerOfScreen.y, 2))
        let radius = distanceFromCenter / distance

        // Get coordinates of point some distance from center
        let x = (radius * playerPos.x + (1 - radius) * centerOfScreen.x)
        let y = (radius * playerPos.y + (1 - radius) * centerOfScreen.y)

        let destination = CGPoint(x: x, y: y)

        self.animationQueue.animate(withDuration: 0.5, animations: {
            if !cardView.isFaceUp {
                cardView.flipCard()
            }

            // Add some flair (spin card and randomize angle)
            let degree = CGFloat(Double.pi) + CGFloat(Int(arc4random()) % 10) / 50 - 0.1
            cardView.transform = cardView.transform.rotated(by: degree)

            cardView.center = destination
        })
    }
}

extension GameTableViewController {
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if size.width > size.height {
            // Position elements for Landscape
        } else {
            // Position elements for Portrait
        }
    }
}

extension GameTableViewController: CardViewDelegate {
    func didTapCard(_ cardView: CardView) {
        let cardsInPlay = GameManager.shared.cardsInPlay
        let hand = GameManager.shared.cards(for: Player.me.id)

        guard
            GameManager.shared.turn.isMe,
            let card = cardView.card as? PlayerCard,
            card.owner == Player.me,
            CardService.shared.canPlay(card: card, from: hand, whenCardsPlayed: cardsInPlay),
            let position = self.playerCards[Player.me.id]?.index(of: cardView)
        else { return }

        GameManager.shared.player(played: card, fromPosition: position)
    }
}
