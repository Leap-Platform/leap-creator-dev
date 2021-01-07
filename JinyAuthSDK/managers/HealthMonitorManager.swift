//
//  HealthMonitorManager.swift
//  JinyAuthSDK
//
//  Created by Shreyansh Sharma on 31/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
import Starscream

class HealthMonitorManager {
    
    var healthListener: HealthCheckListener
    var roomId: String?
    var webSocket: WebSocket?
    var lastPongTime: Double?
    var pingTask: DispatchWorkItem?
    let MAX_FAILED_ATTEMPTS = 2.0
    let PING_INTERVAL =  5.0
    
    init(healthCheckListener: HealthCheckListener){
        self.healthListener = healthCheckListener
    }
    
    func start(webSocket: WebSocket, room: String){
        self.roomId = room
        self.webSocket = webSocket
        initialiseSessionVariable()
        pingTask = DispatchWorkItem{
            self.sendPing()
        }
    }
    
    func initialiseSessionVariable(){
        lastPongTime = NSTimeIntervalSince1970
    }
    
    func sendPing(){
        if isSessionActive() {
            let payload = "{\"room\":\"\(roomId!)\",\"message\": {\"commandType\":\"PING\",\"end\":\"true\"},\"action\": \"message\",\"source\": \"android\"}"
            self.webSocket?.write(string: payload, completion: {
                print("PING has been sent! ")
            })
        }else{
            self.healthListener.onSessionClosed()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + PING_INTERVAL, execute: self.pingTask! )
    }
    
    func sendPong(){
        let payload = "{\"room\":\"\(roomId!)\",\"message\": {\"commandType\":\"PONG\",\"end\":\"true\"},\"action\": \"message\",\"source\": \"android\"}"
        self.webSocket?.write(string: payload, completion: {
            print(" payload : \(payload)")
            print("PONG has been sent! ")
        })
    }
    
    func isSessionActive()->Bool{
        return ((NSTimeIntervalSince1970 - self.lastPongTime!) < self.MAX_FAILED_ATTEMPTS * self.PING_INTERVAL)
    }
    
    func receivePong(){
        lastPongTime = NSTimeIntervalSince1970
    }
    
    func stop(){
        self.pingTask?.cancel()
    }
}

protocol HealthCheckListener {
    func onSessionClosed()->Void
    
}
