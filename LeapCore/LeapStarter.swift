//
//  LeapStarter.swift
//  LeapCore
//
//  Created by Aravind GS on 17/03/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

// MARK: - LEAPSTARTER CLASS
class LeapStarter: NSObject {
    
    private let contextManager: LeapContextManager
        
    private let configManager: LeapConfigManager
    
    init(_ token : String, uiManager: LeapAUIHandler?) {
        self.configManager = LeapConfigManager(with: LeapProjectManager(), configRepo: LeapConfigRepository(with: LeapRemoteConfigHandler(token: token)))
        self.contextManager = LeapContextManager(with: uiManager, configManager: self.configManager)
        super.init()
        LeapSharedInformation.shared.setAPIKey(token)
        LeapSharedInformation.shared.setSessionId()
        self.getConfigForDetection()
    }
    
    func auiCallback() -> LeapAUICallback? {
        return self.contextManager
    }
    
    func getConfigForDetection() {
        configManager.getConfig(projectId: nil, completion: { [weak self] _ in
            DispatchQueue.main.async {
                self?.contextManager.initializeLeapEngine()
            }
        })
    }
    
    func startProject(projectId: String, resetProject: Bool, isEmbedProject: Bool) {
        self.configManager.startProject(projectId: projectId, resetProject: resetProject, isEmbedProject: isEmbedProject)
    }
}
