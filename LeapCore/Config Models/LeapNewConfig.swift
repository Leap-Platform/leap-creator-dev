//
//  LeapNewConfig.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 16/12/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

struct LeapNewConfig: Codable {
    
    let projectParameters: LeapNewProjectParameters?
    let assists: [LeapNewAssist]?
    let languages: [LeapNewLanguage]?
    let discoverySounds: LeapNewDiscoverySounds?
    let localeSounds: LeapNewLocaleSounds?
    let discoveryList: [LeapNewDiscovery]?
    let nativeIdentifiers: [String : LeapNewNativeIdentifier]?
    let webIdentifiers: [String : LeapNewWebIdentifier]?
    let webViewList: [LeapNewWebView]?
    let flows: [LeapNewFlow]?
    let auiContent: LeapNewAUIContent?
    let iconSetting: [String : LeapNewIconSetting]?
    let defaultAccessibilityText: LeapNewDefaultAccessibilityText?
    let connectedProjects: [LeapNewConnectedProject]?
}
