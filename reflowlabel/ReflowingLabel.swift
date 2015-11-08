//
//  ReflowingLabel.swift
//  ReflowLabel
//
//  Created by Adlai Holler on 7/12/14.
//  Copyright (c) 2014 Adlai Holler. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

class ReflowLabel : UIView {
    var boundsWhenLastUpdatedFragPositions = CGRectNull
    let textStorage = NSTextStorage()
    let layoutManager = NSLayoutManager()
    let textContainer = NSTextContainer()
    var wordViews: [ReflowFragmentView] = []

    // FIXME: Use NSAttributedString instead.
    var text = "" {
        didSet {
            if text != oldValue {
                _recreateFrags()
            }
        }
    }
    
    /// Hate implicitly unwrapped optionals but we need to pass self into the initializer.
    private var displayLink: CADisplayLink!
    
    override init(frame: CGRect)  {
        super.init(frame: frame)
        displayLink = CADisplayLink(target: self, selector: "displayLinkFired:")
        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0.0
        layoutManager.addTextContainer(textContainer)
        clipsToBounds = true
        displayLink.frameInterval = 5
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func displayLinkFired(displayLink: CADisplayLink) {
        let presLayer = layer.presentationLayer() as! CALayer
        updateFragPositions(CGRectIntegral(presLayer.bounds), animated: true)
    }
    
    private static let tokenRegex = try! NSRegularExpression(pattern: "[\\S]+", options: [])
    
    // should call automatically – observe label.text somehow
    func _recreateFrags() {
        let font = UIFont.systemFontOfSize(17)
        let attributedString = NSAttributedString(string: text, attributes: [NSFontAttributeName: font])
        textStorage.setAttributedString(attributedString)
        for view in wordViews {
            view.removeFromSuperview()
        }
        wordViews.removeAll(keepCapacity: true)
        let range = text.nsRangeFromRange(text.startIndex..<text.endIndex)
        ReflowLabel.tokenRegex.enumerateMatchesInString(text, options: [], range: range) { result, _, _ in
            guard let result = result else { return }
            let nsRange = result.range
            let attributedText = attributedString.attributedSubstringFromRange(nsRange)
            var frame = self.boundingRect(nsRange, bounds: self.bounds)
            
            frame = self.fragFrameFromGlyphsFrame(frame)
            let label = ReflowFragmentView(frame: frame)
            label.characterRange = nsRange
            label.attributedText = attributedText
            self.addSubview(label)
            self.wordViews.append(label)
        }
    }
    
    private func fragFrameFromGlyphsFrame(glyphsFrame: CGRect) -> CGRect {
        var result = glyphsFrame
        result.size.width += 1
        return result.integral
    }
    
    private func updateFragPositions(bounds: CGRect, animated: Bool) {
        if bounds == boundsWhenLastUpdatedFragPositions { return }
        boundsWhenLastUpdatedFragPositions = bounds
        textContainer.size = bounds.size
        for view in wordViews {
            let rect = fragFrameFromGlyphsFrame(boundingRect(view.characterRange, bounds: bounds))
            let newCenter = CGPoint(x: rect.midX, y: rect.midY)
            if newCenter == view.center { continue }

            let goingDown = newCenter.y > view.center.y
            let goingUp = newCenter.y < view.center.y
            
            if animated {
                if goingDown {
                    UIView.animateKeyframesWithDuration(0.2, delay: 0, options: .BeginFromCurrentState, animations: {

                        UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0.5){
                            var c = view.center
                            c.x += 50
                            view.center = c
                            view.alpha = 0
                        }
                        UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0){
                            var c = newCenter
                            c.x -= 50
                            view.center = c
                        }
                        UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0.5) {
                            view.alpha = 1
                            view.center = newCenter
                        }
                    }, completion: nil)
                } else if goingUp {
                    UIView.animateKeyframesWithDuration(0.2, delay: 0, options: .BeginFromCurrentState, animations: {
                        
                        UIView.addKeyframeWithRelativeStartTime(0, relativeDuration: 0.5){
                            var c = view.center
                            c.x -= 50
                            view.center = c
                            view.alpha = 0
                        }
                        UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0){
                            var c = newCenter
                            c.x += 50
                            view.center = c
                        }
                        UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0.5) {
                            view.alpha = 1
                            view.center = newCenter
                        }
                        }, completion: nil)
                } else {
                    UIView.animateWithDuration(0.2, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.4, options: .BeginFromCurrentState, animations: {
                        view.center = newCenter
                        }, completion: nil)
                }
            } else {
                view.center = newCenter
            }
        }
    }
    
    private func boundingRect(characterRange: NSRange, bounds: CGRect) -> CGRect {
        // get y padding
        var glyphRange = NSMakeRange(0, 0)
        layoutManager.characterRangeForGlyphRange(characterRange, actualGlyphRange: &glyphRange)
        return layoutManager.boundingRectForGlyphRange(glyphRange, inTextContainer: textContainer)
    }
}