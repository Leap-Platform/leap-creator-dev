//
//  LeapBeaconManager.swift
//  LeapCreator
//
//  Created by Shreyansh Sharma on 20/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

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
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: info, options: .fragmentsAllowed),
              let json = String(data: data, encoding: .utf8) else { return "{}" }
        return json
    }()
    
    var beaconListener: LeapBeaconListener
    var appId: String?
    var roomId: String
    var status: String?
    var task: DispatchWorkItem?
    let interval: TimeInterval = (LeapCreatorShared.shared.creatorConfig?.beacon?.interval ?? 3000)/1000
    
    private var sendFirstBeacon: Bool?
        
    var roomID: String? {
        get{
            return roomId
        }
    }
    
    init(beaconListener: LeapBeaconListener) {
        self.beaconListener = beaconListener
        self.roomId = ""
        NotificationCenter.default.addObserver(self, selector: #selector(internetConnected), name: NSNotification.Name(rawValue: "internetConnected"), object: nil)
    }
    
    deinit {
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "internetConnected"), object: nil)
    }
    
    func start(appId: String){
        self.appId = appId
        self.task = DispatchWorkItem{self.sendSubsequentBeacons()}
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
        let discoveryTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let data = data {
                _ = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                self.sendFirstBeacon = true
                self.sendSubsequentBeacons()
            }
        }
        discoveryTask.resume()
    }
    
    func sendSubsequentBeacons() {
        guard let beaconDiscoveryUrl: URL = URL(string: "\(LeapCreatorShared.shared.ALFRED_URL)/alfred/api/v1/device/beacon") else { return }
        var urlRequest: URLRequest = URLRequest(url: beaconDiscoveryUrl)
        guard let apiKey = LeapCreatorShared.shared.apiKey else { return }
        urlRequest.addValue(apiKey , forHTTPHeaderField: "x-auth-id")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "PUT"
        guard let json = json else { return }
        let jsonData = Data(json.utf8)
        urlRequest.httpBody = jsonData
    
        let discoveryTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let data = data {
                let jsonData = try? JSONSerialization.jsonObject(with: data,  options: []) as? [String: Any]
                //fetch the status and room info from the json
                guard let roomId = (jsonData?[constant_roomId]) as? String else { return }
                self.roomId = roomId
                guard let status = jsonData?[constant_status] else { return }
                self.beaconListener.onBeaconSuccess(roomId: self.roomId, status: status as Any)
                //repeat this api call every 'm' seconds
                guard let task = self.task else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + self.interval, execute: task)
            }
        }
        discoveryTask.resume()
    }

    /*
     Stop the beacon manager to stop sending the beacons once the connection is active
     */
    func stop()->Void {
        self.task?.cancel()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "internetConnected"), object: nil)
    }
    
    @objc func internetConnected() {
        
        guard sendFirstBeacon != nil else {
            
            return
        }
        
        if (sendFirstBeacon ?? false) {
            
            sendSubsequentBeacons()
        
        } else {
            guard let appId = self.appId else { return }
            start(appId: appId)
        }
    }
}

protocol LeapBeaconListener{
    func onBeaconSuccess(roomId: String, status: Any)->Void
    func onBeaconFailure()->Void
}
