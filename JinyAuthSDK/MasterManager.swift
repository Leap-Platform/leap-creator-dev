//
//  MasterManager.swift
//  JinyAuthSDK
//
//  Created by Shreyansh Sharma on 20/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class MasterManager: ProtocolListener,
                     PermissionListener,
                     BeaconListener,
                     AppIdListener {
   
    //Protocol Listener
    func onSessionClosed() {
        
    }
    
    
    //Beacon Listeners
    func onBeaconSuccess(roomId: String, status: Any) {

        let roomStatus: String! = String(describing: status)
        // contains needs to change, it should be equals
        if roomStatus.contains(PERMISSION_NEEDED) {
            beaconManager?.stop()
            permissionManager?.start()
        }
    }
    
    // Permission Listeners
    func onPermissionStatusUpdation(permission: String) {
        if permission == PERMISSION_GRANTED {
            self.protocolManager?.start(roomId: (self.beaconManager?.roomId) as! String)
        }else{
            print(permission)
        }
    }
    
   //Beacon Listeners
    func onPermissionGranted(permission: String, status: Bool) {
        self.permissionManager?.updatePermissionStatus(permission: PERMISSION_GRANTED, status: status, appId: self.appId!)
    }
    
    func onPermissionRejected(permnission: String) {
        self.permissionManager?.updatePermissionStatus(permission: PERMISSION_REJECTED, appId: self.appId!)
    }
    
    func onBeaconFailure() {
    }
    
    
    // App ID fetch Listeners
    func onIdFound() -> String {
        return (appIdManager?.appStoreId)!
    }
    
   //local variables
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
        addObservers()
    }
    
    func initialiseComponents(){
        appIdManager = AppIdManager(appIdListener: self, applicationcontext: application)
        beaconManager = BeaconManager(beaconListener: self)
        permissionManager = PermissionManager(application: self.application, permissionListener: self)
        protocolManager = ProtocolManager(protocolListener: self, context: application)
        protocolManager?.setup()
    }
    
    func start(){
        self.appId = Constants.API_KEY
        beaconManager?.start(appId: self.appId!)
    }
    
    
}

extension MasterManager{
    
    private func addObservers() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(appLaunched), name: UIApplication.didFinishLaunchingNotification, object: nil)
        nc.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    @objc private func appLaunched(){
    }
    
    @objc private func appWillEnterForeground(){
        self.permissionManager = PermissionManager(application: UIApplication.shared, permissionListener: self)
        self.protocolManager?.onApplicationInForeground()
    }
    
    @objc private func appDidEnterBackground(){
        self.protocolManager?.onApplicationInBackground()
    }
    
    @objc private func appWillTerminate(){
        self.protocolManager?.onApplicationInTermination()
    }
    
}
