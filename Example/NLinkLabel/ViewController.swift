//
//  ViewController.swift
//  NLinkLabel
//
//  Created by nilkanthdesai76 on 04/03/2024.
//  Copyright (c) 2024 nilkanthdesai76. All rights reserved.
//

import Foundation
import UIKit
import NLinkLabel

class ViewController: UIViewController {

    @IBOutlet weak var lblTitle: NLinkLabel!
    
    /// This is attributed string for terms and condition
    var signupSrting: NSAttributedString {
        let normal = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]
        let tappable: [NSAttributedString.Key : Any] = [ NSAttributedString.Key.foregroundColor: UIColor.systemBlue,  NSAttributedString.Key.attachment : "tappable", NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]
        
        let para = NSMutableParagraphStyle()
        para.minimumLineHeight = 20
        para.maximumLineHeight = 20
        para.alignment = .center
        
        let mutableStr = NSMutableAttributedString(attributedString: NSAttributedString.attributedText(texts: ["This is a ","Tappable", " String"], attributes: [normal, tappable, normal]))
        let range = NSMakeRange(0, mutableStr.string.count)
        mutableStr.addAttribute(NSAttributedString.Key.paragraphStyle, value: para, range: range)
        
        return mutableStr
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        lblTitle.setTagText(attriText: signupSrting, linebreak: .byTruncatingTail)
        lblTitle.delegate = self
    }
}

// MARK: - NLinkLabelDelagete
extension ViewController: NLinkLabelDelagete {
    
    func tapOnEmpty(index: IndexPath?) {}
    
    func tapOnTag(tagName: String, type: ActiveType, tappableLabel: NLinkLabel) {
        print(tagName)
    }
}
