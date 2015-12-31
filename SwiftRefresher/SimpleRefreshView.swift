//
//  SimpleRefreshView.swift
//  Demo
//
//  Created by MORITANAOKI on 2015/12/31.
//  Copyright © 2015年 molabo. All rights reserved.
//

import UIKit

public class SimpleRefreshView: UIView, RefresherEventReceivable {
    private weak var activityIndicatorView: UIActivityIndicatorView!
    private weak var pullingImageView: UIImageView!
    
    public var activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
    
    private init() {
        super.init(frame: CGRect.zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        let aView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        aView.hidesWhenStopped = true
        addSubview(aView)
        aView.translatesAutoresizingMaskIntoConstraints = false
        addConstraints(
            [
                NSLayoutConstraint(item: aView, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: aView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0.0)
            ]
        )
        self.activityIndicatorView = aView
        
        let pView = UIImageView(frame: CGRect.zero)
        pView.contentMode = .ScaleAspectFit
        if let imagePath = NSBundle(forClass: SimpleRefreshView.self).pathForResource("pull", ofType: "png") {
            pView.image = UIImage(contentsOfFile: imagePath)
        }
        addSubview(pView)
        pView.translatesAutoresizingMaskIntoConstraints = false
        addConstraints(
            [
                NSLayoutConstraint(item: pView, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: pView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: pView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1.0, constant: 22.0),
                NSLayoutConstraint(item: pView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1.0, constant: 22.0),
            ]
        )
        
        self.pullingImageView = pView
    }
    
    public func didReceiveEvent(event: RefresherEvent) {
        switch event {
        case .StartRefreshing:
            pullingImageView.hidden = true
            activityIndicatorView.startAnimating()
        case .EndRefreshing:
            activityIndicatorView.stopAnimating()
        case .Pulling:
            pullingImageView.hidden = false
        }
    }
}