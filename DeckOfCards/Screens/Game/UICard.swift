//
//  UICard.swift
//  DeckOfCards
//
//  Created by John DeLong on 5/9/16.
//  Copyright © 2016 delong. All rights reserved.
//

import Foundation
import SpriteKit


class UICard : SKSpriteNode {

    let frontTexture :SKTexture
    let backTexture :SKTexture
    var faceUp = true
    var selected = false

    init(card: Card) {

        // initialize properties
        backTexture = SKTexture(imageNamed: "back")
        frontTexture = SKTexture(imageNamed: card.assetName())

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

            let movePos:CGFloat = self.selected ? -50.0 : 50.0
            let liftUp = SKAction.moveToY(self.position.y + movePos, duration: 0.2)
            runAction(liftUp)

            self.selected = !self.selected
        }
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        //        if enlarged { return }

        //        guard let scene = scene else {
        //            return
        //        }
        //
        //        for touch in touches {
        //            let location = touch.locationInNode(scene)  // make sure this is scene, not self
        //            position = location
        //        }
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        //        if enlarged { return }

        //        for _ in touches {
        ////            zPosition = 0
        //
        //
        //        }
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

    //
    //    let wiggleIn = SKAction.scaleXTo(1.0, duration: 0.2)
    //    let wiggleOut = SKAction.scaleXTo(1.2, duration: 0.2)
    //    let wiggle = SKAction.sequence([wiggleIn, wiggleOut])
    //    let wiggleRepeat = SKAction.repeatActionForever(wiggle)
    //
    //    // again, since this is the touched sprite
    //    // run the action on self (implied)
    //    runAction(wiggleRepeat, withKey: "wiggle")



    //    let dropDown = SKAction.scaleTo(1.0, duration: 0.2)
    //    runAction(dropDown)
    //
    //    removeActionForKey("wiggle")


    //    func enlarge() {
    //        if enlarged {
    //            let slide = SKAction.moveTo(savedPosition, duration:0.3)
    //            let scaleDown = SKAction.scaleTo(1.0, duration:0.3)
    //            runAction(SKAction.group([slide, scaleDown])) {
    //                self.enlarged = false
    //                self.zPosition = 0
    //            }
    //        } else {
    //            enlarged = true
    //            savedPosition = position
    //
    //            zPosition = 20
    //
    //            let newPosition = CGPointMake(CGRectGetMidX(parent!.frame), CGRectGetMidY(parent!.frame))
    //            removeAllActions()
    //
    //            let slide = SKAction.moveTo(newPosition, duration:0.3)
    //            let scaleUp = SKAction.scaleTo(5.0, duration:0.3)
    //            runAction(SKAction.group([slide, scaleUp]))
    //        }
    //    }
}