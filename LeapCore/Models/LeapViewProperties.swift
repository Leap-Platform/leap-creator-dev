//
//  LeapViewProperties.swift
//  LeapSDK
//
//  Created by Aravind GS on 27/04/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class LeapViewProperties {
    var viewId: String
    weak var weakView: UIView?
    var parent: String?
    var children: [String] = []
    var nodeIndex: Int
    var controller:String?
    
    var accId: String?
    var accLabel: String?
    var className: String
    var tag: String
    var text:String?
    var isSelected:Bool
    var isEnabled:Bool
    var isFocused:Bool
    var isWKWebview:Bool
    
    init(with view:UIView, uuid:String, parentUUID:String?, index:Int = 0, controllerName:String?) {
        viewId = uuid
        weakView = view
        parent = parentUUID
        nodeIndex = index
        controller = controllerName
        
        accId = view.accessibilityIdentifier
        accLabel = view.accessibilityLabel
        className = String(describing: type(of: view))
        tag = "\(view.tag)"
        
        text = {
            if let label = view as? UILabel { return label.text }
            if let textField = view as? UITextField { return textField.text }
            if let textView = view as? UITextView { return textView.text }
            if let button = view as? UIButton { return button.title(for: .normal) }
            return nil
        }()
        
        isSelected = (view as? UIControl)?.isSelected ?? false
        isEnabled = (view as? UIControl)?.isEnabled ?? false
        isFocused = view.isFocused
        isWKWebview = view.isMember(of: WKWebView.self)
        
    }
    
}
