//
//  LeapStageInfo.swift
//  LeapCore
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class LeapStageInfo:Codable {
    var stage_id:String
    var stage_name:String
    var stage_type:String
    var is_success:Bool
    var checkpoint:Bool
    
    init(stage:LeapStage) {
        stage_id = String(stage.id)
        stage_name = stage.name
        stage_type = stage.type.rawValue
        is_success = stage.isSuccess
        checkpoint = stage.checkpoint
    }
    
}
