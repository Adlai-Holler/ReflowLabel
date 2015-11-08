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
    let label: UILabel
    var wordViews: [ReflowFragmentView] = []
    var textFragsCameFrom: NSAttributedString?
    
    private lazy var displayLink: CADisplayLink = { [unowned self] in
        return CADisplayLink(target: self, selector: "displayLinkFired:")
    }()
    
    override init(frame: CGRect)  {
        label = UILabel()

        super.init(frame: frame)
        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0.0
        layoutManager.addTextContainer(textContainer)
        label.frame = bounds
        label.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        label.hidden = true
        clipsToBounds = true
        addSubview(label)
        displayLink.frameInterval = 5
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func displayLinkFired(displayLink: CADisplayLink) {
        let presLayer = layer.presentationLayer() as! CALayer
        updateFragPositions(CGRectIntegral(presLayer.bounds), animated: true)
    }
    
    private static let tokenRegex = try! NSRegularExpression(pattern: "[\\S]+", options: [])
    
    // should call automatically – observe label.text somehow
    func _recreateFrags() {
        textStorage.setAttributedString(NSAttributedString(string: label.text!, attributes: [ NSFontAttributeName: label.font]))
        for view in wordViews {
            view.removeFromSuperview()
        }
        wordViews.removeAll(keepCapacity: true)
        let attributedStr = label.attributedText!
        let str2 = label.text!
        let range = str2.nsRangeFromRange(str2.startIndex..<str2.endIndex)
        let bounds = self.bounds
        ReflowLabel.tokenRegex.enumerateMatchesInString(str2, options: [], range: range) { result, _, _ in
            guard let result = result else { return }
            let nsRange = result.range
            let attributedText = attributedStr.attributedSubstringFromRange(nsRange)
            var frame = self.boundingRect(nsRange, bounds: bounds)
            
            frame = self.fragFrameFromGlyphsFrame(frame)
            let label = ReflowFragmentView(frame: frame)
            label.characterRange = nsRange
            label.attributedText = attributedText
            self.addSubview(label)
            self.wordViews.append(label)
        }

        textFragsCameFrom = attributedStr
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