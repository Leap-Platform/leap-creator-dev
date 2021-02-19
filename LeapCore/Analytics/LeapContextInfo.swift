//
//  LeapContextInfo.swift
//  LeapCore
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation


class LeapContextInfo:Codable {
    
    var flow_info:LeapFlowInfo
    var page_info:LeapPageInfo?
    var stage_info:LeapStageInfo?
    
    init(flow:LeapFlow, subFlow:LeapFlow?, page:LeapPage?, stage:LeapStage?) {
        flow_info = LeapFlowInfo(flow: flow, subFlow: subFlow)
        if let pageData = page { page_info = LeapPageInfo(page: pageData) }
        if let stageData = stage { stage_info = LeapStageInfo(stage: stageData) }
        
    }
    
}
