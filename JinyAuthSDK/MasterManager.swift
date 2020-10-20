//
//  MasterManager.swift
//  JinyAuthSDK
//
//  Created by Shreyansh Sharma on 20/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class MasterManager: ProtocolListener, PermissionListener, BeaconListener, AppIdListener {
    
    func onIdFound() -> String {
        return ""
    }
    
    var apiKey: String?
    var application: UIApplication
    var beaconManager: BeaconManager?
    var appIdManager: AppIdManager?
    var permissionManager: PermissionManager?
    var protocolManager: ProtocolManager?
    
    
    init(application: UIApplication, key: String) {
        self.apiKey = key
        self.application = application
    }
    
    func initialiseComponents(){
        appIdManager = AppIdManager(appIdListener: self, applicationcontext: application)
        beaconManager = BeaconManager(beaconListener: self)
        permissionManager = PermissionManager(permissionListener: self)
        protocolManager = ProtocolManager(protocolListener: self)
    }
    
    func start(){
        let appId = "Sample device id"
        beaconManager?.start(appId: appId)
    }
}

