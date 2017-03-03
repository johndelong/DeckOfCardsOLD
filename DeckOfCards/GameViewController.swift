//
//  GameViewController.swift
//  DeckOfCards
//
//  Created by John DeLong on 2/27/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation
import UIKit

class GameViewController: UIViewController, StoryboardBased {

    @IBOutlet weak var exitButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func exitPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
