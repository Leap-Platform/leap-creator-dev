//
//  JinyContextTypeInfo.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation


class JinyContextTypeInfo:Codable {
    
    var flow_info:JinyFlowInfo
    var page_info:JinyPageInfo
    var stage_info:JinyStageInfo
    
    init(flow:JinyFlow, subFlow:JinyFlow?, page:JinyPage, stage:JinyStage) {
        flow_info = JinyFlowInfo(flow: flow, subFlow: subFlow)
        page_info = JinyPageInfo(page: page)
        stage_info = JinyStageInfo(stage: stage)
    }
    
}
