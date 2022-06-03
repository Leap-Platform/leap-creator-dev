//
//  LeapBeaconManager.swift
//  LeapCreator
//
//  Created by Shreyansh Sharma on 20/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

protocol LeapBeaconListener: AnyObject {
    func onBeaconSuccess(roomId: String, status: Any)
    func onBeaconFailure()
}

class LeapBeaconManager {
    
    let json: String? = {
        guard let apiKey = LeapCreatorShared.shared.apiKey else { return nil }
        let info: Dictionary<String,String> = [
            "id"                    : "\(apiKey)",
            "name"                  : UIDevice.current.name,
            "type"                  : "IOS",
            "appApiKey"             : "\(apiKey)",
            "model"                 : "\(UIDevice.current.model)",
            "osVersion"             : UIDevice.current.systemVersion,
            "height"                : "\(UIScreen.main.bounds.height)",
            "width"                 : "\(UIScreen.main.bounds.width)",
            "appVersionCode"        : (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "Empty",
            "appVesionName "        : (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "Empty",
            "status"                : "AVAILABLE",
            "authToolsVersionName"  : (Bundle(for: LeapBeaconManager.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "Empty",
            "authToolsVersionCode"  : (Bundle(for: LeapBeaconManager.self).object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "Empty",
            "deviceType"            : UIDevice.current.userInterfaceIdiom == .pad ? constant_TABLET : constant_PHONE
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: info, options: .fragmentsAllowed),
              let json = String(data: data, encoding: .utf8) else { return "{}" }
        return json
    }()
    
    weak var beaconListener: LeapBeaconListener?
    var appId: String?
    var status: String?
    let interval: TimeInterval = (LeapCreatorShared.shared.creatorConfig?.beacon?.interval ?? 3000)/1000
    
    private var sendFirstBeacon: Bool?
    
    init(beaconListener: LeapBeaconListener) {
        self.beaconListener = beaconListener
        NotificationCenter.default.addObserver(self, selector: #selector(internetConnected), name: NSNotification.Name(rawValue: constant_internetConnected), object: nil)
    }
    
    func start(appId: String){
        self.appId = appId
        startBeacons()
    }
    
    private func startBeacons(){
        DispatchQueue.global().async {
            self.sendFirstDiscoveryBeacon()
        }
    }
    
    private func sendFirstDiscoveryBeacon() {
        //Do first network call to POST device metric
        guard let beaconDiscoveryUrl: URL = URL(string: "\(LeapCreatorShared.shared.ALFRED_URL)/alfred/api/v1/device/beacon") else { return }

        var urlRequest: URLRequest = URLRequest(url: beaconDiscoveryUrl)
        guard let apiKey = LeapCreatorShared.shared.apiKey else { return }
        urlRequest.addValue(apiKey, forHTTPHeaderField: "x-auth-id")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        guard let json = json else { return }
        let jsonData = Data(json.utf8)
        urlRequest.httpBody = jsonData
        sendFirstBeacon = false
        let discoveryTask = URLSession.shared.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            if let data = data {
                _ = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                self?.sendFirstBeacon = true
            }
        }
        discoveryTask.resume()
    }
    
    @objc func internetConnected() {
        
        guard sendFirstBeacon != nil else {
            
            return
        }
        
        if !(sendFirstBeacon ?? false) {
            guard let appId = self.appId else { return }
            start(appId: appId)
        }
    }
}

class LeapRoomManager {
                
    func validateRoomId(roomId: String, completion: @escaping SuccessCallBack) {
        guard let validateRoomID: URL = URL(string: LeapCreatorShared.shared.ALFRED_URL+LeapCreatorShared.shared.VALIDATE_ROOMID_ENDPOINT+roomId) else { return }
        var urlRequest: URLRequest = URLRequest(url: validateRoomID)
        guard let apiKey = LeapCreatorShared.shared.apiKey else { return }
        urlRequest.addValue(apiKey , forHTTPHeaderField: "x-auth-id")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "GET"
    
        let validateTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                let status = httpResponse.statusCode
                switch status {
                case 200: completion(true)
                default: completion(false)
                }
            }
        }
        validateTask.resume()
    }
}
