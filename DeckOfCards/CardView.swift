//
//  CardView.swift
//  DeckOfCards
//
//  Created by John DeLong on 3/19/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation
import UIKit

class CardView: UIImageView {
    var card: Card

    init(card: Card) {
        self.card = card
        super.init(image: card.image)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
