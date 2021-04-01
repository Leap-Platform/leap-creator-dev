//
//  LeapProjectParameters.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 28/03/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

class LeapProjectParameters: NSObject, Codable {
    
    var deploymentType: String?
    var deploymentId: String?
    var deploymentName: String?
    var projectName: String?
    var projectId: String?
    var flowId: Int?
    
    init(withDict paramDict: Dictionary<String, Any>) {
        
        if let deploymentType = paramDict["deploymentType"] as? String {
            self.deploymentType = deploymentType
        }
        if let deploymentId = paramDict["deploymentId"] as? String {
            self.deploymentId = deploymentId
        }
        if let deploymentName = paramDict["deploymentName"] as? String {
            self.deploymentName = deploymentName
        }
        if let projectName = paramDict["projectName"] as? String {
            self.projectName = projectName
        }
        if let projectId = paramDict["projectId"] as? String {
            self.projectId = projectId
        }
    }
}
