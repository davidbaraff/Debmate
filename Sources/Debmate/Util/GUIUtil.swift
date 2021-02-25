//
//  GUIUtil.swift
//  Debmate
//
//  Copyright © 2019 David Baraff. All rights reserved.
//

#if os(iOS) || os(tvOS)

import Foundation
import UIKit

extension Util {
    /// Return the current root view controller.
    static public func rootViewController() -> UIViewController {
        guard let window = UIApplication.shared.delegate?.window,
            let rvc = window?.rootViewController else {
                fatalErrorForCrashReport("unable to obtain root view controller")
        }
        return rvc
    }
    
    /// Return the current topmost view controller
    static public func currentViewController() -> UIViewController  {
        var vc = rootViewController()
        while let next = vc.presentedViewController {
            vc = next
        }
        return vc
    }
    
    
    /// Pin two views together
    /// - Parameter fromView: first view
    /// - Parameter view: second view
    static public func pinView(_ fromView: UIView, to view: UIView) {
        NSLayoutConstraint.activate([
          fromView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
          fromView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
          fromView.topAnchor.constraint(equalTo: view.topAnchor),
          fromView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
          ])
    }
    
    /// Dismiss a view controller and then run a completion handler
    ///
    /// - Parameters:
    ///   - viewController: optional view controller
    ///   - animated: if dismissal should be animated
    ///   - completion: completion closure
    ///
    /// If viewController is nil, completion is invoked immediately; otherwise, completion
    /// is run after viewController's dismissal is complete.
    static public func dismissPossiblyNilViewController(_ viewController: UIViewController?, animated: Bool, completion: @escaping () -> ()) {
        if let vc = viewController {
            vc.dismiss(animated: animated, completion: completion)
        }
        else {
            completion()
        }
    }
    
    /// Recolor an image
    ///
    /// - Parameters:
    ///   - image: input image
    ///   - tint: tint color
    /// - Returns: recolored image
    ///
    /// If there is an issue, the original image is returned.
    static public func tintedImage(_ image: UIImage?, tint: UIColor) -> UIImage? {
        guard let image = image else {
            return nil
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext(),
              let cgImage = image.cgImage else {
                  return image
        }
        
        context.translateBy(x: 0, y: image.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        let rect = CGRect(origin: .zero, size: image.size)
        
        // draw alpha-mask
        context.setBlendMode(.normal)
        context.draw(cgImage, in: rect)
        
        // draw tint color, preserving alpha values of original image
        context.setBlendMode(.sourceIn)
        tint.setFill()
        context.fill(rect)
        
        let coloredImage = UIGraphicsGetImageFromCurrentImageContext()
        return coloredImage ?? image
    }

    /// Darken an image.
    ///
    /// - Parameters:
    ///   - image: input image
    ///   - inputEV: how much to darken (default is -2); see CIExposureAdjust for details.
    /// - Returns: darkened image
    ///
    /// If there is an issue, the original image is returned.  Setting inputEv
    /// to a positive value will brighten the image.
    static public func darkenedImage(_ image: UIImage?, inputEV: Float = -2.0) -> UIImage? {
        guard let image = image else {
            return nil
        }
        
        // Get the original image and set up the CIExposureAdjust filter
        guard let inputImage = CIImage(image: image),
            let filter = CIFilter(name: "CIExposureAdjust") else {
                return  image
        }
        
        filter.setValue(inputImage, forKey: "inputImage")
        filter.setValue(inputEV, forKey: "inputEV")
        
        guard let filteredImage = filter.outputImage else {
            return  image
        }
        
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(filteredImage, from: filteredImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Create a blank image with a size and fill color
    ///
    /// - Parameters:
    ///   - fillColor: contents of image
    ///   - size: image size
    /// - Returns: image
    static public func createBlankImage(fillColor: UIColor, size: CGSize) -> UIImage {
        let bounds1 = CGRect(origin: .zero, size: size)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        guard let ctx = CGContext(data: nil,
                                  width: Int(size.width),
                                  height: Int(size.height),
                                  bitsPerComponent: 8,
                                  bytesPerRow: 0,
                                  space: colorSpace,
                                  bitmapInfo: bitmapInfo.rawValue) else {
                                    fatalErrorForCrashReport("failed to create CGContext")
        }
        
        ctx.setBlendMode(.normal)
        ctx.setFillColor(fillColor.cgColor)
        ctx.fill(bounds1)
        
        guard let finalImage = ctx.makeImage() else {
            fatalErrorForCrashReport("ctx.makeImage() failed")
        }
        
        return UIImage(cgImage: finalImage)
    }
    
    /// Show an (asynchronous) modal warning dialog.
    ///
    /// - Parameters:
    ///   - title: title for warning
    ///   - details: message body (optional)
    ///   - over: view controller (defaults to root view controller)
    ///   - transparent: allow slight transparency (not good for dark background)
    ///   - centered: center the detail text; otherwise, left justified.
    ///   - completionHandler: completion handler
    ///
    static public func showWarning(_ title: String, details: String? = nil,
                                   over viewController: UIViewController,
                                   transparent: Bool = false,
                                   centered: Bool = true,
                                   completionHandler: (() -> Void)? = nil) {
        let ac = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        if let details = details {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = centered ? .center : .left

            let messageText = NSMutableAttributedString(string: details,
                                                    attributes: [
                                                        NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .footnote),
                                                        NSAttributedString.Key.paragraphStyle: paragraphStyle])
            ac.setValue(messageText, forKey: "attributedMessage")
        }
        

        if !transparent {
            ac.view.backgroundColor = UIColor.white
            ac.view.layer.cornerRadius = 12
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            if let completionHandler = completionHandler {
                completionHandler()
            }
         }
        
        ac.addAction(okAction)
        viewController.present(ac, animated: true)
     }
    
    /// Show a modal confirmation dialog.
    ///
    /// - Parameters:
    ///   - title: title for warning
    ///   - action: action being taken (e.g. "Upload", "Remove")
    ///   - details: message body (optional)
    ///   - autoConfirmWhen: if true, skip dialog and and call completion handler with true
    ///   - over: view controller (defaults to root view controller)
    ///   - transparent: allow slight transparency (not good for dark background)
    ///   - completionHandler: completion handler (called with true or false)
    static public func confirmAction(_ title: String, action:String,
                                     details: String? = nil,
                                     autoConfirmWhen: Bool = false,
                                     over viewController: UIViewController,
                                     transparent: Bool = false,
                                     cancelString: String = "Cancel",
                                     completionHandler: ((Bool) -> Void)? = nil) {
        if autoConfirmWhen {
            completionHandler?(true)
            return
        }
        
        let ac = UIAlertController(title: title, message:details, preferredStyle: .alert)
        
        if !transparent {
            ac.view.backgroundColor = UIColor.white
            ac.view.layer.cornerRadius = 12
        }
        
        let confirmAction = UIAlertAction(title: action, style: .default) { _ in
            completionHandler?(true)
        }
        
        let cancelAction = UIAlertAction(title: cancelString, style: .cancel) { _ in
            completionHandler?(false)
        }
        
        ac.addAction(cancelAction)
        ac.addAction(confirmAction)
        viewController.present(ac, animated: true)
    }
}

/// Use this segue when you need a completion callback to run after the segue is done.
public class StoryboardSegueWithCompletion: UIStoryboardSegue {
    public var completion: (() -> Void)?

    override public func perform() {
        super.perform()
        if let completion = completion {
            completion()
        }
    }
}

#endif

