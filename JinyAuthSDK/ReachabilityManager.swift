//
//  ReachabilityManager.swift
//  JinyAuthSDK
//
//  Created by Ajay S on 19/01/21.
//  Copyright © 2021 Jiny Inc. All rights reserved.
//

import UIKit

class ReachabilityManager {
    
    static let shared = ReachabilityManager()
    
    var reachability: Reachability?
    
    private var defaultConnection = false
        
    func initialize() {
    
        startHost(at: 0)
    }
    
    func startHost(at index: Int) {
        stopNotifier()
        setupReachability(nil, useClosures: true)
        startNotifier()
    }
    
    func setupReachability(_ hostName: String?, useClosures: Bool) {
        let reachability: Reachability?
        if let hostName = hostName {
            reachability = try? Reachability(hostname: hostName)
        } else {
            reachability = try? Reachability()
        }
        self.reachability = reachability

        if useClosures {
            reachability?.whenReachable = { reachability in
                self.updateLabelColourWhenReachable(reachability)
                if self.defaultConnection {
                  NotificationCenter.default.post(Notification(name: NSNotification.Name(rawValue: "internetConnected")))
                }
                self.defaultConnection = true
            }
            reachability?.whenUnreachable = { reachability in
                self.updateLabelColourWhenNotReachable(reachability)
                NotificationCenter.default.post(Notification(name: NSNotification.Name(rawValue: "internetNotConnected")))
                self.defaultConnection = true
            }
        } else {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(reachabilityChanged(_:)),
                name: .reachabilityChanged,
                object: reachability
            )
        }
    }
    
    func startNotifier() {
        print("--- start notifier")
        do {
            try reachability?.startNotifier()
        } catch {
            return
        }
    }
    
    func stopNotifier() {
        print("--- stop notifier")
        reachability?.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: nil)
        reachability = nil
    }
    
    func updateLabelColourWhenReachable(_ reachability: Reachability) {
        print("\(reachability.description) - \(reachability.connection)")
        UIApplication.shared.keyWindow?.rootViewController?.showToast(message: "Connected to the Internet", color: .systemGreen)
    }
    
    func updateLabelColourWhenNotReachable(_ reachability: Reachability) {
        print("\(reachability.description) - \(reachability.connection)")
        UIApplication.shared.keyWindow?.rootViewController?.showToast(message: "Please check your internet connection", color: .systemRed)
    }

    @objc func reachabilityChanged(_ note: Notification) {
        let reachability = note.object as! Reachability
        
        if reachability.connection != .unavailable {
            updateLabelColourWhenReachable(reachability)
        } else {
            updateLabelColourWhenNotReachable(reachability)
        }
    }
    
    deinit {
        stopNotifier()
    }
}
