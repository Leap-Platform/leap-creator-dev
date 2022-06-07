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
    var deploymentVersion: String?
    var projectId: String?
    var projectType: String?
    var id: Int?
    var isEmbed: Bool = false
    var isEnabled: Bool = false
    
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
        if let deploymentVersion = paramDict["deploymentVersion"] as? String {
            self.deploymentVersion = deploymentVersion
        }
        if let projectName = paramDict["projectName"] as? String {
            self.projectName = projectName
        }
        if let projectId = paramDict["projectId"] as? String {
            self.projectId = projectId
        }
        if let projectType = paramDict["projectType"] as? String {
            self.projectType = projectType
        }
    }
    
    func setEnabled(enabled:Bool) {
        isEnabled = enabled
    }
    
    func setEmbed(embed:Bool) {
        isEmbed = embed
    }
    
    func getIsEnabled() -> Bool {
        return isEnabled
    }
    
    func getIsEmbed() -> Bool {
        return isEmbed
    }
    
}
