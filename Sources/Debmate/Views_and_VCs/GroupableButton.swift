//
//  GroupableButton.swift
//  Debmate
//
//  Copyright © 2018 David Baraff. All rights reserved.
//

#if os(iOS) || os(tvOS)

import Foundation
import UIKit

/// A UIButton that can be used in a ButtonGroup.
public class GroupableButton : UIButton {
    weak var buttonGroup: ButtonGroup?
    
    override public var isHighlighted: Bool {
        didSet {
            if isHighlighted != oldValue {
                buttonGroup?.highlightChanged(isHighlighted)
            }
        }
    }
}

/// Class for grouping buttons together.
///
/// When any button in the group is highlighted, all the buttons in the group
/// are highlighted.  The touchUpInside action for any button causes the
/// (optional) pressed closure of the ButtonGroup to be run.
public class ButtonGroup {
    
    /// Closure that is run when any button in the group has its touchUpInside action invoked.
    public var pressed: (() -> ())?
    
    public init() {
    }
    
    var buttons = [UIButton]()
    
    
    /// Add a button to the group
    ///
    /// - Parameter button: button to be added
    public func add(button: GroupableButton) {
        button.buttonGroup = self
        buttons.append(button)
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
    }
    
    
    /// Remove a button from the group
    ///
    /// - Parameter button: button to be removed
    public func remove(button: GroupableButton) {
        buttons = buttons.filter { $0 != button }
        button.buttonGroup = nil
    }
    
    func highlightChanged(_ state: Bool) {
        for button in buttons {
            button.isHighlighted = state
        }
    }
    
    @objc func buttonPressed() {
        pressed?()
    }
}

#endif
