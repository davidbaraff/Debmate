//
//  PopupTextMenu.swift
//  Debmate
//
//  Copyright © 2018 David Baraff. All rights reserved.
//

#if os(iOS)

import Foundation
import UIKit

fileprivate class Cell : UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        textLabel?.textColor = .systemBlue
        textLabel?.font = .systemFont(ofSize: 17)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class PopupTextMenuVC : UITableViewController {
    var textEntries = [String]()
    var callbacks = [(() ->())?]()
    var images = [UIImage?]()
    var indentations = [Int]()
    var completionHandler: (() -> ())?
    var treeTitle: String?
    var tracePaperEnabled = [Bool]()
    var selectedIndex: Int?
    
    /// Present a popup menu
    ///
    /// - Parameters:
    ///   - presentingViewController: Controller the menu is being presented from
    ///   - sourceView: anchoring view
    ///   - arrowDirections: allowed arrow directions
    ///   - preferredContentWidth: prefered menu width
    ///   - preferredCellHeight: prefered per-entry height
    ///   - textAndCallbacks: menu strings and the corresponding callback function on selection
    ///   - completionHandler: Run when the menu is dismissed
    @discardableResult
    static public func present(presentingViewController: UIViewController, sourceView: UIView,
                               sourceRect: CGRect? = nil,
                               arrowDirections: UIPopoverArrowDirection = .left,
                               preferredContentWidth: Int = 300,
                               preferredCellHeight: Int = 44,
                               textAndCallbacks: [(String, (() ->())?)],
                               selectedIndex: Int? = nil,
                               completionHandler: (() -> ())? = nil) -> PopupTextMenuVC {
        let menuVC = PopupTextMenuVC()
        menuVC.textEntries = textAndCallbacks.map { $0.0 }
        menuVC.callbacks = textAndCallbacks.map { $0.1 }
        menuVC.completionHandler = completionHandler
        menuVC.tracePaperEnabled = textAndCallbacks.map { $0.1 != nil }
        
        menuVC.modalPresentationStyle = .popover
        menuVC.popoverPresentationController?.permittedArrowDirections = arrowDirections
        menuVC.popoverPresentationController?.sourceView = sourceView
        menuVC.popoverPresentationController?.sourceRect = sourceRect ?? sourceView.bounds
        menuVC.popoverPresentationController?.backgroundColor = .white
        
        menuVC.preferredContentSize = CGSize(preferredContentWidth, menuVC.textEntries.count * preferredCellHeight)
        menuVC.tableView.rowHeight = CGFloat(preferredCellHeight)
        menuVC.selectedIndex = selectedIndex
        presentingViewController.present(menuVC, animated: true)
        return menuVC
    }
    
    /// Present a popup menu
    ///
    /// - Parameters:
    ///   - presentingViewController: Controller the menu is being presented from
    ///   - sourceView: anchoring view
    ///   - arrowDirections: allowed arrow directions
    ///   - preferredContentWidth: prefered menu width
    ///   - preferredCellHeight: prefered per-entry height
    ///   - dataAndCallbacks: list of (menu label, image, indentation level, selection callback) tuples
    ///   - completionHandler: Run when the menu is dismissed
    static public func presentTree(presentingViewController: UIViewController, sourceView: UIView,
                                   arrowDirections: UIPopoverArrowDirection = .left,
                                   treeTitle: String? = nil,
                                   preferredContentWidth: Int = 300,
                                   preferredCellHeight: Int = 44,
                                   dataAndCallbacks: [(String, UIImage?, Int, () ->(), Bool)],
                                   completionHandler: (() -> ())? = nil) {
        let menuVC = PopupTextMenuVC()
        
        menuVC.textEntries = dataAndCallbacks.map { $0.0 }
        menuVC.images = dataAndCallbacks.map { $0.1 }
        menuVC.indentations = dataAndCallbacks.map { $0.2 }
        menuVC.callbacks = dataAndCallbacks.map { $0.3 }
        menuVC.tracePaperEnabled = dataAndCallbacks.map { $0.4 }
        menuVC.completionHandler = completionHandler
        menuVC.treeTitle = treeTitle
        
        menuVC.modalPresentationStyle = .popover
        menuVC.popoverPresentationController?.permittedArrowDirections = arrowDirections
        menuVC.popoverPresentationController?.sourceView = sourceView
        menuVC.popoverPresentationController?.sourceRect = sourceView.bounds
        menuVC.popoverPresentationController?.backgroundColor = .white
        
        menuVC.preferredContentSize = CGSize(preferredContentWidth, menuVC.textEntries.count * preferredCellHeight)
        menuVC.tableView.rowHeight = CGFloat(preferredCellHeight)
        presentingViewController.present(menuVC, animated: true)
    }
    
    init() {
        super.init(style: .plain)
        tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(Cell.self, forCellReuseIdentifier: "cell")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        if let completionHandler = self.completionHandler {
            completionHandler()
        }
    }
    
    // MARK: UITableViewDelegate
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return treeTitle
    }
    
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return textEntries.count
    }
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if !indentations.isEmpty {
            // cell.indentationLevel = indentations[indexPath.row]
            cell.separatorInset = UIEdgeInsets(top: 0, left: 1.5 * cell.indentationWidth * CGFloat(indentations[indexPath.row]), bottom: 0, right: 0)
            cell.textLabel?.textAlignment = .left
            cell.imageView?.image = images[indexPath.row]
            cell.textLabel?.alpha = tracePaperEnabled[indexPath.row] ? 1 : 0.5
            cell.isUserInteractionEnabled = tracePaperEnabled[indexPath.row]
        }
        else if !tracePaperEnabled.isEmpty {
            cell.isUserInteractionEnabled = tracePaperEnabled[indexPath.row]
            cell.textLabel?.alpha = tracePaperEnabled[indexPath.row] ? 1 : 0.5
        }
        cell.textLabel?.text = textEntries[indexPath.row]
        cell.accessoryType = (indexPath.row == selectedIndex) ? .checkmark : .none
        return cell
    }
    
    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true) {
            self.callbacks[indexPath.row]?()
        }
    }
}

#endif
