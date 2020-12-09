//
//  JinyIconSetting.swift
//  JinySDK
//
//  Created by Ajay S on 02/12/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

public class IconSetting {
    
    public var dragEnabled: Bool?
    public var dismissible: Bool?
    public var leftAlign: Bool?
    private var isCustomised: Bool?
    public var bgColor: String?
    public var htmlUrl: String? //can also be base64
    public var contentUrls: [String]?
    
    init(with dict: Dictionary<String, Any>) {
        
        if let dragEnabled = dict["dragEnabled"] as? Bool {
            self.dragEnabled = dragEnabled
        } else {
            self.dragEnabled = false
        }
        
        if let dismissible = dict["dismissible"] as? Bool {
            self.dismissible = dismissible
        } else {
            self.dismissible = false
        }
        
        if let leftAlign = dict["leftAlign"] as? Bool {
            self.leftAlign = leftAlign
        } else {
            self.leftAlign = false
        }
        
        if let isCustomised = dict["isCustomised"] as? Bool {
            self.isCustomised = isCustomised
        } else {
            self.isCustomised = false
        }
        
        if let bgColor = dict["bgColor"] as? String {
            self.bgColor = bgColor
        } else {
            self.bgColor = ""
        }
        
        if let htmlUrl = dict["htmlUrl"] as? String {
            self.htmlUrl = htmlUrl
        }
        
        if let contentUrls = dict["content"] as? [String] {
            self.contentUrls = contentUrls
        }
    }
}
