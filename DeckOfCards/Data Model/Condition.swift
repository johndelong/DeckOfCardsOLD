//
//  Condition.swift
//  DeckOfCards
//
//  Created by John DeLong on 5/9/16.
//  Copyright © 2016 delong. All rights reserved.
//

import Foundation

class Condition {
    enum CollaborationType {
        case Team
        case Solo
    }

    enum StrategyType {
        case Offense
        case Defense
    }

    var numOfTricksWon: Int?
    var strategy: StrategyType?
    var collaboration: CollaborationType?
}