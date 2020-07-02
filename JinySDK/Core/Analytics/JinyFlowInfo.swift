//
//  JinyFlowInfo.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation


class JinyFlowInfo:Codable {
    
    var flow_id:String
    var flow_name:String
    var is_branch:Bool
    var branch_flow_id:String?
    var branch_flow_name:String?
    
    init(flow:JinyFlow, subFlow:JinyFlow?) {
        flow_id = String(flow.id!)
        flow_name = flow.name!
        guard let branchFlow = subFlow else {
            is_branch = false
            return
        }
        is_branch = true
        branch_flow_id = String(branchFlow.id!)
        branch_flow_name = branchFlow.name!
    }
    
}
