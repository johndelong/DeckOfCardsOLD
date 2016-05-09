//
//  GameScene.swift
//  DeckOfcards
//
//  Created by John DeLong on 4/3/16.
//  Copyright (c) 2016 delong. All rights reserved.
//

import SpriteKit
import MultipeerConnectivity

//https://www.raywenderlich.com/119815/sprite-kit-swift-2-tutorial-for-beginners

//https://www.raywenderlich.com/12735/how-to-make-a-simple-playing-card-game-with-multiplayer-and-bluetooth-part-1

// All visual logic goes in here
// This class should know nothing about the game (rules or how a game should be played)
// This class receives instructions on what should happen on the table

class GameScene: SKScene {
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */

//        let closeButton = UIButton()
//        closeButton.titleLabel = "Close"
//        closeButton

        setupHand()

    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
       /* Called when a touch begins */
        
        for touch in touches {
//            let location = touch.locationInNode(self)
//            
//            let sprite = SKSpriteNode(imageNamed:"Spaceship")
//            
//            sprite.xScale = 0.5
//            sprite.yScale = 0.5
//            sprite.position = location
//            
//            let action = SKAction.rotateByAngle(CGFloat(M_PI), duration:1)
//            
//            sprite.runAction(SKAction.repeatActionForever(action))
//            
//            self.addChild(sprite)
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }

    func setupHand() {
        let numOfCards = 13;
        for cardNum in 1...numOfCards {
            guard let rank = Card.Rank(rawValue: cardNum) else {
                continue
            }

            let pos = CGFloat(cardNum) * 30.0

            let card = UICard(card: Card(rank: rank, suit: .Spades))
            card.position = CGPoint(x:CGRectGetMidX(self.frame) + pos, y:CGRectGetMidY(self.frame))
            card.zPosition = pos
            addChild(card)
        }
    }
}