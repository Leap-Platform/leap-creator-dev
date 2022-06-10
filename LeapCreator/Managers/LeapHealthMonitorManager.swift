//
//  LeapHealthMonitorManager.swift
//  LeapCreator
//
//  Created by Shreyansh Sharma on 31/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

class LeapHealthMonitorManager {
    
    weak var healthListener: LeapHealthCheckListener?
    var roomId: String?
    var webSocket: WebSocket?
    var lastPongTime: Double?
    var pingTask: DispatchWorkItem?
    let MAX_FAILED_ATTEMPTS = 2.0
    let PING_INTERVAL = 5.0
    
    init(healthCheckListener: LeapHealthCheckListener) {
        self.healthListener = healthCheckListener
    }
    
    func start(webSocket: WebSocket, room: String) {
        self.roomId = room
        self.webSocket = webSocket
        initialiseSessionVariable()
        pingTask = DispatchWorkItem{
            self.sendPing()
        }
        sendPing()
    }
    
    func initialiseSessionVariable() {
        lastPongTime = NSDate().timeIntervalSince1970
    }
    
    func sendPing() {
        if isSessionActive() {
            guard let payload = getPayloadFor("PING") else { return }
            self.webSocket?.write(string: payload, completion: {
                print("PING has been sent! ")
            })
        } else {
            if self.webSocket != nil {
                self.healthListener?.onSessionClosed()
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .init(rawValue: "Reset_Notification"), object: nil)
                }
            }
        }
        guard let pingTask = self.pingTask else { return }
        DispatchQueue.global().asyncAfter(deadline: .now() + PING_INTERVAL, execute: pingTask)
    }
    
    func sendPong() {
        guard let payload = getPayloadFor("PONG") else { return }
        self.webSocket?.write(string: payload, completion: {
            print(" payload : \(payload)")
            print("PONG has been sent! ")
        })
    }
    
    func getPayloadFor(_ commandType:String) -> String? {
        guard commandType == "PING" || commandType == "PONG" else { return nil }
        guard let roomId = roomId else { return nil }

        let payloadDict:[String:AnyHashable] = [
            "room"              : roomId,
            "message"           : [
                "commandType"   : commandType,
                "end"           : "true",
            ],
            "action"            : "message",
            "source"            : "android"
        ]
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payloadDict, options: .fragmentsAllowed),
              let payloadString = String(data: payloadData, encoding: .utf8) else { return nil }
        return payloadString
    }
    
    func isSessionActive() -> Bool {
        guard let lastPongTime = self.lastPongTime else { return false }
        return ((NSDate().timeIntervalSince1970 - lastPongTime) < (self.MAX_FAILED_ATTEMPTS * self.PING_INTERVAL))
    }
    
    func receivePong() {
        lastPongTime = NSDate().timeIntervalSince1970
    }
    
    func stop() {
        self.pingTask?.cancel()
    }
}

protocol LeapHealthCheckListener: AnyObject {
    func onCloseSession()
    func onSessionClosed()
}
