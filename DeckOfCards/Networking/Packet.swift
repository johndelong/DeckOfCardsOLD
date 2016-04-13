//
//  Packet.swift
//  DeckOfCards
//
//  Created by John DeLong on 4/12/16.
//  Copyright © 2016 delong. All rights reserved.
//

import Foundation

enum PacketType: Int {
    case Unknown, DealCards
}

class Packet {

    var number:Int = -1
    var type:PacketType = .Unknown
    var payload:NSData?

    required convenience init?(coder decoder: NSCoder) {
        self.init()

        if decoder.decodeObjectForKey("packet_header") as? String != "DeckOfCards" {
            return
        }

        if let number = decoder.decodeObjectForKey("packet_number") as? Int {
            self.number = number
        }

        if let typeValue = decoder.decodeObjectForKey("packet_type") as? Int,
            let type = PacketType.init(rawValue: typeValue) {
            self.type = type
        }

        self.payload = decoder.decodeObjectForKey("packet_payload") as? NSData
    }

    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject("DeckOfCards", forKey: "packet_header")
        coder.encodeObject(self.number, forKey: "packet_number")
        coder.encodeObject(self.type.rawValue, forKey: "packet_type")
        coder.encodeObject(self.payload, forKey: "packet_payload")
    }

    func toData() -> NSData {
        return NSKeyedArchiver.archivedDataWithRootObject(self)
    }

    static func fromData(data: NSData) -> Packet? {
        return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Packet
    }
}