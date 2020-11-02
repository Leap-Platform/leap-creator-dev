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
    var client_activity_name:String
    var checkpoint:Bool
    
    init(page:JinyPage) {
        page_id = String(page.id!)
        page_name = String(page.name!)
        if let currentVC = UIApplication.getCurrentVC() { client_activity_name = String(describing: type(of: currentVC)) }
        else { client_activity_name = "" }
        checkpoint = page.checkpoint
    }
    
}
