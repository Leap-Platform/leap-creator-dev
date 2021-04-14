//
//  LeapFlowInfo.swift
//  LeapCore
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation


class LeapFlowInfo:Codable {
    
    var flow_id:String?
    var flow_name:String?
    var is_branch:Bool?
    var branch_flow_id:String?
    var branch_flow_name:String?
    
    init(flow:LeapFlow, subFlow:LeapFlow?) {
        guard let flowId = flow.id, let flowName = flow.name else {
            print("No Flow Id or Flow Name")
            return
        }
        flow_id = String(flowId)
        flow_name = flowName
        guard let branchFlow = subFlow else {
            is_branch = false
            return
        }
        is_branch = true
        guard let branchFlowId = branchFlow.id, let branchFlowName = branchFlow.name else {
            print("No Sub Flow Id or Sub Flow Name")
            return
        }
        branch_flow_id = String(branchFlowId)
        branch_flow_name = branchFlowName
    }
}
