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
    func performInstruction(instruction:Dictionary<String,Any>, inView:UIView)
    func performInstrcution(instruction:Dictionary<String,Any>, rect:CGRect, inWebview:UIView?)
    func updateRect(rect:CGRect, inWebView:UIView?)
    
    func playAudio()
    func playTTS(withLangCode:String)
    func presentJinyButton()
    func presentBottomDiscovery(header:String, optInText:String, optOutText:String, languages:Array<String>)
    func presentPingDiscovery()
    func presentFlowSelector(branchTitle:String, flowTitles:Array<String>)
    func presentPointer(toView:UIView, ofType:JinyPointerStyle)
    func presentPointer(toRect:CGRect, inView:UIView?, ofType:JinyPointerStyle)
    func updatePointerRect(newRect:CGRect, inView:UIView?)
    func presentLanguagePanel(languages:Array<String>)
    func presentOptionPanel(mute:String, repeatText:String, language:String?)
    func dismissJinyButton()
    func keepOnlyJinyButtonIfPresent()
    func removeAllViews()
}

@objc public protocol JinyAUICallback:NSObjectProtocol {
    
    func getDefaultMedia() -> Dictionary<String,Dictionary<String,Any>>
    
    func triggerEvent(identifier:String, value:Any)
    
    func tryTTS() -> String?
    func getAudioFilePath() -> String?
    func getTTSText() -> String?
    func getLanguages() -> Array<String>
    func getLanguageCode() -> String
    
    func willPresentView()
    func didPresentView()
    func willPlayAudio()
    func didPlayAudio()
    func failedToPerform()
    func didDismissView()
    
    func stagePerformed()
    
    func jinyTapped()
    
    func discoveryPresented()
    func discoveryMuted()
    func discoveryOptedInFlow(atIndex:Int)
    func discoveryReset()
    
    func languagePanelOpened()
    func languagePanelClosed()
    func languagePanelLanguageSelected(atIndex:Int)
    
    func optionPanelOpened()
    func optionPanelClosed()
    func optionPanelRepeatClicked()
    func optionPanelMuteClicked()
    
    func flowSelectorPresented()
    func flowSelectorFlowSelected(atIndex:Int)
    func flowSelectorDismissed()
    
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
    
    @objc public func initialize(withToken token:String, isTesting isTest:Bool, uiManager:JinyAUIHandler?) -> JinyAUICallback? {
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
