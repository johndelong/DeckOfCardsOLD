//
//  CardView.swift
//  DeckOfCards
//
//  Created by John DeLong on 3/19/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation
import UIKit

protocol CardViewDelegate: class {
    func didTapCard(_ cardView: CardView)
}

class CardView: UIImageView {
    static let size = CGSize(width: 80, height: 116)

    private(set) var isFaceUp = false
    var card: Card {
        didSet {
            if self.isFaceUp {
                self.image = self.card.faceUp
            }
        }
    }

    weak var delegate: CardViewDelegate?

    init(card: Card) {
        self.card = card

        super.init(image: Card.faceDown)

        self.frame = CGRect(x: 0, y: 0, width: CardView.size.width, height: CardView.size.height)

        self.isUserInteractionEnabled = true
        self.contentMode = .scaleAspectFit

        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapCard))
        self.addGestureRecognizer(gesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func didTapCard(_ sender: UITapGestureRecognizer) {
        guard let cardView = sender.view as? CardView else { return }
        self.delegate?.didTapCard(cardView)
    }

    func flipCard() {
        self.isFaceUp = !self.isFaceUp
        self.image = self.isFaceUp ? card.faceUp : Card.faceDown
    }
}
