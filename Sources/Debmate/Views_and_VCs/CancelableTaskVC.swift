//
//  CancelableTaskVC.swift
//  Debware
//
//  Created by David Baraff on 6/28/17.
//  Copyright © 2017 David Baraff. All rights reserved.
//

#if os(iOS)

import UIKit

class CancelableTaskVC : UIViewController {
    var popupView: UIView!
    var activityIndicatorView: UIActivityIndicatorView!
    var label: UILabel!
    var progressView: UIProgressView!
    var cancelButton: UIButton!

    var progressMode = false

     override public func loadView() {
        view = UIView()
        view.backgroundColor = .clear
        
        popupView = UIView()
        popupView.backgroundColor = UIColor(white: 0.3, alpha: 0.8)
        popupView.frame = CGRect(origin: .zero, size: CGSize(160, 160))
        popupView.layer.cornerRadius = 12

        activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.style = .large
        activityIndicatorView.color = .white
        activityIndicatorView.frame = CGRect(x: 62, y: 62, width: 37, height: 37)
        
        label = UILabel()
        label.font = .boldSystemFont(ofSize: 17)
        label.textColor = .white
        label.textAlignment = .center
        label.frame = CGRect(x: 16, y: 13, width: 128, height: 21)

        progressView = UIProgressView()
        progressView.tintColor = .systemBlue
        progressView.frame = CGRect(x: 5, y: 79, width: 150, height: 2)

        cancelButton = UIButton()
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.systemBlue, for: .normal)
        cancelButton.frame = CGRect(x: 49, y: 120, width: 63, height: 30)
        
        view.addSubview(popupView)
        popupView.addSubview(label)
        popupView.addSubview(cancelButton)
        popupView.addSubview(activityIndicatorView)
        popupView.addSubview(progressView)
    }

    override func viewDidLoad() {
        progressView.isHidden = true
        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
    }
    
    override func viewDidLayoutSubviews() {
       popupView.center = view.center
    }
    
    func setProgress(_ value:Float) {
        if !progressMode {
            progressMode = true
            activityIndicatorView.stopAnimating()
            activityIndicatorView.isHidden = true
            progressView.isHidden = false
        }
        
        progressView.setProgress(value, animated: false)
    }
}

#endif

