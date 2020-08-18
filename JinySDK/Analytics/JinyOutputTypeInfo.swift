//
//  JinyOutputTypeInfo.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyOutputTypeInfo:Codable {
    
    var normal_pointer_type:Bool
    var negative_pointer_type:Bool
    var jiny_arrow_clicked:Bool
    var pointer_type:String
    
    init() {
        normal_pointer_type = false
        negative_pointer_type = false
        jiny_arrow_clicked = false
        pointer_type = "NORMAL"
    }
    
}
