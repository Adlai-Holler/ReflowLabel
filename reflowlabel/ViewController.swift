//
//  ViewController.swift
//  ReflowLabel
//
//  Created by Adlai Holler on 7/12/14.
//  Copyright (c) 2014 Adlai Holler. All rights reserved.
//

import UIKit
let maxIndentationLevel = 5
let indentationWidth: CGFloat = 25.0
class ViewController: UIViewController {
    @IBOutlet var levelLabel: UILabel!
    var indentationLevel:Int = 0 {
        didSet {
            let indentation = indentationWidth * CGFloat(indentationLevel);
            UIView.animateWithDuration(1.0, delay: 0, usingSpringWithDamping: 0.95, initialSpringVelocity: 0.3, options: .BeginFromCurrentState, animations: {
                let frame = CGRect(x: indentation, y: 150, width: self.view.bounds.size.width - indentation, height: 200)
                self.reflowLabel.frame = frame
            }, completion: { finished in
                
            })
            levelLabel.text = "Level: \(indentationLevel)"
        }
    }
    
    lazy var reflowLabel: ReflowLabel = {
        let l = ReflowLabel(frame: CGRect(x: 0, y: 150, width: 320, height: 200))
        l.label.text = "This text will reflow as the label shrinks, I'm sure of it. If not, then it'll be back to the drawing board I guess – but hey, considering how fast this was built, I still have reason to be proud."
        l.layer.borderColor = UIColor.blackColor().CGColor
        l.layer.borderWidth = 1
        l.layer.cornerRadius = 3
        l._recreateFrags()
        return l
    }()
                            
    override func viewDidLoad() {
        super.viewDidLoad()
        view.insertSubview(reflowLabel, atIndex: 0)
    }
    
    @IBAction func stepperValueChanged(sender: UIStepper) {
        let val = Int(sender.value)
        indentationLevel = val
    }

}

