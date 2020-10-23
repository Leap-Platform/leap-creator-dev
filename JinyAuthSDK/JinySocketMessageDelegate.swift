//
//  JinySocketListener.swift
//  JinyAuthSDK
//
//  Created by Shreyansh Sharma on 22/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
import Starscream

class JinySocketMessageDelegate: WebSocketDelegate{
    
    let NORMAL_CLOSURE_STATUS: Int = 1000;
    var jinySocketListener: JinySocketListener
    
    init(jinySocketListener: JinySocketListener) {
        self.jinySocketListener = jinySocketListener
    }

    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
           case .connected(let headers):
             print("connected \(headers)")
            self.jinySocketListener.onConnectionEstablished()  // called to enable socket to begin writing 
            
           case .disconnected(let reason, let closeCode):
             print("disconnected \(reason) \(closeCode)")
            
           case .text(let text):
             print("received text: \(text)")
            
           case .binary(let data):
             print("received data: \(data)")
            
           case .pong(let pongData):
             print("received pong: \(pongData)")
            
           case .ping(let pingData):
             print("received ping: \(pingData)")
            
           case .error(let error):
             print("error \(error)")
            
           case .viabilityChanged:
             print("viabilityChanged")
            
           case .reconnectSuggested:
             print("reconnectSuggested")
            
           case .cancelled:
             print("cancelled")
           }
        
    }
    
    
}

protocol JinySocketListener{
    func onReceivePacket(id: String, type: String)
    func onConnectionEstablished()->Void
    
}
