//
//  LeapProjectManager.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 11/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation

class LeapProjectManager {
    
    private var fetchedProjectIds: Array<String> = []
    private var currentEmbeddedProjectId: String?
    
    func resetCurrentEmbeddedProjectId() {
        currentEmbeddedProjectId = nil
    }
    
    func getCurrentEmbeddedProjectId() -> String? {
        return currentEmbeddedProjectId
    }
    
    func getFetchedProjectIds() -> [String] {
        return fetchedProjectIds
    }
    
    func appendProjectId(projectId: String) { 
        fetchedProjectIds.append(projectId)
    }
}
