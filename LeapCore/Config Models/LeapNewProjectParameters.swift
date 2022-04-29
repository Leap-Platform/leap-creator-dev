//
//  LeapNewProjectParameters.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 16/12/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

struct LeapNewProjectParameters: Codable {
    
    let deploymentID: String?
    let deploymentVersion: String?
    let deploymentType: String?
    let deploymentName: String?
    let projectName: String?
    let projectID: String?
    let projectType: String?
    
    enum CodingKeys: String, CodingKey {
        case deploymentType, deploymentVersion
        case deploymentID = "deploymentId"
        case projectType, deploymentName, projectName
        case projectID = "projectId"
    }
}
