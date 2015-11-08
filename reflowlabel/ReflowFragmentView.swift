//
//  ReflowFragmentView.swift
//  ReflowLabel
//
//  Created by Adlai Holler on 7/12/14.
//  Copyright (c) 2014 Adlai Holler. All rights reserved.
//

import Foundation
import UIKit
class ReflowFragmentView: UILabel {
    var characterRange: NSRange
    override init(frame: CGRect)  {
        characterRange = NSMakeRange(NSNotFound, NSNotFound)
        super.init(frame: frame)
        lineBreakMode = .ByClipping
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
