//
//  HandOrientationRule.swift
//  DeckOfCards
//
//  Created by John DeLong on 4/23/16.
//  Copyright © 2016 delong. All rights reserved.
//

import Foundation

class HandOrientationRule: Rule {

    enum HandOrientationType: Int {
        case FaceUp
        case FaceDown
    }

    var value:HandOrientationType

    init(value: HandOrientationType) {
        self.value = value

        super.init(type: .HandOrientation)
    }
}
