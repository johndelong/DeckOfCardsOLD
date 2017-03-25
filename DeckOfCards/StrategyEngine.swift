//
//  File.swift
//  DeckOfCards
//
//  Created by John DeLong on 3/25/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation

class StrategyEngine {
    
    var teams = [[Player]]()

    /**
        - TODO:
            - Lay high if can win
            - Trump if cannot follow suit
            - Use teams to determine when to "lay low" if a partner already has the trick
     */
    static func determineCardToPlay(from hand: [Card]) -> Card? {
        guard !hand.isEmpty else { return nil }

        return hand.first
    }
}
