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
    private let API_KEY: String  = "626085ff-35d6-4779-bb12-6b6da2eb8838"
    
    var beaconListener: BeaconListener
    var appId: String?
    
    init(beaconListener: BeaconListener) {
        self.beaconListener = beaconListener
    }
    
    public func start(appId: String){
        self.appId = appId
        startBeacons()
    }
    
    private func startBeacons(){
        DispatchQueue.global().async {
            print("Starting to send beacons in 3 .. 2.. 1 ... !")
            self.sendFirstDiscoveryBeacon()
        }
    }
    
    private func sendFirstDiscoveryBeacon(){
        //Do first network call to POST device metric
                
        var beaconDiscoveryUrl: URL = URL(string: "\(ALFRED_URL_DEV)/alfred/api/v1/device/beacon")!
        
        var json: [String:  String] = [
            "id" : "device_123",
            "name" : "One Plus",
            "type" : "IOS",
            "appApiKey":"626085ff-35d6-4779-bb12-6b6da2eb8838",
            "model" : "iPhone11",
            "osVersion" : "10.3",
            "height" : "2280",
            "width" : "1080",
            "appVersionCode" : "90",
            "appVersionName" : "2.0.2",
            "authToolVersionCode" : "10",
            "authToolVersionName" : "4.0.1",
            "status":"AVAILABLE"
        ]

        var urlRequest: URLRequest = URLRequest(url: beaconDiscoveryUrl)
        urlRequest.addValue("626085ff-35d6-4779-bb12-6b6da2eb8838" , forHTTPHeaderField: "x-auth-id")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed)
        urlRequest.httpBody = jsonData
    
        let discoveryTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let data = data {
                let jsonData = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                self.sendSubsequentBeacons()
            }
        }
        discoveryTask.resume()
    }
    
    func sendSubsequentBeacons()-> Void{
        var beaconDiscoveryUrl: URL = URL(string: "\(ALFRED_URL_DEV)/alfred/api/v1/device/beacon")!
        
        var json: [String:  String] = [
            "id" : "device_123",
            "name" : "One Plus",
            "type" : "IOS",
            "appApiKey":"626085ff-35d6-4779-bb12-6b6da2eb8838",
            "model" : "iPhone11",
            "osVersion" : "10.3",
            "height" : "2280",
            "width" : "1080",
            "appVersionCode" : "90",
            "appVersionName" : "2.0.2",
            "authToolVersionCode" : "10",
            "authToolVersionName" : "4.0.1",
            "status":"AVAILABLE"
        ]

        var urlRequest: URLRequest = URLRequest(url: beaconDiscoveryUrl)
        urlRequest.addValue("626085ff-35d6-4779-bb12-6b6da2eb8838" , forHTTPHeaderField: "x-auth-id")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "PUT"
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed)
        urlRequest.httpBody = jsonData
    
        let discoveryTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let data = data {
                let jsonData = try? JSONSerialization.jsonObject(with: data,  options: []) as? [String: Any]
                //fetch the status and room info from the json
                var roomId = jsonData?["roomId"]
                var status = jsonData?["status"]
                
                //repeat this api call every 'm' seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        // do stuff 42 seconds later
                    self.sendSubsequentBeacons()
                }
            
            }
            
        }
        discoveryTask.resume()
    }

}

struct BeaconObject: Codable {
    var id: String
    var name:String
    var type:String
    var appApiKey:String
    var model: String
    var osVersion: String
    var width: String
    var height: String
    var appVersionName: String
    var appVersionCode: String
    var authToolVersionCode: String
    var authToolVersionName: String
    var status : String
    var logo : String
    var permissionStatus : String
    var permissionBy: String
    var roomId : String
    var createdAt : String
    var updatedAt : String
    var createdBy : String
    var updatedBy: String
}

protocol BeaconListener{
    
}
