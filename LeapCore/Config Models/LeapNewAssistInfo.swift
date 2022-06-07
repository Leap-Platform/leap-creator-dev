//
//  LeapNewAssistInfo.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 15/12/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

struct LeapNewAssistInfo: Codable {
    
    let type: String?
    let highlightClickable, focus: Bool?
    let identifier: String?
    let layoutInfo: LeapNewLayoutInfo?
    let autoDismissDelay: Int?
    let accessibilityText: String?
    let isWeb: Bool?
    let htmlURL: String?
    let highlightAnchor: Bool?
    let contentUrls: [String]?
    let extraProps: LeapNewExtraProps?
    
    enum CodingKeys: String, CodingKey {
        case type, highlightClickable, focus, identifier, layoutInfo
        case htmlURL = "htmlUrl"
        case contentUrls, accessibilityText, extraProps, isWeb, autoDismissDelay, highlightAnchor
    }
}

struct LeapNewExtraProps: Codable {
    
    let highlightCornerRadius: String?
    let animateHighlight: String?
    let tooltipType: String?
    let highlightType: String?
}
