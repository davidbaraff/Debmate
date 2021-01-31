//
//  PopoverMessageVC.swift
//  Debmate
//
//  Created by David Baraff on 3/4/18.
//  Copyright © 2018 David Baraff. All rights reserved.
//

#if os(iOS)

import Foundation
import UIKit

/// A UIViewController that presents a message in a popover view.
public class PopoverMessageVC : UIViewController {
    var label: UILabel?
    var button: UIButton?
    var buttonHandler: (() -> ())?
    var extraMargin = CGSize.zero
    var labelSize = CGSize.zero
    static public let systemBlue = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
    
    @objc
    func buttonPressed() {
        if let buttonHandler = buttonHandler {
            buttonHandler()
        }
        dismiss(animated: true)
    }
    
    
    /// Present a message
    ///
    /// - Parameters:
    ///   - buttonText: text to be displayed in a single button
    ///   - extraMargin: addition margin around text (optional)
    ///   - textColor: color of message (defaults to system blue)
    ///   - backgroundColor: popover background (defaults to white)
    ///   - pressedTextColor: what color the text should be when pressed
    ///   - buttonHandler: optional closure to run when button is pressed
    public convenience init(buttonText: String, extraMargin: CGSize = CGSize(width: 20, height:20),
                textColor: UIColor = PopoverMessageVC.systemBlue,
                backgroundColor: UIColor = UIColor.white,
                pressedTextColor: UIColor = UIColor.gray, buttonHandler bh: (() -> ())?) {
        self.init(nibName: nil, bundle: nil)
        let boxes = UIButton()
        button = boxes
        buttonHandler = bh
        self.extraMargin = extraMargin
        boxes.setTitle(buttonText, for: .normal)
        boxes.setTitleColor(textColor, for: .normal)
        boxes.setTitleColor(pressedTextColor, for: .highlighted)
        boxes.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
    }
    
    
    /// Present a message using an attributed text string.
    ///
    /// - Parameters:
    ///   - attributedText: text message as attributed text
    ///   - extraMargin: addition margin around text (optional)
    ///   - backgroundColor: popover background (defaults to white)
    public convenience init(attributedText: NSAttributedString, extraMargin: CGSize = CGSize(width: 40, height: 30),
                backgroundColor: UIColor = UIColor.white) {
        self.init(nibName: nil, bundle: nil)
        let l = UILabel()
        label = l
        l.attributedText = attributedText
        self.extraMargin = extraMargin
        labelSize = attributedText.size()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    /// Specify the view the popup should use for an anchor.
    ///
    /// - Parameter view: anchoring view
    public func setAnchoringView(_ view: UIView) {
        self.modalPresentationStyle = .popover
        self.popoverPresentationController?.sourceView = view
        self.popoverPresentationController?.sourceRect = view.bounds
    }
    
    override public func viewDidLoad() {
        // view.layer.cornerRadius = 6
        if let sv = button ?? label {
            view.addSubview(sv)
        }
        
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        let delta = extraMargin
        
        if let label = label {
            preferredContentSize = labelSize + delta
            label.numberOfLines = 0
            label.frame = CGRect(origin: view.frame.origin + CGPoint(x: delta.width/2, y: delta.height/2), size: labelSize)
        }
        else if let button = button {
            preferredContentSize = button.intrinsicContentSize + delta
            button.frame = CGRect(origin: view.frame.origin, size: preferredContentSize)
        }
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        // without setting background color, radius (next line) has no effect
        view.superview?.backgroundColor = UIColor(white: 0.8, alpha: 1)
        view.superview?.layer.cornerRadius = 6
        // view.layer.cornerRadius = 6
        super.viewDidAppear(animated)
    }
}

#endif

