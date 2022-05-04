//
//  LeapNewLayoutInfo.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 15/12/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

struct LeapNewLayoutInfo: Codable {
    
    let alignment: String?
    let style: LeapNewStyle?
    let dismissAction: LeapNewDismissAction?
}

struct LeapNewStyle: Codable {
    
    let bgColor: String?
    let maxWidth: Int?
    let strokeWidth: Int?
    let strokeColor: String?
}

struct LeapNewDismissAction: Codable {
    
    let outsideDismiss: Bool?
    let dismissOnAnchorClick: Bool?
}
