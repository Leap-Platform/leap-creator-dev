//
//  JinyPageInfo.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

class JinyPageInfo:Codable {
    
    var page_id:String
    var page_name:String
    var is_web:Bool
    var is_success:Bool
    var checkpoint:Bool
    
    init(page:JinyPage) {
        page_id = String(page.id)
        page_name = page.name
        is_success = false
        is_web = page.isWeb
        checkpoint = page.checkpoint
    }
    
}
