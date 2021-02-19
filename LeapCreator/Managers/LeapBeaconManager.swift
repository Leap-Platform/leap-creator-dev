//
//  LeapBeaconManager.swift
//  LeapCreator
//
//  Created by Shreyansh Sharma on 20/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation

class LeapBeaconManager {
    private let ALFRED_URL_LOCAL: String  = "http://192.168.1.3:8080"
    private let ALFRED_URL_DEV: String = "https://alfred-dev-gke.leap.is"
    
    let json = "{\"id\":\"\(LeapCreatorShared.shared.apiKey!)\",\"name\":\"iPhone\",\"type\":\"IOS\",\"appApiKey\":\"\(LeapCreatorShared.shared.apiKey!)\",\"model\" :\"iPhone11\",\"osVersion\" : \"10.3\",\"height\" : \"2280\",\"width\" : \"1080\",\"appVersionCode\" : \"90\",\"appVersionName\" : \"2.0.2\",\"authToolVersionCode\" :\"10\",\"authToolVersionName\" : \"4.0.1\",\"status\":\"AVAILABLE\"}"
    
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
    
    private func sendFirstDiscoveryBeacon(){
        //Do first network call to POST device metric
        let beaconDiscoveryUrl: URL = URL(string: "\(ALFRED_URL_DEV)/alfred/api/v1/device/beacon")!

        var urlRequest: URLRequest = URLRequest(url: beaconDiscoveryUrl)
        urlRequest.addValue(LeapCreatorShared.shared.apiKey!, forHTTPHeaderField: "x-auth-id")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        
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
    
    func sendSubsequentBeacons()-> Void{
        let beaconDiscoveryUrl: URL = URL(string: "\(ALFRED_URL_DEV)/alfred/api/v1/device/beacon")!

        var urlRequest: URLRequest = URLRequest(url: beaconDiscoveryUrl)
        urlRequest.addValue(LeapCreatorShared.shared.apiKey! , forHTTPHeaderField: "x-auth-id")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "PUT"
        
        let jsonData = Data(json.utf8)
        urlRequest.httpBody = jsonData
    
        let discoveryTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let data = data {
                let jsonData = try? JSONSerialization.jsonObject(with: data,  options: []) as? [String: Any]
                //fetch the status and room info from the json
                guard let roomId = (jsonData?[constant_roomId]) as? String else { return }
                self.roomId = roomId
                self.beaconListener.onBeaconSuccess(roomId: self.roomId, status: jsonData?[constant_status]! as Any)
                //repeat this api call every 'm' seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + self.interval, execute: self.task!)
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
            
            start(appId: self.appId!)
        }
    }
}

protocol LeapBeaconListener{
    func onBeaconSuccess(roomId: String, status: Any)->Void
    func onBeaconFailure()->Void
}
