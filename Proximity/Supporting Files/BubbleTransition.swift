//
//  BubbleTransition.swift
//  desappstre framework
//
//  Created by Adolfo Vera Blasco on 14/03/16.
//  Copyright (c) 2016 Adolfo Vera Blasco. All rights reserved.
//

import UIKit
import Foundation

@objc public class BubbleTransition: NSObject 
{
    /// Point in which we situate the bubble.
    /// By default Upper Left corner
    public var startingPoint: CGPoint
    
    /// The transition direction.
    public var transitionMode: TransitionMode
    
    /// The color of the bubble.
    /// Non defined? We use the presented controller background color
    public var bubbleColor: UIColor?
    
    /// The bubble
    private var bubble: UIView!
    /// Transition duration
    private var presentingDuration: Double
    /// Dismiss duration
    private var dismissDuration: Double

    /**
        Initializer
    */
    public override init()
    {
        self.presentingDuration = 0.5
        self.dismissDuration = 0.35
        
        self.startingPoint = CGPoint(x:0.0, y:0.0)
        self.transitionMode = TransitionMode.Present
    }

    //
    // MARK: - Private Methods
    //

    /**
        Calculate the circle needed to cover the screen completly
     
        - Parameters:
            - originalSize: Size that must be covered
            - start: Where the bubble starts to growth
    */
    private func frameForBubbleWithSize(originalSize: CGSize, start: CGPoint) -> CGRect
    {
        let lengthX = fmax(start.x, originalSize.width - start.x);
        let lengthY = fmax(start.y, originalSize.height - start.y)

        let offset = sqrt(lengthX * lengthX + lengthY * lengthY) * 2;

        return CGRect(x:0, y:0, width:offset, height:offset)
    }
}

//
// MARK: - UIViewControllerAnimatedTransitioning Protocol
//

extension BubbleTransition: UIViewControllerAnimatedTransitioning 
{
    /**
        Transition duration
    */
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return self.transitionMode == .Present ? self.presentingDuration : self.dismissDuration
    }

    /**
        Where the magic happends :)
    */
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        let containerView = transitionContext.containerView
        guard let toView = transitionContext.view(forKey: .to),
            let fromView = transitionContext.view(forKey: .from)
        else 
        {
            return
        }

        if transitionMode == TransitionMode.Present 
        {
            let originalCenter = toView.center
            let originalSize = toView.frame.size

            let frame: CGRect = self.frameForBubbleWithSize(originalSize: originalSize, start: self.startingPoint)

            self.bubble = UIView(frame: frame)
            self.bubble.layer.cornerRadius = self.bubble.frame.height / 2
            self.bubble.center = self.startingPoint
            self.bubble.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)

            if let bubbleColor = self.bubbleColor
            {
                self.bubble.backgroundColor = bubbleColor
            }
            else 
            {
                self.bubble.backgroundColor = toView.backgroundColor
            }
            
            toView.center = startingPoint
            toView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            toView.alpha = 0
            
            containerView.addSubview(toView)
            containerView.addSubview(self.bubble)

            UIView.animate(withDuration: self.presentingDuration,
                animations: 
                {
                    self.bubble.transform = .identity
                    
                    toView.transform = .identity
                    toView.alpha = 1
                    toView.center = originalCenter
                },
                completion: { (finished: Bool) -> (Void) in
                    if finished
                    {
                        self.bubble.removeFromSuperview()
                        
                        transitionContext.completeTransition(true)
                    }
                }
            )
        } 
        else 
        {
            let originalSize = fromView.frame.size

            self.bubble.frame = self.frameForBubbleWithSize(originalSize: originalSize, start: startingPoint)
            self.bubble.layer.cornerRadius = self.bubble.frame.height / 2
            self.bubble.center = self.startingPoint
            
            containerView.addSubview(toView)
            containerView.addSubview(self.bubble)

            UIView.animate(withDuration: self.dismissDuration,
                animations: 
                {
                    self.bubble.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                },
                completion: { (finished: Bool) -> (Void) in
                    if finished
                    {
                        toView.removeFromSuperview()
                        self.bubble.removeFromSuperview()

                        transitionContext.completeTransition(true)
                    }
                }
            )
        }
    }
}
