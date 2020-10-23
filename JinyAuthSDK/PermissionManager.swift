//
//  PermissionManager.swift
//  JinyAuthSDK
//
//  Created by Shreyansh Sharma on 20/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit


class PermissionManager{
    
    let ALFRED_URL_LOCAL: String = "http://192.168.1.3:8080";
    let ALFRED_URL_DEV: String = "https://alfred-dev-0-0-1-gke.jiny.io";
    let API_KEY: String = "626085ff-35d6-4779-bb12-6b6da2eb8838";
    var permissionListener: PermissionListener
    var application: UIApplication
    let permissionGranted: String = "PERMISSION_GRANTED"
    let permissionRejected: String = "PERMISSION_REJECTED"
    
    init(application: UIApplication, permissionListener: PermissionListener){
        self.permissionListener = permissionListener
        self.application = application
    }
    
    //call start in MasterManager
    func start()->Void{
        //seek permission to allow communication to take place
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Streaming Permission ", message: "Do you allow your device to stream to Jiny's dashboard", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            
                // update the Alfred server that permission has been granted
                self.permissionListener.onPermissionGranted(permission: self.permissionGranted, status: true)
                
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler:{ (action) in
                self.permissionListener.onPermissionRejected(permnission: self.permissionRejected)
            }))

            
           // UIApplication.shared.keyWindow!.rootViewController?.present(alert, animated: true)
            UIApplication.getCurrentVC()?.present(alert, animated: true)
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
        
        let beaconDiscoveryUrl: URL = URL(string: "\(ALFRED_URL_DEV)/alfred/api/v1/apps/\(Constants.API_KEY)/device/\(appId)")!

        var urlRequest: URLRequest = URLRequest(url: beaconDiscoveryUrl)
        urlRequest.addValue(Constants.API_KEY , forHTTPHeaderField: "x-auth-id")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "PUT"
        
        let json: [String: String] = [
            "permissionStatus" : "\(permission)"
        ]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed)
        urlRequest.httpBody = jsonData
    
        let permissionUpdateStatus = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let response = response {
                print(response)
            }
            
            if let data = data {
                self.permissionListener.onPermissionStatusUpdation(permission: permission)
            }
        }.resume()
        
    }
    func stop()->Void{
        
    }
}

protocol PermissionListener{
    func onPermissionGranted(permission: String, status: Bool)->Void
    func onPermissionRejected(permnission: String)->Void
    func onPermissionStatusUpdation(permission: String)->Void
}

