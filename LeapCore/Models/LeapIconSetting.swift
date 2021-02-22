//
//  LeapIconSetting.swift
//  LeapCore
//
//  Created by Ajay S on 02/12/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation

@objc public class LeapIconSetting: NSObject, Codable {
    
    public var dismissible: Bool?
    public var leftAlign: Bool?
    private var isCustomised: Bool?
    public var bgColor: String?
    public var htmlUrl: String? //can also be base64
    
    public init(with dict: Dictionary<String, Any>) {
        
        if let dismissible = dict[constant_dismissible] as? Bool {
            self.dismissible = dismissible
        } else {
            self.dismissible = false
        }
        
        if let leftAlign = dict[constant_leftAlign] as? Bool {
            self.leftAlign = leftAlign
        } else {
            self.leftAlign = false
        }
        
        if let isCustomised = dict[constant_isCustomised] as? Bool {
            self.isCustomised = isCustomised
        } else {
            self.isCustomised = false
        }
        
        if let bgColor = dict[constant_bgColor] as? String {
            self.bgColor = bgColor
        } else {
            self.bgColor = ""
        }
        
        if let htmlUrl = dict[constant_htmlUrl] as? String {
            if self.isCustomised ?? false {
               self.htmlUrl = htmlUrl
            }
        }
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? LeapIconSetting {
            return self.leftAlign == object.leftAlign && self.dismissible == object.dismissible && self.isCustomised == object.isCustomised && self.bgColor == object.bgColor && self.htmlUrl == object.htmlUrl
        }
        return false
    }
}
