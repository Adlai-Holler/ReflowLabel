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

func delay(time: NSTimeInterval, completionClosure: () -> ()) {
    // don't worry about all this bullshit
    let totalDelay = Int64(time * Double(NSEC_PER_SEC))
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            totalDelay
        ),
        dispatch_get_main_queue(), completionClosure)
}

class ReflowLayer : CALayer {
    var myFloat: CGFloat = 0.0 {
    didSet{
        print("\(self) \(myFloat)")
    }
    }
    override func addAnimation(anim: CAAnimation, forKey key: String?) {
        super.addAnimation(anim, forKey: key)
        print(self)
    }
    override class func needsDisplayForKey(key: String) -> Bool {
        switch(key) {
        case "myFloat": return true
        default: return super.needsDisplayForKey(key)
        }
    }
    
    override func drawInContext(ctx: CGContext)  {
        UIGraphicsPushContext(ctx)
        UIColor(white: myFloat, alpha: 1.0).setFill()
        UIRectFill(bounds)
        UIGraphicsPopContext()
    }
    
    override func actionForKey(event: String) -> CAAction? {
        print(event)
        return super.actionForKey(event)
    }
}
class ReflowLabel : UIView {
    var boundsWhenLastUpdatedFragPositions = CGRectNull
    let textStorage = NSTextStorage()
    let layoutManager = NSLayoutManager()
    let textContainer = NSTextContainer()
    var label: UILabel
    var wordViews: [ReflowFragmentView] = []
    var textFragsCameFrom: NSAttributedString
    lazy var displayLink: CADisplayLink = {
        return CADisplayLink(target: self, selector: "displayLinkFired:")
    }()
    override init(frame: CGRect)  {
        textFragsCameFrom = NSAttributedString()
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
        delay(1) {
            let anim = CABasicAnimation(keyPath: "myFloat")
            let layer = self.layer as! ReflowLayer
            anim.toValue = 0.8
            anim.duration = 2.0
            anim.delegate = self
            layer.addAnimation(anim, forKey: "theAnimKey")
            layer.myFloat = anim.toValue as! CGFloat
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func drawLayer(layer: CALayer, inContext ctx: CGContext) {
        
    }
    override class func layerClass() -> AnyClass {
        return ReflowLayer.self
    }
    func displayLinkFired(displayLink: CADisplayLink) {
        let presLayer = layer.presentationLayer() as! CALayer
        _updateFragPositions(CGRectIntegral(presLayer.bounds), animated: true)
    }
    
    func hideFrags() {
        for view in wordViews {
            view.hidden = true
        }
    }
    // should call automatically – observe label.text somehow
    func _recreateFrags() {
        textStorage.setAttributedString(NSAttributedString(string: label.text!, attributes: [ NSFontAttributeName: label.font]))
        for view in wordViews {
            view.removeFromSuperview()
        }
        wordViews.removeAll(keepCapacity: true)
        let attributedStr = label.attributedText!
        let str: CFString = label.text!
        
        let tokenizer = CFStringTokenizerCreate(nil, str, CFRangeMake(0, CFStringGetLength(str)), CFOptionFlags(kCFStringTokenizerUnitWordBoundary), CFLocaleCopyCurrent())
        for var next = CFStringTokenizerAdvanceToNextToken(tokenizer);
            next != .None;
            next = CFStringTokenizerAdvanceToNextToken(tokenizer) {
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            let nsrange = NSMakeRange(range.location, range.length)
            let attributedText = attributedStr.attributedSubstringFromRange(nsrange)
            if attributedText.string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).isEmpty {
                continue
            }
            var frame = boundingRect(nsrange, bounds: bounds)

            frame = fragFrameFromGlyphsFrame(frame)
            let label = ReflowFragmentView(frame: frame)
            label.characterRange = nsrange
            label.attributedText = attributedText
            addSubview(label)
            wordViews.append(label)
        }
        textFragsCameFrom = attributedStr
    }
    func fragFrameFromGlyphsFrame(glyphsFrame: CGRect) -> CGRect {
        var result = glyphsFrame
        result.size.width += 1
        return CGRectIntegral(result)
    }
    func _updateFragPositions(bounds: CGRect, animated: Bool) {
        if bounds == boundsWhenLastUpdatedFragPositions { return }
        boundsWhenLastUpdatedFragPositions = bounds
        textContainer.size = bounds.size
        for view in wordViews {
            let rect = fragFrameFromGlyphsFrame(boundingRect(view.characterRange, bounds: bounds))
            let newCenter = CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMidY(rect))
            if newCenter == view.center { continue }

            let goingDown = newCenter.y > view.center.y
            let goingUp = newCenter.y < view.center.y
            let theChange = {
                view.center = newCenter
            }
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
                    }, completion: {finished in })
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
                        }, completion: {finished in })
                } else {
                UIView.animateWithDuration(0.2, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.4, options: .BeginFromCurrentState, animations: theChange) {finished in }
                }
            } else {
                theChange()
            }
        }
    }
    
    override func actionForLayer(layer: CALayer, forKey event: String) -> CAAction? {
        print("Action for layer \(layer) for key \(event)")
        return super.actionForLayer(layer, forKey: event)
    }
    
    func boundingRect(characterRange: NSRange, bounds: CGRect) -> CGRect {
        // get y padding
//        let textRect = layoutManager.usedRectForTextContainer(textContainer)
        var glyphRange: NSRange = NSMakeRange(0, 0)
        layoutManager.characterRangeForGlyphRange(characterRange, actualGlyphRange: &glyphRange)
        let result = layoutManager.boundingRectForGlyphRange(glyphRange, inTextContainer: textContainer)
//        result.origin.y += (bounds.size.height - textRect.size.height) / 2.0
        return result
    }
}