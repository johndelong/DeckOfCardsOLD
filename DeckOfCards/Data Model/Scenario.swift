//
//  Scenario.swift
//  DeckOfCards
//
//  Created by John DeLong on 4/23/16.
//  Copyright © 2016 delong. All rights reserved.
//

import Foundation


// In a particular scenario, what are the rules?

class Scenario {

    // Key points in the game
    enum ScenarioType {
        case ConstantRules // rules that never change throughout the game
        case TheDeal
        case NormalPlay
        case GameOver
        case WhenOccurs
    }

    var type: ScenarioType
    var rules = Dictionary<Rule.RuleType, Rule>()

    init(type: ScenarioType) {
        self.type = type
    }

}

