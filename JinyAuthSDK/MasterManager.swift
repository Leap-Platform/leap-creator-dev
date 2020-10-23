//
//  MasterManager.swift
//  JinyAuthSDK
//
//  Created by Shreyansh Sharma on 20/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class MasterManager: ProtocolListener, PermissionListener, BeaconListener, AppIdListener {
    func onBeaconSuccess(roomId: String, status: Any) {
        print("Room is \(roomId)")
        print("Status is \(status)")
        
        let roomStatus: String! = String(describing: status)
        // contains needs to change, it should be equals
        if roomStatus.contains(PERMISSION_NEEDED) {
            beaconManager?.stop()
            permissionManager?.start()
        }
    }
    
    func onPermissionStatusUpdation(permission: String) {
        if permission == PERMISSION_GRANTED {
            self.protocolManager?.start(roomId: (self.beaconManager?.roomId) as! String)
        }else{
            print(permission)
        }
    }
    
   
    func onPermissionGranted(permission: String, status: Bool) {
        self.permissionManager?.updatePermissionStatus(permission: PERMISSION_GRANTED, status: status, appId: self.appId!)
    }
    
    func onPermissionRejected(permnission: String) {
        self.permissionManager?.updatePermissionStatus(permission: PERMISSION_REJECTED, appId: self.appId!)
    }
    
    func onBeaconFailure() {
    }
    
    
    func onIdFound() -> String {
        return ""
    }
    
   
    var apiKey: String?
    var application: UIApplication
    var beaconManager: BeaconManager?
    var appIdManager: AppIdManager?
    var permissionManager: PermissionManager?
    var protocolManager: ProtocolManager?
    let PERMISSION_NEEDED: String = "PERMISSION_NEEDED"
    let PERMISSION_REJECTED: String = "REJECTED"
    let PERMISSION_GRANTED: String = "GRANTED"
    var appId: String?
    
    
    init(application: UIApplication, key: String) {
        self.apiKey = key
        self.application = application
    }
    
    func initialiseComponents(){
        appIdManager = AppIdManager(appIdListener: self, applicationcontext: application)
        beaconManager = BeaconManager(beaconListener: self)
        permissionManager = PermissionManager(application: self.application, permissionListener: self)
        protocolManager = ProtocolManager(protocolListener: self, context: application)
        protocolManager?.setup()
    }
    
    func start(){
        self.appId = "7da70a20-7bfa-4b34-8f79-fa20d30c2d8e"
        beaconManager?.start(appId: self.appId!)
    }
    
    
}

