//
//  LeapMasterManager.swift
//  LeapCreator
//
//  Created by Shreyansh Sharma on 20/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import UIKit

class LeapMasterManager: LeapProtocolListener,
                     LeapPermissionListener,
                     LeapBeaconListener,
                     LeapAppIdListener {
   
    //Protocol Listener
    func onSessionClosed() {
        // sessiontime out
        //send a toast message on screen and start beacons
        guard let appId = self.appId else { return }
        self.beaconManager?.start(appId: appId)
    }
    
    
    //Beacon Listeners
    func onBeaconSuccess(roomId: String, status: Any) {

//        let roomStatus = String(describing: status)
//        // contains needs to change, it should be equals
//        if roomStatus.contains(PERMISSION_NEEDED) {
//            beaconManager?.stop()
//            permissionManager?.start()
//        }
    }
    
    func onBeaconFailure() {
    }
    
    // Permission Listeners
    func onPermissionStatusUpdation(permission: String) {
//        if permission == PERMISSION_GRANTED {
//            guard let roomId = self.beaconManager?.roomId else { return }
//            self.protocolManager?.start(roomId: roomId)
//        } else {
//            guard let appId = self.appId else { return }
//            self.beaconManager?.start(appId: appId)
//        }
    }
    
   //Beacon Listeners
    func onPermissionGranted(permission: String, status: Bool) {
        guard let appId = self.appId else { return }
        self.permissionManager?.updatePermissionStatus(permission: PERMISSION_GRANTED, status: status, appId: appId)
    }
    
    func onPermissionRejected(permnission: String) {
        guard let appId = self.appId else { return }
        self.permissionManager?.updatePermissionStatus(permission: PERMISSION_REJECTED, appId: appId)
    }

    // App ID fetch Listeners
    func onIdFound() -> String? {
        return appIdManager?.appStoreId
    }
    
   //local variables
    var apiKey: String?
    var application: UIApplication
    var beaconManager: LeapBeaconManager?
    var appIdManager: LeapAppIdManager?
    var permissionManager: LeapPermissionManager?
    var protocolManager: LeapProtocolManager?
    let PERMISSION_NEEDED: String = "PERMISSION_NEEDED"
    let PERMISSION_REJECTED: String = "REJECTED"
    let PERMISSION_GRANTED: String = "GRANTED"
    var appId: String?
    
    init(key: String) {
        self.apiKey = key
        self.application = UIApplication.shared
        addObservers()
    }
    
    func initialiseComponents(){
        appIdManager = LeapAppIdManager(appIdListener: self)
        beaconManager = LeapBeaconManager(beaconListener: self)
        permissionManager = LeapPermissionManager(permissionListener: self)
        protocolManager = LeapProtocolManager(protocolListener: self)
        protocolManager?.setup()
    }
    
    @objc func start(){
        self.appId = LeapCreatorShared.shared.apiKey
        guard let appId = self.appId else { return }
        beaconManager?.start(appId: appId)
    }
    
    @objc func onPaired(notification: NSNotification) {
        NotificationCenter.default.post(name: .init(rawValue: "leap_creator_live"), object: nil)
        guard let roomDict = notification.object as? Dictionary<String, Any> else { return }
        guard let roomId = roomDict[constant_roomId] as? String else { return }
        self.protocolManager?.start(roomId: roomId)
    }
    
    @objc func disconnect() {
        self.protocolManager?.onSessionClosed()
    }
}

extension LeapMasterManager{
    
    private func addObservers() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(appLaunched), name: UIApplication.didFinishLaunchingNotification, object: nil)
        nc.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
        nc.addObserver(self, selector: #selector(start), name: .init("leap_end_preview"), object: nil)
        nc.addObserver(self, selector: #selector(onPaired(notification:)), name: .init("onPaired"), object: nil)
        nc.addObserver(self, selector: #selector(disconnect), name: .init("Creator_Disconnect"), object: nil)
    }
    
    @objc private func appLaunched(){
    }
    
    @objc private func appWillEnterForeground(){
        self.permissionManager = LeapPermissionManager(permissionListener: self)
        self.protocolManager?.onApplicationInForeground()
    }
    
    @objc private func appDidEnterBackground(){
        self.protocolManager?.onApplicationInBackground()
    }
    
    @objc private func appWillTerminate(){
        self.protocolManager?.onApplicationInTermination()
    }
    
}

extension UIViewController {

func showToast(message : String) {

    let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
       toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
       toastLabel.textColor = UIColor.white
       toastLabel.textAlignment = .center;
       toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
       toastLabel.text = message
       toastLabel.alpha = 1.0
       toastLabel.layer.cornerRadius = 10;
       toastLabel.clipsToBounds  =  true
       self.view.addSubview(toastLabel)
       UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
           toastLabel.alpha = 0.0
       }, completion: {(isCompleted) in
           toastLabel.removeFromSuperview()
       })
} }
