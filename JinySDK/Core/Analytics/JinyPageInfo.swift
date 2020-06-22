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
    var page_type:String
    var client_activity_name:String
    
    init(page:JinyPage) {
        page_id = String(page.pageId)
        page_name = String(page.pageName)
        page_type = page.pageType.rawValue
        if let currentVC = UIApplication.getCurrentVC() { client_activity_name = String(describing: type(of: currentVC)) }
        else { client_activity_name = "" }
    }
    
}
