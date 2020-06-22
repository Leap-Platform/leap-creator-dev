//
//  JinyStageInfo.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyStageInfo:Codable {
    var stage_id:String
    var stage_name:String
    var stage_type:String
    var is_success:Bool
    
    init(stage:JinyStage) {
        stage_id = String(stage.stageId)
        stage_name = stage.stageName
        stage_type = stage.stageType.rawValue
        is_success = stage.isSuccess
    }
    
}
