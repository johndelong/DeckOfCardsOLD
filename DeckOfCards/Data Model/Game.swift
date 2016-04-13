//
//  Game.swift
//  DeckOfCards
//
//  Created by John DeLong on 4/12/16.
//  Copyright © 2016 delong. All rights reserved.
//


/*
 
 This class manages the entire game
 
*/



import Foundation
import MultipeerConnectivity

enum NetworkRole {
    case Host, Client
}

class Game: NSObject {

    static let sharedInstance = Game()

//    var networkRole: NetworkRole

//    override init() {
//
//    }

//    init(role: NetworkRole) {
//        self.networkRole = role
//    }
}