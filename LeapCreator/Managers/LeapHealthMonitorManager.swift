//
//  LeapHealthMonitorManager.swift
//  LeapCreator
//
//  Created by Shreyansh Sharma on 31/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import Starscream

class LeapHealthMonitorManager {
    
    var healthListener: LeapHealthCheckListener
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
            guard let roomId = roomId else { return }
            let payload = "{\"room\":\"\(roomId)\",\"message\": {\"commandType\":\"PING\",\"end\":\"true\"},\"action\": \"message\",\"source\": \"android\"}"
            self.webSocket?.write(string: payload, completion: {
                print("PING has been sent! ")
            })
        } else {
            self.healthListener.onSessionClosed()
        }
        guard let pingTask = self.pingTask else { return }
        DispatchQueue.global().asyncAfter(deadline: .now() + PING_INTERVAL, execute: pingTask)
    }
    
    func sendPong() {
        guard let roomId = roomId else { return }
        let payload = "{\"room\":\"\(roomId)\",\"message\": {\"commandType\":\"PONG\",\"end\":\"true\"},\"action\": \"message\",\"source\": \"android\"}"
        self.webSocket?.write(string: payload, completion: {
            print(" payload : \(payload)")
            print("PONG has been sent! ")
        })
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

protocol LeapHealthCheckListener {
    func onSessionClosed()->Void
    
}
