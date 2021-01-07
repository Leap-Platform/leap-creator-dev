//
//  BeaconManager.swift
//  JinyAuthSDK
//
//  Created by Shreyansh Sharma on 20/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class BeaconManager {
    private static let TAG: String = " Jiny - BeaconManager "
    private let ALFRED_URL_LOCAL: String  = "http://192.168.1.3:8080"
    private let ALFRED_URL_DEV: String = "https://alfred-dev-0-0-1-gke.jiny.io"
    
    let json = "{\"id\":\"\(JinyAuthShared.shared.apiKey!)\",\"name\":\"iPhone\",\"type\":\"IOS\",\"appApiKey\":\"\(JinyAuthShared.shared.apiKey!)\",\"model\" :\"iPhone11\",\"osVersion\" : \"10.3\",\"height\" : \"2280\",\"width\" : \"1080\",\"appVersionCode\" : \"90\",\"appVersionName\" : \"2.0.2\",\"authToolVersionCode\" :\"10\",\"authToolVersionName\" : \"4.0.1\",\"status\":\"AVAILABLE\"}"
    
    var beaconListener: BeaconListener
    var appId: String?
    var roomId: String
    var status: String?
    var task: DispatchWorkItem?
    let interval: TimeInterval = (JinyAuthShared.shared.authConfig?.beacon?.interval ?? 3000)/1000
    
    var roomID: String? {
        get{
            return roomId
        }
    }
    
    init(beaconListener: BeaconListener) {
        self.beaconListener = beaconListener
        self.roomId = ""
    }
    
    public func start(appId: String){
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
        urlRequest.addValue(JinyAuthShared.shared.apiKey!, forHTTPHeaderField: "x-auth-id")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        
        let jsonData = Data(json.utf8)
        urlRequest.httpBody = jsonData
    
        let discoveryTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let data = data {
                _ = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                self.sendSubsequentBeacons()
            }
        }
        discoveryTask.resume()
    }
    
    func sendSubsequentBeacons()-> Void{
        let beaconDiscoveryUrl: URL = URL(string: "\(ALFRED_URL_DEV)/alfred/api/v1/device/beacon")!

        var urlRequest: URLRequest = URLRequest(url: beaconDiscoveryUrl)
        urlRequest.addValue(JinyAuthShared.shared.apiKey! , forHTTPHeaderField: "x-auth-id")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "PUT"
        
        let jsonData = Data(json.utf8)
        urlRequest.httpBody = jsonData
    
        let discoveryTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let data = data {
                let jsonData = try? JSONSerialization.jsonObject(with: data,  options: []) as? [String: Any]
                //fetch the status and room info from the json
                self.roomId = (jsonData?[constant_roomId]) as! String
                self.beaconListener.onBeaconSuccess(roomId: (jsonData?[constant_roomId])! as! String, status: jsonData?[constant_status]! as Any)
                //repeat this api call every 'm' seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + self.interval, execute: self.task!)
            }
        }
        discoveryTask.resume()
    }

    /*
     Stop the beacon manager to stop sending the beacons once the connection is active
     */
    func stop()->Void{
        self.task?.cancel()
    }
    
}

protocol BeaconListener{
    func onBeaconSuccess(roomId: String, status: Any)->Void
    func onBeaconFailure()->Void
}
