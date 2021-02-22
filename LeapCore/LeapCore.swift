//
//  Leap.swift
//  LeapCore
//
//  Created by Aravind GS on 16/03/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol LeapAUIHandler:NSObjectProtocol {
    
    func startMediaFetch()
    func hasClientCallBack() -> Bool
    func sendEvent(event:Dictionary<String,Any>)
    
    func performNativeAssist(instruction: Dictionary<String, Any>, view: UIView?, localeCode: String)
    func performWebAssist(instruction: Dictionary<String,Any>, rect: CGRect, webview: UIView?, localeCode: String)
    
    func performNativeDiscovery(instruction: Dictionary<String, Any>, view: UIView?,  localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, AnyHashable>, localeHtmlUrl: String?)
    func performWebDiscovery(instruction: Dictionary<String, Any>, rect: CGRect, webview: UIView?,  localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, AnyHashable>, localeHtmlUrl: String?)
    
    func performNativeStage(instruction: Dictionary<String, Any>, view: UIView?, iconInfo: Dictionary<String, AnyHashable>)
    func performWebStage(instruction: Dictionary<String, Any>, rect: CGRect, webview: UIView?, iconInfo: Dictionary<String, AnyHashable>)
    
    func updateRect(rect:CGRect, inWebView:UIView?)
    func updateView(inView:UIView)
    
    func presentLeapButton(for iconInfo: Dictionary<String,AnyHashable>, iconEnabled: Bool)
    func removeAllViews()
}

@objc public protocol LeapAUICallback:NSObjectProtocol {
    
    func getDefaultMedia() -> Dictionary<String,Any>
    func triggerEvent(identifier:String, value:Any)
    func getWebScript(_ identifier:String) -> String?
    
    func getCurrentLanguageOptionsTexts() -> Dictionary<String,String>
    func getLanguagesForCurrentInstruction() -> Array<Dictionary<String,String>>
    func getIconInfoForCurrentInstruction() -> Dictionary<String,Any>?
    func getLanguageHtmlUrl() -> String?
    func getLanguageCode() -> String
    func getTTSCodeFor(code:String) -> String?
    
    func didPresentView()
    func failedToPerform()
    func didDismissView(byUser:Bool, autoDismissed:Bool, panelOpen:Bool, action:Dictionary<String,Any>?)
    
    func leapTapped()
    
    func optionPanelOpened()
    func optionPanelStopClicked()
    func optionPanelClosed()

    func disableAssistance()
}


@objc public class LeapCore:NSObject {
        
    @objc public static let shared = LeapCore()
    private var leapInternal:LeapInternal?
    private var apiKey:String? = nil
    private var isTest:Bool? = false
    
    private override init() {
        super.init()
    }
    
    public func initialize(withToken token:String, isTesting isTest:Bool, uiManager:LeapAUIHandler?) -> LeapAUICallback? {
        assert(token != "", "Incorrect token")
        self.apiKey = token
        self.isTest = isTest
        self.leapInternal = LeapInternal.init(self.apiKey!, uiManager: uiManager)
        return self.leapInternal?.auiCallback()
    }
}
