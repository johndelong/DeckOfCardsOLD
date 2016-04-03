//
//  Card.swift
//  DeckOfcards
//
//  Created by John DeLong on 4/3/16.
//  Copyright © 2016 delong. All rights reserved.
//

import Foundation
import SpriteKit

struct Card {
    enum Suit:String {
        case Hearts, Diamonds, Clubs, Spades
    }
    enum Rank:Int {
        case Ace, Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten
        case Jack, Queen, King
    }

    let rank:Rank
    let suit:Suit

    func toAssetName() -> String {
        return (Suit.RawValue() as String)
    }
}

class UICard : SKSpriteNode {

    let frontTexture :SKTexture
    let backTexture :SKTexture
    var largeTexture :SKTexture?
    let largeTextureFilename :String
    var faceUp = true
    var enlarged = false
    var savedPosition = CGPointZero

    init(card: Card) {

        // initialize properties
        backTexture = SKTexture(imageNamed: "back")
        frontTexture = SKTexture(imageNamed: "c01")
        largeTextureFilename = "c01"

        // call designated initializer on super
        let size = CGSize(width: frontTexture.size().width / 8, height: frontTexture.size().height / 8)
        super.init(texture: frontTexture, color: UIColor.redColor(), size: size)

        // set properties defined in super
        userInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            if touch.tapCount > 1 {
                self.flip()
            }

            if enlarged { return }

            // note: removed references to touchedNode
            // 'self' in most cases is not required in Swift
            zPosition = 15
            let liftUp = SKAction.scaleTo(1.2, duration: 0.2)
            runAction(liftUp)

            let wiggleIn = SKAction.scaleXTo(1.0, duration: 0.2)
            let wiggleOut = SKAction.scaleXTo(1.2, duration: 0.2)
            let wiggle = SKAction.sequence([wiggleIn, wiggleOut])
            let wiggleRepeat = SKAction.repeatActionForever(wiggle)

            // again, since this is the touched sprite
            // run the action on self (implied)
            runAction(wiggleRepeat, withKey: "wiggle")
        }
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if enlarged { return }

        for touch in touches {
            let location = touch.locationInNode(scene!)  // make sure this is scene, not self
            position = location
        }
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if enlarged { return }

        for _ in touches {
            zPosition = 0

            let dropDown = SKAction.scaleTo(1.0, duration: 0.2)
            runAction(dropDown)

            removeActionForKey("wiggle")
        }
    }

    func flip() {
        let firstHalfFlip = SKAction.scaleXTo(0.0, duration: 0.4)
        let secondHalfFlip = SKAction.scaleXTo(1.0, duration: 0.4)

        setScale(1.0)

        if faceUp {
            runAction(firstHalfFlip) {
                self.texture = self.backTexture
                self.faceUp = false
                self.runAction(secondHalfFlip)
            }
        } else {
            runAction(firstHalfFlip) {
                self.texture = self.frontTexture
                self.faceUp = true
                self.runAction(secondHalfFlip)
            }
        }
    }

    func enlarge() {
        if enlarged {
            let slide = SKAction.moveTo(savedPosition, duration:0.3)
            let scaleDown = SKAction.scaleTo(1.0, duration:0.3)
            runAction(SKAction.group([slide, scaleDown])) {
                self.enlarged = false
                self.zPosition = 0
            }
        } else {
            enlarged = true
            savedPosition = position

            if (largeTexture != nil) {
                texture = largeTexture
            } else {
                largeTexture = SKTexture(imageNamed: largeTextureFilename)
                texture = largeTexture
            }

            zPosition = 20

            let newPosition = CGPointMake(CGRectGetMidX(parent!.frame), CGRectGetMidY(parent!.frame))
            removeAllActions()

            let slide = SKAction.moveTo(newPosition, duration:0.3)
            let scaleUp = SKAction.scaleTo(5.0, duration:0.3)
            runAction(SKAction.group([slide, scaleUp]))
        }
    }
}
