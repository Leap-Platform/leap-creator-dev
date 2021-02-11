//
//  Jiny.swift
//  JinySDK
//
//  Created by Aravind GS on 16/03/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

@objc public enum JinyPointerStyle:Int {
    case FingerRipple
    case NegativeUI
}

@objc public protocol JinyAUIHandler:NSObjectProtocol {
    
    func startMediaFetch()
    func hasClientCallBack() -> Bool
    func sendEvent(event:Dictionary<String,Any>)
    
    func performNativeAssist(instruction: Dictionary<String, Any>, view: UIView?, localeCode: String)
    func performWebAssist(instruction: Dictionary<String,Any>, rect: CGRect, webview: UIView?, localeCode: String)
    
    func performNativeDiscovery(instruction: Dictionary<String, Any>, view: UIView?,  localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, Any>, localeHtmlUrl: String?)
    func performWebDiscovery(instruction: Dictionary<String, Any>, rect: CGRect, webview: UIView?,  localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, Any>, localeHtmlUrl: String?)
    
    func performNativeStage(instruction: Dictionary<String, Any>, view: UIView?, iconInfo: Dictionary<String, Any>)
    func performWebStage(instruction: Dictionary<String, Any>, rect: CGRect, webview: UIView?, iconInfo: Dictionary<String, Any>)
    
    func updateRect(rect:CGRect, inWebView:UIView?)
    func updateView(inView:UIView)
    
    func presentJinyButton(for iconSetting: IconSetting, iconEnabled: Bool)
    func dismissJinyButton()
    func removeAllViews()
}

@objc public protocol JinyAUICallback:NSObjectProtocol {
    
    func getDefaultMedia() -> Dictionary<String,Any>
    func triggerEvent(identifier:String, value:Any)
    func getWebScript(_ identifier:String) -> String?
    
    func getLanguages() -> Array<String>
    func getLanguageCode() -> String
    
    func didPresentView()
    func failedToPerform()
    func didDismissView(byUser:Bool, autoDismissed:Bool, panelOpen:Bool, action:Dictionary<String,Any>?)
    
    func jinyTapped()
    
    func languagePanelOpened()
    func languagePanelClosed()
    func languagePanelLanguageSelected(atIndex:Int)
    
    func optionPanelOpened()
    func optionPanelClosed()
    func optionPanelRepeatClicked()
    func optionPanelMuteClicked()
    
    func disableAssistance()
}


@objc public class Jiny:NSObject {
        
    @objc public static let shared = Jiny()
    private var jinyInternal:JinyInternal?
    private var apiKey:String? = nil
    private var isTest:Bool? = false
    private var sdkEnabled:Bool = true
    
    private override init() {
        self.sdkEnabled = true
        super.init()
    }
    
    public func initialize(withToken token:String, isTesting isTest:Bool, uiManager:JinyAUIHandler?) -> JinyAUICallback? {
        assert(token != "", "Incorrect token")
        self.apiKey = token
        self.isTest = isTest
        self.jinyInternal = JinyInternal.init(self.apiKey!, uiManager: uiManager)
        return self.jinyInternal?.auiCallback()
    }
    
    @objc public func enable(_ enable:Bool) { sdkEnabled = enable }

    
}

struct Constants {
    
}
