//
//  PermissionManager.swift
//  JinyAuthSDK
//
//  Created by Shreyansh Sharma on 20/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit


class PermissionManager: AppStateProtocol{
    func onApplicationInForeground() {
        
    }
    
    func onApplicationInBackground() {
        
    }
    
    func onApplicationInTermination() {
        
    }
    
    
    let ALFRED_URL_LOCAL: String = "http://192.168.1.3:8080";
    let ALFRED_URL_DEV: String = "https://alfred-dev-0-0-1-gke.jiny.io";
    var permissionListener: PermissionListener
    var application: UIApplication
    let permissionGranted: String = "PERMISSION_GRANTED"
    let permissionRejected: String = "PERMISSION_REJECTED"
    private var permissionTimer: Timer?
    let timeout: TimeInterval = (JinyAuthShared.shared.authConfig?.permission?.timeOutDuration ?? 15000)/1000
    private var permissionAlert: UIAlertController?
    
    init(permissionListener: PermissionListener){
        self.permissionListener = permissionListener
        self.application = UIApplication.shared
        addObservers()
    }
    
    //call start in MasterManager
    func start()->Void{
        //seek permission to allow communication to take place
        
        DispatchQueue.main.async {
                        
            self.permissionTimer = Timer.scheduledTimer(timeInterval: self.timeout, target: self, selector: #selector(self.permissionDenied), userInfo: nil, repeats: false)
            
            self.permissionAlert = UIAlertController(title: JinyAuthShared.shared.authConfig?.permission?.dialogTitle ?? "Streaming Permission ", message: JinyAuthShared.shared.authConfig?.permission?.dialogDescription ?? "Do you permit Jiny Dashboard to stream your screen ?", preferredStyle: .alert)

            self.permissionAlert?.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            
                self.permissionTimer?.invalidate()
                self.permissionTimer = nil
                // update the Alfred server that permission has been granted
                self.permissionListener.onPermissionGranted(permission: self.permissionGranted, status: true)
                
            }))
            self.permissionAlert?.addAction(UIAlertAction(title: "No", style: .cancel, handler:{ (action) in
                 self.permissionDenied()
            }))

            
           // UIApplication.shared.keyWindow!.rootViewController?.present(alert, animated: true)
            UIApplication.getCurrentVC()?.present(self.permissionAlert!, animated: true)
        }
        
    }
    
    func updatePermissionStatus(permission: String, appId: String){
        self.updatePermissionStatus(permission: permission, status: false, appId: appId)
    }
    
    func updatePermissionStatus(permission: String, status: Bool, appId: String){
        updatePermissionToServer(permission: permission, status: status, appId: appId)
    }
    
    //Update the permission action to Alfred Server by POST
    func updatePermissionToServer(permission: String, status:Bool, appId: String){
        
        let beaconDiscoveryUrl: URL = URL(string: "\(ALFRED_URL_DEV)/alfred/api/v1/apps/\(JinyAuthShared.shared.apiKey!)/device/\(appId)")!

        var urlRequest: URLRequest = URLRequest(url: beaconDiscoveryUrl)
        urlRequest.addValue(JinyAuthShared.shared.apiKey! , forHTTPHeaderField: "x-auth-id")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "PUT"
  
        let json = "{ \"permissionStatus\": \"\(permission)\"}"
        let data = Data(json.utf8)
       // let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed)
        urlRequest.httpBody = data
    
        let _: Void = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let response = response {
                print(response)
            }
            
            if data != nil {
                self.permissionListener.onPermissionStatusUpdation(permission: permission)
            }
        }.resume()
        
    }
    func stop()->Void{
        
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc private func appDidEnterBackground(){
        permissionDenied()
    }
    
    @objc private func permissionDenied() {
        guard permissionTimer != nil else { return }
        permissionTimer?.invalidate()
        permissionTimer = nil
        self.permissionAlert?.dismiss(animated: true, completion: nil)
        self.permissionListener.onPermissionRejected(permnission: self.permissionRejected)
    }
}

protocol PermissionListener{
    func onPermissionGranted(permission: String, status: Bool)->Void
    func onPermissionRejected(permnission: String)->Void
    func onPermissionStatusUpdation(permission: String)->Void
}

