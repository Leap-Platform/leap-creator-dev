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

public protocol JinyAUIHandler:NSObjectProtocol {
    
    func startMediaFetch()
    func hasClientCallBack() -> Bool
    func sendEvent(event:Dictionary<String,Any>)
    func performInstruction(instruction: Dictionary<String, Any>, inView: UIView?, iconInfo: Dictionary<String, Any>)
    func performInstruction(instruction:Dictionary<String,Any>, rect:CGRect, inWebview:UIView?, iconInfo:Dictionary<String,Any>)
    func performInstruction(instruction:Dictionary<String,Any>)
    func updateRect(rect:CGRect, inWebView:UIView?)
    func updateView(inView:UIView)
    func presentJinyButton(for iconSetting: IconSetting, iconEnabled: Bool)
    func presentLanguagePanel(languages: Array<String>)
    func presentOptionPanel(mute: String, repeatText: String, language: String?)
    func dismissJinyButton()
    func keepOnlyJinyButtonIfPresent()
    func dismissCurrentAssist()
    func removeAllViews()
}

@objc public protocol JinyAUICallback:NSObjectProtocol {
    
    func getDefaultMedia() -> Dictionary<String,Any>
    func triggerEvent(identifier:String, value:Any)
    
    func getLanguages() -> Array<String>
    func getLanguageCode() -> String
    
    func willPresentView()
    func didPresentView()
    func willPlayAudio()
    func didPlayAudio()
    func failedToPerform()
    func willDismissView()
    func didDismissView()
    func didDismissView(byUser:Bool, autoDismissed:Bool, action:Dictionary<String,Any>?)
    func didReceiveInstruction(dict:Dictionary<String,Any>)
    
    func stagePerformed()
    
    func jinyTapped()
    
    func languagePanelOpened()
    func languagePanelClosed()
    func languagePanelLanguageSelected(atIndex:Int)
    
    func optionPanelOpened()
    func optionPanelClosed()
    func optionPanelRepeatClicked()
    func optionPanelMuteClicked()
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
