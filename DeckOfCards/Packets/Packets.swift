//
//  Packets.swift
//  DeckOfCards
//
//  Created by John DeLong on 3/1/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation
import UIKit
import MultipeerConnectivity

extension Data {
    func decode() -> PacketProtocol? {
        return NSKeyedUnarchiver.unarchiveObject(with: self) as? PacketProtocol
    }
}

protocol PacketProtocol: NSObjectProtocol, NSCoding {}

extension PacketProtocol {
    func encode() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
}
