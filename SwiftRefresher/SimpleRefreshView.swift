//
//  SimpleRefreshView.swift
//  Demo
//
//  Created by MORITANAOKI on 2015/12/31.
//  Copyright © 2015年 molabo. All rights reserved.
//

import UIKit

private let DEFAULT_ACTIVITY_INDICATOR_VIEW_STYLE: UIActivityIndicatorViewStyle = .Gray
private let DEFAULT_PULLING_IMAGE: UIImage? = {
    if let imagePath = NSBundle(forClass: SimpleRefreshView.self).pathForResource("pull", ofType: "png") {
        return UIImage(contentsOfFile: imagePath)
    }
    return nil
}()

public class SimpleRefreshView: UIView, SwfitRefresherEventReceivable {
    private weak var activityIndicatorView: UIActivityIndicatorView!
    private weak var pullingImageView: UIImageView!
    
    private var activityIndicatorViewStyle = DEFAULT_ACTIVITY_INDICATOR_VIEW_STYLE
    private var pullingImage: UIImage?
    
    convenience init(activityIndicatorViewStyle: UIActivityIndicatorViewStyle, pullingImage: UIImage? = DEFAULT_PULLING_IMAGE) {
        self.init(frame: CGRect.zero)
        self.activityIndicatorViewStyle = activityIndicatorViewStyle
        self.pullingImage = pullingImage
        commonInit()
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
        let aView = UIActivityIndicatorView(activityIndicatorStyle: activityIndicatorViewStyle)
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
        pView.image = pullingImage
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
    
    public func didReceiveEvent(event: SwiftRefresherEvent) {
        switch event {
        case .Pull:
            pullingImageView.hidden = false
        case .StartRefreshing:
            pullingImageView.hidden = true
            activityIndicatorView.startAnimating()
        case .EndRefreshing:
            activityIndicatorView.stopAnimating()
        case .RecoveredToInitialState:
            break
        }
    }
}