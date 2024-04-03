//
//  NLinkLabel.swift
//  NLinkLabel
//
//  Created by Nilkanth Desai on 03/04/24.
//

import Foundation
import UIKit

/// Link label types
enum ActiveType {
    case Mention
    case Hashtag
    case URL
    case Custom(pattern: String)
    var pattern: String {
        switch self {
        case .Mention: return RegexParser.mentionPattern
        case .Hashtag: return RegexParser.hashtagPattern
        case .URL: return RegexParser.urlPattern
        case .Custom(let regex): return regex
        }
    }
}

// MARK: - Attributed
extension NSAttributedString {
    
    // This will give combined string with respective attributes
    class func attributedText(texts: [String], attributes: [[NSAttributedString.Key : Any]]) -> NSAttributedString {
        let attbStr = NSMutableAttributedString()
        for (index,element) in texts.enumerated() {
            attbStr.append(NSAttributedString(string: element, attributes: attributes[index]))
        }
        return attbStr
    }
}

extension String {
    
    /// It will return attributed string as per content of string
    /// - Parameters:
    ///   - defaultFont: Default Font Color
    ///   - defaultColor: Color for default text
    ///   - hasFont: Font for hastags used in string
    ///   - hasColor: Color for hastags used in string
    ///   - userNameFont: Font for mentions in string
    ///   - userNameColor: color for mentions in string
    ///   - alignment: alignment of string
    /// - Returns: attributed string with given configurations
    func getTagString(defaultFont: UIFont, defaultColor: UIColor, hasFont: UIFont, hasColor: UIColor, userNameFont: UIFont, userNameColor: UIColor, alignment: NSTextAlignment = .left) -> NSAttributedString {
        let attbStr = NSMutableAttributedString(string: self)
        let str = NSString(string: self)
        let range = str.range(of: str as String)
        
        
        attbStr.addAttribute(.font, value: defaultFont, range: range)
        attbStr.addAttribute(.foregroundColor, value: defaultColor, range: range)
        
        if let arrOfHasTags = RegexParser.getElements(from: self, with: RegexParser.hashtagPattern, range: range) {
            for has in arrOfHasTags {
                attbStr.addAttribute(.font, value: hasFont, range: has.range)
                attbStr.addAttribute(.foregroundColor, value: hasColor, range: has.range)
            }
        }
        
        if let arrOfUserNames = RegexParser.getElements(from: self, with: RegexParser.mentionPattern, range: range) {
            for userName in arrOfUserNames {
                attbStr.addAttribute(.font, value: userNameFont, range: userName.range)
                attbStr.addAttribute(.foregroundColor, value: userNameColor, range: userName.range)
            }
        }
        
        if let arrOfUrls = RegexParser.getElements(from: self, with: RegexParser.urlPattern, range: range) {
            for url in arrOfUrls {
                attbStr.addAttribute(.font, value: defaultFont, range: url.range)
                attbStr.addAttribute(.foregroundColor, value: UIColor.blue, range: url.range)
            }
        }

        let para = NSMutableParagraphStyle()
        para.alignment = alignment
        attbStr.addAttributes([NSAttributedString.Key.paragraphStyle: para], range: range)
        return attbStr
    }
}

struct RegexParser {
    /// RegEx for hashtag
    static let hashtagPattern = "(?:^|\\s|$)#[\\p{L}0-9_]*"
    /// RegEx For mention
    static let mentionPattern = "(?:^|\\s)@[\\p{L}0-9._-]*" //"(?:^|\\s|$|[.])@[\\p{L}0-9\\_-]*"
    /// RegEx for url
    static let urlPattern = "(^|[\\s.:;?\\-\\]<\\(])" +
        "((https?://|www\\.|pic\\.)[-\\w;/?:@&=+$\\|\\_.!~*\\|'()\\[\\]%#,☺]+[\\w/#](\\(\\))?)" +
    "(?=$|[\\s',\\|\\(\\).:;?\\-\\[\\]>\\)])"
    static let custom = "\\sit\\b"
    
    /// It will return array of NSTextCheckingResult matching with pattern in intrested range
    /// - Parameters:
    ///   - text: From string
    ///   - pattern: intrested pattern
    ///   - range: range for get elements
    /// - Returns: Array of NSTextCheckingResult objects
    static func getElements(from text: String, with pattern: String, range: NSRange) -> [NSTextCheckingResult]? {
        if text.isEmpty {return nil}
        do {
            let elementRegex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            return elementRegex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        } catch let error {
            print(error.localizedDescription)
            return []
        }
        //guard let elementRegex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        //return elementRegex.matches(in: text, options: [], range: range)
    }
}

protocol NLinkLabelDelagete: NSObjectProtocol {
    func tapOnTag(tagName: String, type: ActiveType, tappableLabel: NLinkLabel)
    func tapOnEmpty(index: IndexPath?)
}

class SelectAttribute: NSObject {
    var range: NSRange!
    var type: ActiveType = ActiveType.Hashtag
}

class NLinkLabel: UILabel, UITextViewDelegate {
    
    var hasSet: [NSTextCheckingResult] = []
    var mentionSet: [NSTextCheckingResult] = []
    var urlSet: [NSTextCheckingResult] = []
    var userName: [NSRange] = []
    var indexPath : IndexPath?
    
    private var heightCorrection: CGFloat = 0
    private lazy var textStorage = NSTextStorage()
    private lazy var layoutManager = NSLayoutManager()
    private lazy var textContainer = NSTextContainer()
    private var hasColor: UIColor!
    private var menColor: UIColor!
    private var urlColor: UIColor!
    private var selectedAttri:[SelectAttribute] = []
    weak var delegate: NLinkLabelDelagete?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupLabel()
    }
    
    
    /// It will setup link label
    private func setupLabel() {
        textStorage.setAttributedString(self.attributedText!)
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = .byTruncatingTail
        textContainer.maximumNumberOfLines = 0
        isUserInteractionEnabled = true
    }
    
    override var intrinsicContentSize: CGSize {
        let superSize = super.intrinsicContentSize
        textContainer.size = CGSize(width: superSize.width, height: CGFloat.greatestFiniteMagnitude)
        let size = layoutManager.usedRect(for: textContainer)
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
    
    // MARK: - Auto layout
    override func drawText(in rect: CGRect) {
        let range = NSRange(location: 0, length: textStorage.length)
        textContainer.size = rect.size
        let newOrigin = textOrigin(inRect: rect)
        layoutManager.drawBackground(forGlyphRange: range, at: newOrigin)
        layoutManager.drawGlyphs(forGlyphRange: range, at: newOrigin)
        setNeedsDisplay()
    }
    
    /// It will set label text as per existing patterns in text for tags, mentions and URLs
    /// - Parameters:
    ///   - attriText: Attributed text for label
    ///   - linebreak: linebreak mode
    func setTagText(attriText: NSAttributedString, linebreak : NSLineBreakMode){
        attributedText = attriText
        textContainer.lineBreakMode = linebreak
        textStorage.setAttributedString(attriText)
        setNeedsDisplay()
        
        let str = NSString(string: attriText.string)
        let range = str.range(of: str as String)
        
        if let arrOfHashTag = RegexParser.getElements(from: self.attributedText!.string, with: RegexParser.hashtagPattern, range: range) {
            hasSet = arrOfHashTag
        }
        if let arrOfMentions = RegexParser.getElements(from: self.attributedText!.string, with: RegexParser.mentionPattern, range:range) {
            mentionSet = arrOfMentions
        }
        if let arrOfUrls = RegexParser.getElements(from: self.attributedText!.string, with: RegexParser.urlPattern, range: range) {
            urlSet = arrOfUrls
        }
        
        userName = []
        attriText.enumerateAttribute(NSAttributedString.Key.attachment, in: range, options: []) { (attribute, rangeOfAtt, data) in
            if let _ = attribute {
                userName.append(rangeOfAtt)
            }
        }
    }
    
    // MARK: - touch event
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch: touch) { return }
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch: touch) { return }
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch: touch) { return }
        super.touchesMoved(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        _ = onTouch(touch: touch)
        super.touchesCancelled(touches, with: event)
    }
    
    
    /// It will return points in screen based on given rect
    /// - Parameter rect: frame of the view containing label
    /// - Returns: origin points from label
    private func textOrigin(inRect rect: CGRect) -> CGPoint {
        let usedRect = layoutManager.usedRect(for: textContainer)
        heightCorrection = (rect.height - usedRect.height)/2
        let glyphOriginY = heightCorrection > 0 ? rect.origin.y + heightCorrection : rect.origin.y
        return CGPoint(x: rect.origin.x, y: glyphOriginY)
    }
    
    /// It will manage user intraction based on touch object
    /// - Parameter touch: user intraction touch object
    /// - Returns: `Boolean indicating need to call super call for touch or not`
    private func onTouch(touch: UITouch) -> Bool {
        var avoidSuperCall = false
        var touchPoint:CGPoint = touch.location(in: self)
        touchPoint.y -= heightCorrection
        let glyphRect = layoutManager.boundingRect(forGlyphRange: NSMakeRange(0, self.attributedText!.string.utf16.count), in: textContainer)
        switch touch.phase {
        case .began, .moved:
            
            for tag in hasSet {
                if glyphRect.contains(touchPoint) {
                    let idx = layoutManager.glyphIndex(for: touchPoint, in: textContainer)
                    if idx >= tag.range.location && idx <= (tag.range.length + tag.range.location){
                        //setSelectedAttribute(range: tag.range, actType: ActiveType.Hashtag)
                        break
                    }
                }
            }
            
            for tag in mentionSet {
                if glyphRect.contains(touchPoint) {
                    let idx = layoutManager.glyphIndex(for: touchPoint, in: textContainer)
                    if idx >= tag.range.location && idx <= (tag.range.length + tag.range.location){
                        //setSelectedAttribute(range: tag.range, actType: ActiveType.Mention)
                        break
                    }
                }
            }
            
            for tag in urlSet {
                if glyphRect.contains(touchPoint) {
                    let idx = layoutManager.glyphIndex(for: touchPoint, in: textContainer)
                    if idx >= tag.range.location && idx <= (tag.range.length + tag.range.location){
                        //setSelectedAttribute(range: tag.range, actType: ActiveType.URL)
                        break
                    }
                }
            }
            
            for name in userName {
                if glyphRect.contains(touchPoint) {
                    let idx = layoutManager.glyphIndex(for: touchPoint, in: textContainer)
                    if idx >= name.location && idx <= (name.length + name.location){
                        //setSelectedAttribute(range: name, actType: ActiveType.URL)
                        break
                    }
                }
            }
            
            avoidSuperCall = true
            break
        case .ended:
            var tapFound = false
            /// It will iterate list of mentionSet and check any object is hit by touch point if yes then call NLinkLabelDelagete method tapOnTag
            for mention in mentionSet {
                if glyphRect.contains(touchPoint) {
                    let idx = layoutManager.glyphIndex(for: touchPoint, in: textContainer)
                    if idx >= mention.range.location && idx <= (mention.range.length + mention.range.location){
                        let strAtt = textStorage.attributedSubstring(from: mention.range)
                        delegate?.tapOnTag(tagName: strAtt.string,type: ActiveType.Mention, tappableLabel: self)
                        tapFound = true
                        break
                    }
                }
            }
            
            /// It will iterate list of hasSet and check any object is hit by touch point if yes then call NLinkLabelDelagete method tapOnTag
            for tag in hasSet {
                if glyphRect.contains(touchPoint) {
                    let idx = layoutManager.glyphIndex(for: touchPoint, in: textContainer)
                    if idx >= tag.range.location && idx <= (tag.range.length + tag.range.location){
                        let strAtt = textStorage.attributedSubstring(from: tag.range)
                        delegate?.tapOnTag(tagName: String(strAtt.string),type: ActiveType.Hashtag, tappableLabel: self)
                        tapFound = true
                        break
                    }
                }
            }
            
            /// It will iterate list of urlSet and check any object is hit by touch point if yes then call NLinkLabelDelagete method tapOnTag
            for url in urlSet {
                if glyphRect.contains(touchPoint) {
                    let idx = layoutManager.glyphIndex(for: touchPoint, in: textContainer)
                    if idx >= url.range.location && idx <= (url.range.length + url.range.location){
                        let strAtt = textStorage.attributedSubstring(from: url.range)
                        delegate?.tapOnTag(tagName: strAtt.string,type: ActiveType.URL, tappableLabel: self)
                        tapFound = true
                        break
                    }
                }
            }
            
            /// It will iterate list of userName and check any object is hit by touch point if yes then call NLinkLabelDelagete method tapOnTag
            for name in userName {
                if glyphRect.contains(touchPoint) {
                    let idx = layoutManager.glyphIndex(for: touchPoint, in: textContainer)
                    if idx >= name.location && idx <= (name.length + name.location){
                        self.attributedText!.enumerateAttribute(NSAttributedString.Key.attachment, in: name, options: []) { (attribute, rangeOfAtt, data) in
                            if let attr = attribute {
                                delegate?.tapOnTag(tagName: attr as! String,type: .Mention, tappableLabel: self)
                            }
                        }
                        tapFound = true
                        break
                    }
                }
            }
            
            if !tapFound{
                delegate?.tapOnEmpty(index: indexPath)
            }
            
            //removeSelectedAttributed()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
                self.removeSelectedAttributed()
            })
            avoidSuperCall = true
            break
        case .cancelled:
            removeSelectedAttributed()
            break
        case .stationary:
            removeSelectedAttributed()
            break
        default:
            break
        }
        return avoidSuperCall
    }
    
    /// It will set attributes to string as per active type
    /// - Parameters:
    ///   - range: range of string where to apply attribute
    ///   - actType: type of string (i.e: Mention, Hashtag, URL)
    private func setSelectedAttribute(range: NSRange, actType: ActiveType){
        removeSelectedAttributed()
        
        let sel = SelectAttribute()
        sel.range = range
        sel.type = actType
        selectedAttri.append(sel)
        
        let attri: [NSAttributedString.Key: AnyObject]!
        switch actType {
        case .Hashtag:
            attri = [NSAttributedString.Key.foregroundColor: UIColor.gray]
            break
        case .Mention:
            attri = [NSAttributedString.Key.foregroundColor: UIColor.red]
            break
        default:
            attri = [NSAttributedString.Key.foregroundColor: UIColor.gray]
            break
        }
        textStorage.addAttributes(attri, range: range)
        setNeedsDisplay()
    }
    
    private func removeSelectedAttributed(){
        for item in selectedAttri {
            let attri: [NSAttributedString.Key: AnyObject]!
            switch item.type {
            case .Hashtag:
                attri = [NSAttributedString.Key.foregroundColor: UIColor.gray]
                break
            case .Mention:
                attri = [NSAttributedString.Key.foregroundColor: UIColor.red]
                break
            default:
                attri = [NSAttributedString.Key.foregroundColor: UIColor.red]
                break
            }
            textStorage.addAttributes(attri, range: item.range)
        }
        selectedAttri = []
        setNeedsDisplay()
    }
}

extension NLinkLabel: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
