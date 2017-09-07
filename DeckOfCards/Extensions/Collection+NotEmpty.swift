//
//  Collection+NotEmpty.swift
//  DeckOfCards
//
//  Created by John DeLong on 9/6/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation

extension Collection {
    var isNotEmpty: Bool {
        return self.isEmpty == false
    }
}
