//
//  LeapAnalyticsManager.swift
//  LeapCore
//
//  Created by Aravind GS on 28/05/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

@objc protocol LeapAnalyticsManagerDelegate {
    func getHeaders() -> Dictionary<String,String>
    func sendPayload(_ payload:Dictionary<String,Any>)
    func failedToSendEvents(payload:Array<Dictionary<String,Any>>)
    func sendEvents(payload:Array<Dictionary<String,Any>>)
    @objc optional func getApiKey() -> String
}

class LeapAnalyticsManager {
    
    let MAX_COUNT = 5
    weak var delegate: LeapAnalyticsManagerDelegate?
    var session: URLSession
    
    init(_ analyticsDelegate: LeapAnalyticsManagerDelegate) {
        delegate = analyticsDelegate
        session = URLSession.shared
        NotificationCenter.default.addObserver(self, selector: #selector(flushPendingEvents), name: UIApplication.willResignActiveNotification, object: nil)
        flushPendingEvents()
    }
    
    @objc private func flushPendingEvents() {
        let prefs = UserDefaults.standard
        let savedEvents = prefs.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        var eventsToFlush = prefs.object(forKey: "leap_flush_events") as? Array<Dictionary<String, String>> ?? []
        eventsToFlush += savedEvents
        prefs.set(eventsToFlush, forKey: "leap_flush_events")
        prefs.removeObject(forKey: "leap_saved_events")
        flushEvents(eventsToFlush)
    }
    
    private func generatePayload(_ event: LeapAnalyticsEvent) -> Dictionary<String, String>? {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        guard let payloadData = try? jsonEncoder.encode(event) else { return nil }
        guard let payload = try? JSONSerialization.jsonObject(with: payloadData, options: .mutableContainers) as? Dictionary<String, String> else { return nil }
        return payload
    }
    
    func saveEvent(event: LeapAnalyticsEvent?) {
        guard let event = event, let payload = generatePayload(event) else { return }
        print("\(payload)")
        let prefs = UserDefaults.standard
        var savedEvents = prefs.object(forKey: "leap_saved_events") as? Array<Dictionary<String, String>> ?? []
        savedEvents.append(payload)
        prefs.set(savedEvents, forKey: "leap_saved_events")
        prefs.synchronize()
        
        // client callback
        let clientCallbackEvent = event
        clientCallbackEvent.sessionId = nil
        clientCallbackEvent.projectId = nil
        clientCallbackEvent.deploymentId = nil
        
        guard let clientPayload = generatePayload(clientCallbackEvent) else { return }
        delegate?.sendPayload(clientPayload)
        
        if savedEvents.count >= MAX_COUNT {
            var eventsToFlush = prefs.object(forKey: "leap_flush_events") as? Array<Dictionary<String, String>> ?? []
            eventsToFlush += savedEvents
            prefs.set(eventsToFlush, forKey: "leap_flush_events")
            prefs.removeObject(forKey: "leap_saved_events")
            flushEvents(eventsToFlush)
        }
    }
    
    func flushEvents(_ events: Array<Dictionary<String, String>>) {
        guard events.count > 0 else { return }
        guard var req = createURLRequest(urlString: Constants.Networking.analyticsEndPoint) else {
            delegate?.failedToSendEvents(payload: events)
            return
        }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: events, options: .prettyPrinted) else {
            delegate?.failedToSendEvents(payload: events)
            return
        }
        req.httpBody = jsonData
        let analyticsTask = session.dataTask(with: req) { (data, response, error) in
            if error != nil { self.delegate?.failedToSendEvents(payload: events) }
            else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    self.delegate?.sendEvents(payload: events)
                    let prefs = UserDefaults.standard
                    prefs.removeObject(forKey: "leap_flush_events")
                } else { self.delegate?.failedToSendEvents(payload: events) }
            }
        }
        analyticsTask.resume()
    }
    
    func createURLRequest(urlString: String) -> URLRequest? {
        guard let url = URL(string: urlString) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        let headers = delegate?.getHeaders()
        headers?.forEach { (key, value) in
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
        static let analyticsEndPoint: String = {
            #if DEV
                return "https://odin-dev-gke.leap.is/odin/api/v1/analytics"
            #elseif STAGE
                return "https://odin-stage-gke.leap.is/odin/api/v1/analytics"
            #elseif PROD
                return "https://odin.leap.is/odin/api/v1/analytics"
            #else
                return "https://odin.leap.is/odin/api/v1/analytics"
            #endif
        }()
    }
}

extension Constants {
    struct AnalyticsKeys {
        static let tempApiKey = "pBWmiQ8HCKllVJd2xQ5Cd7d5defd9e1e4f7a8882c34ff75f0d36"
        static let xClientId = "x-client-id"
        static let contentTypeKey = "Content-Type"
        static let contentTypeValue = "application/json"
        static let xLeapId = "x-leap-id"
        static let xJinyClientId = "x-jiny-client-id"
    }
}
