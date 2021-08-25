//
//  FlowMenuInfo.swift
//  LeapSDK
//
//  Created by Ajay S on 18/08/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

class LeapFlowMenuInfo: NSObject, Codable {
    
    var language: String?
    
    var projects: [LeapFlowCompletedInfo] = []
    
    init(with completedFlowsInfo: Dictionary<String, Bool>) {
        
        self.language = LeapPreferences.shared.getUserLanguage()
        
        for (key, value) in completedFlowsInfo {
            let flowCompletedInfo = LeapFlowCompletedInfo(id: key, completed: value)
            projects.append(flowCompletedInfo)
        }
    }
}

class LeapFlowCompletedInfo: Codable {
    
    var id: String?
    
    var completed: Bool?
    
    init(id: String, completed: Bool) {
        self.id = id
        self.completed = completed
    }
}
