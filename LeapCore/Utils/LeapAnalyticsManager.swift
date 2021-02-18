//
//  LeapAnalyticsManager.swift
//  LeapCore
//
//  Created by Aravind GS on 28/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

@objc protocol LeapAnalyticsManagerDelegate {
    func getHeaders() -> Dictionary<String,String>
    func failedToSendPayload(_ payload:Dictionary<String,Any> )
    func payloadSend(_ payload:Dictionary<String,Any>)
    func incorrectPayload(_ payload:Dictionary<String,Any>)
    func failedToSendBulkEvents(payload:Array<Dictionary<String,Any>>)
    func sendBulkEvents(payload:Array<Dictionary<String,Any>>)
    @objc optional func getApiKey() -> String
}

class LeapAnalyticsManager {
    
    let MAX_COUNT = 5
    var delegate:LeapAnalyticsManagerDelegate
    var session:URLSession
    
    init(_ analyticsDelegate:LeapAnalyticsManagerDelegate) {
        delegate = analyticsDelegate
        session = URLSession.shared
        let pref = UserDefaults.standard
        let events = pref.object(forKey: "leap_saved_events") as? Array<Dictionary<String,Any>> ?? []
        flushEvents(events)
    }
    
    func sendEvent(_ event:LeapAnalyticsEvent) {
        
        guard let payload = generatePayload(event) else { return }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted) else {
            delegate.incorrectPayload(payload)
            return
        }
        guard var eventReq = createURLRequest(urlString: Constants.Networking.analyticsEndPoint) else {
            delegate.failedToSendPayload(payload)
            return
        }
        eventReq.httpBody = jsonData
        let analyticsTask = session.dataTask(with: eventReq) { (data, urlResponse, error) in
            if error != nil { self.delegate.failedToSendPayload(payload) }
            else {
                if let res = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Dictionary<String,String> {
                    if let status = res[constant_status], status == "success" {
                        self.delegate.payloadSend(payload)
                    } else { self.delegate.failedToSendPayload(payload)}
                } else { self.delegate.failedToSendPayload(payload)}
            }
        }
        analyticsTask.resume()
    }
    
    func generatePayload(_ event:LeapAnalyticsEvent) -> Dictionary<String,Any>? {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        guard let payloadData = try? jsonEncoder.encode(event) else { return nil }
        guard let payload = try? JSONSerialization.jsonObject(with: payloadData, options: .mutableContainers) as? Dictionary<String,Any> else { return nil }
        return payload
    }
    
    func saveEvent(payload:Dictionary<String,Any>, isSuccess:Bool) {
        let prefs = UserDefaults.standard
        var savedEvents = prefs.object(forKey: "leap_saved_events") as? Array<Dictionary<String,Any>> ?? []

        if savedEvents.count == MAX_COUNT || isSuccess {
            flushEvents(savedEvents)
            savedEvents.removeAll()
        }
        savedEvents.append(payload)
        prefs.set(savedEvents, forKey: "leap_saved_events")
        prefs.synchronize()
    }
    
    func saveEvents(payload:Array<Dictionary<String,Any>>) {
        let prefs = UserDefaults.standard
        var savedEvents = prefs.object(forKey: "leap_saved_events") as? Array<Dictionary<String,Any>> ?? []
        savedEvents += payload
        prefs.set(payload, forKey: "leap_saved_events")
        prefs.synchronize()
    }
    
    func flushEvents(_ events:Array<Dictionary<String,Any>>) {
        guard events.count > 0 else { return }
        guard var req = createURLRequest(urlString: Constants.Networking.bulkAnalyticsEndPoint) else {
            delegate.failedToSendBulkEvents(payload: events)
            return
        }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: events, options: .prettyPrinted) else {
            delegate.failedToSendBulkEvents(payload: events)
            return
        }
        req.httpBody = jsonData
        let bulkAnalyticsTask = session.dataTask(with: req) { (data, response, error) in
            if error != nil { self.delegate.failedToSendBulkEvents(payload: events) }
            else {
                if let res = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Dictionary<String,String> {
                    if let status = res[constant_status], status == "success" {
                        self.delegate.sendBulkEvents(payload: events)
                    } else { self.delegate.failedToSendBulkEvents(payload: events)}
                } else { self.delegate.failedToSendBulkEvents(payload: events)}
            }
        }
        bulkAnalyticsTask.resume()
    }
    
    func createURLRequest(urlString:String) -> URLRequest? {
        guard let url = URL(string: urlString) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        let headers = delegate.getHeaders()
        headers.forEach { (key, value) in
            req.addValue(value, forHTTPHeaderField: key)
        }
        return req
    }
    
}



struct Constants {
    struct Networking {
        static let isExecuting = "isExecuting"
        static let isFinished = "isFinished"
        static let downloadQ = "Leap Download Queue"
        static let dataQ = "Leap Data Queue"
        static let downloadsFolder = "Leap"
        static let analyticsEndPoint = "https://dev.leap.io/api/leap/v2/sendAnalytics"
        static let bulkAnalyticsEndPoint = "https://dev.leap.io/api/leap/v2/bulkAnalytics"
    }
}

extension Constants {
    struct AnalyticsTemp {
        static let tempApiKey = "pBWmiQ8HCKllVJd2xQ5Cd7d5defd9e1e4f7a8882c34ff75f0d36"
        static let xClientId = "x-client-id"
        static let contentTypeKey = "Content-Type"
        static let contentTypeValue = "application/json"
        static let timestampKey = ""
    }
}
