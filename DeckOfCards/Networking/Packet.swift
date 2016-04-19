//
//  Packet.swift
//  DeckOfCards
//
//  Created by John DeLong on 4/12/16.
//  Copyright © 2016 delong. All rights reserved.
//

// https://developer.apple.com/library/ios/referencelibrary/GettingStarted/DevelopiOSAppsSwift/Lesson10.html

import Foundation

enum PacketType: Int {
    case Unknown, NewGame, DealCards
}

class Packet: NSObject, NSSecureCoding {

    var type: PacketType
    var msg: String?

    struct PropertyKey {
        static let typeKey = "type"
        static let msgKey = "msg"
    }

    init(type: PacketType, msg: String?) {
        // Initialize stored properties.
        self.type = type
        self.msg = msg

        super.init()
    }

    // ===================================================================================
    // archive
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(self.type.rawValue, forKey: PropertyKey.typeKey)
        aCoder.encodeObject(self.msg, forKey: PropertyKey.msgKey)
    }

    // ===================================================================================
    // unarchive

    // The required keyword means this initializer must be implemented on every subclass of the class that defines 
    // this initializer.

    // Convenience initializers are secondary, supporting initializers that need to call one of their class’s
    // designated initializers. Designated initializers are the primary initializers for a class. They fully initialize 
    // all properties introduced by that class and call a superclass initializer to continue the initialization process 
    // up the superclass chain. Here, you’re declaring this initializer as a convenience initializer because it only 
    // applies when there’s saved data to be loaded.

    // The question mark (?) means that this is a failable initializer that might return nil.
    required convenience init?(coder aDecoder: NSCoder) {

        let type = PacketType.init(rawValue: aDecoder.decodeIntegerForKey(PropertyKey.typeKey))!
        let msg = aDecoder.decodeObjectForKey(PropertyKey.msgKey) as? String

        // Must call designated initializer.
        self.init(type: type, msg: msg)
    }

    class func supportsSecureCoding() -> Bool {
        return true
    }
}