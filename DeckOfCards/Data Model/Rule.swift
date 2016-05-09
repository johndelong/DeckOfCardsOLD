//
//  Rule.swift
//  DeckOfCards
//
//  Created by John DeLong on 4/23/16.
//  Copyright © 2016 delong. All rights reserved.
//

import Foundation

class Rule: NSObject {

    enum RuleType {
        case HandOrientation
        case NumberOfCardsInHand
    }

    var type: RuleType

    init(type: RuleType) {
        self.type = type
    }
}
