//
//  LeapSocketListener.swift
//  LeapCreator
//
//  Created by Shreyansh Sharma on 22/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import Starscream

class LeapSocketMessageDelegate: WebSocketDelegate{
    
    let NORMAL_CLOSURE_STATUS: Int = 1000
    weak var leapSocketListener: LeapSocketListener?

    init(leapSocketListener: LeapSocketListener) {
        self.leapSocketListener = leapSocketListener
        
        UIApplication.shared.beginBackgroundTask { }
    }

    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            print("connected \(headers)")
            self.leapSocketListener?.onConnectionEstablished()  // called to enable socket to begin writing
        
        case .disconnected(let reason, let closeCode):
            print("disconnected \(reason) \(closeCode)")
            
        case .text(let text):
            print("received text: \(text)")
            
            guard let data = text.data(using: .utf8) else { return }
            guard let jsonData = try? JSONSerialization.jsonObject(with: data,  options: []) as? [String: Any] else { return }
            //fetch the status and room info from the json
            if jsonData[constant_id] == nil { return }
            guard let typeOfPacket = (jsonData[constant_type]) as? String else { return }
            guard let id = (jsonData[constant_id]) as? String else { return }
            self.leapSocketListener?.onReceivePacket(id: id, type: typeOfPacket)
            
        case .binary(let data):
            print("received data: \(data)")
            
        case .pong( _): break
            
        case .ping( _): break
            
        case .error(let error):
            print("error \(String(describing: error?.localizedDescription))")
            
        case .viabilityChanged:
            print("viabilityChanged")
            
        case .reconnectSuggested:
            print("reconnectSuggested")
            
        case .cancelled:
            print("cancelled")
        }
    }
}

protocol LeapSocketListener: AnyObject {
    func onReceivePacket(id: String, type: String)
    func onConnectionEstablished()
}
