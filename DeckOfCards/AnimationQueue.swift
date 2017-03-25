//
//  AnimationQueue.swift
//  DeckOfCards
//
//  Created by John DeLong on 3/25/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation
import UIKit

class AnimationQueue {

    private struct Animation {
        let duration: TimeInterval
        let animate: (() -> Swift.Void)
        let completion: (() -> Swift.Void)?
    }

    private var animations = [Animation]()
    private var isAnimating = false

    func animate(
        withDuration duration: TimeInterval,
        animations: @escaping () -> Swift.Void,
        completion: (() -> Swift.Void)? = nil
    ) {
        let animation = Animation(duration: duration, animate: animations, completion: completion)
        self.animations.append(animation)
        if !self.isAnimating {
            self.startAnimating()
        }
    }

    private func startAnimating() {
        guard !self.animations.isEmpty else {
            self.isAnimating = false
            return
        }

        self.isAnimating = true

        let animation = self.animations[0]
        UIView.animate(withDuration: animation.duration, animations: {
            animation.animate()
        }, completion: { _ in
            if let completion = animation.completion {
                completion()
            }

            self.animations.remove(at: 0)
            self.startAnimating()
        })
    }
}
