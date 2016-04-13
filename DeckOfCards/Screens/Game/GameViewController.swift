//
//  GameViewController.swift
//  DeckOfcards
//
//  Created by John DeLong on 4/3/16.
//  Copyright (c) 2016 delong. All rights reserved.
//

import UIKit
import SpriteKit
//import MultipeerConnectivity

//protocol GameViewControllerDelegate {
//    func joinViewController(controller: JoinViewController, startGameWithSession session: MCSession, playerName name:NSString, server peerID:NSString)
//}

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

//        let scene = GameScene(size: view.bounds.size)
        if let scene = GameScene(fileNamed:"GameScene") {
            // Configure the view.
            let skView = self.view as! SKView
            skView.showsFPS = true
            skView.showsNodeCount = true
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            
            skView.presentScene(scene)
        }
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

//    func joinViewController(controller: JoinViewController, startGameWithSession session: MCSession, playerName name:NSString, server peerID:MCPeerID) {
//        print("hello world");
//    }

}
