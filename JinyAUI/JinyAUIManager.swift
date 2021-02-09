//
//  JinyAUIManager.swift
//  JinyAUI
//
//  Created by Aravind GS on 07/07/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
import JinySDK
import AVFoundation
import AdSupport
import WebKit


protocol JinyAUIManagerDelegate:NSObjectProtocol {
    
    func isClientCallbackRequired() -> Bool
    func eventGenerated(event:Dictionary<String,Any>)
    
}

class JinyAUIManager:NSObject {
    
    weak var auiManagerCallBack:JinyAUICallback?
    weak var delegate:JinyAUIManagerDelegate?
    
    var currentAssist:JinyAssist? { didSet { if let _ = currentAssist { currentAssist?.delegate = self } } }
    
    var keyboardHeight:Float = 0
    var jinyButtonBottomConstraint:NSLayoutConstraint?
    var scrollArrowBottomConstraint:NSLayoutConstraint?
    
    var audioPlayer:AVAudioPlayer?
    var optionPanel:JinyOptionPanel?
    var languagePanel:JinyLanguagePanel?
    var jinyButton:JinyMainButton?
    
    var synthesizer:AVSpeechSynthesizer?
    var utterance:AVSpeechUtterance?
    let audioSession = AVAudioSession.sharedInstance()
    var mediaManager:JinyMediaManager?
    
    var soundsJson:Dictionary<String,Any>?
    var scrollArrow:UIButton?
    
    var currentInstruction:Dictionary<String,Any>?
    weak var currentTargetView:UIView?
    var currentTargetRect:CGRect?
    weak var currentWebView:UIView?
    
    var autoDismissTimer:Timer?
    private var baseUrl = String()
    
    func addIdentifier(identifier:String, value:Any) {
        auiManagerCallBack?.triggerEvent(identifier: identifier, value: value)
    }
    
}

extension JinyAUIManager {
    
    func addKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    @objc func keyboardDidShow(_ notification:NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
           let targetView = currentTargetView, isViewHiddenByKeyboard(targetView)
        {
            let keyboardRectangle = keyboardFrame.cgRectValue
            keyboardHeight = Float(keyboardRectangle.height)
            showArrow()
            scrollArrowBottomConstraint?.constant = CGFloat(keyboardHeight + 20)
            scrollArrow?.updateConstraints()
        }
        if jinyButton != nil {
            jinyButtonBottomConstraint?.constant = CGFloat(keyboardHeight + 20)
            jinyButton?.updateConstraints()
        }
    }
    
    @objc func keyboardDidHide(_ notification:NSNotification) {
        keyboardHeight = 0
        guard let assistInfo = currentInstruction?[constant_assistInfo] as? Dictionary<String,Any>, let autoScroll = assistInfo[constant_autoScroll] as? Bool else {
            return
        }
        if autoScroll {
            scrollArrow?.removeFromSuperview()
            scrollArrow = nil
        }
        else if let targetView = currentTargetView {
            if !isViewHiddenByKeyboard(targetView) {
                scrollArrow?.removeFromSuperview()
                scrollArrow = nil
            }
        }
        if jinyButton != nil {
            jinyButtonBottomConstraint?.constant = 20.0
            jinyButton?.updateConstraints()
        }
    }
    
    func playAudio() {
        guard let code = JinyPreferences.shared.currentLanguage,
              let mediaName = currentInstruction?[constant_soundName] as? String else {
            startAutoDismissTimer()
            return
        }
        
        if mediaManager?.isAlreadyDownloaded(mediaName: mediaName, langCode: code) ?? false {
            let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            var jinyMediaPath = documentPath.appendingPathComponent(Constants.Networking.downloadsFolder)
            jinyMediaPath = jinyMediaPath.appendingPathComponent(code).appendingPathComponent(mediaName).appendingPathExtension("mp3")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                self.audioPlayer = try AVAudioPlayer(contentsOf: jinyMediaPath, fileTypeHint: AVFileType.mp3.rawValue)
                self.audioPlayer?.delegate = self
                guard let player = self.audioPlayer else { return }
                self.jinyButton?.iconState = .audioPlay
                player.play()
            } catch  { }
        }
    }
}

extension JinyAUIManager:JinyAUIHandler {
    
    func startMediaFetch() {
        
        DispatchQueue.main.async {
            self.jinyButton?.iconState = .loading
        }
        
        DispatchQueue.global().async {
            
            self.mediaManager = JinyMediaManager(withDelegate: self)
            guard let callback = self.auiManagerCallBack else { return }
            let initialSounds = callback.getDefaultMedia()
            
            if let defaultSoundsDicts = initialSounds[constant_defaultSounds] as? Array<Dictionary<String,Any>> {
                for defaultSoundDict in defaultSoundsDicts {
                    self.startDefaultSoundDownload(defaultSoundDict)
                }
            }
            if let discoverySoundsDicts = initialSounds[constant_discoverySounds] as? Array<Dictionary<String,Any>> {
                for discoverySoundsDict in discoverySoundsDicts {
                    self.startDefaultSoundDownload(discoverySoundsDict)
                }
            }
            var htmlBaseUrl:String?
            if let auiContentDicts = initialSounds[constant_auiContent]  as? Array<Dictionary<String,Any>> {
                for auiContentDict in auiContentDicts {
                    if let baseUrl = auiContentDict[constant_baseUrl] as? String, let contents = auiContentDict[constant_content] as? Array<String> {
                        self.baseUrl = baseUrl
                        htmlBaseUrl = baseUrl
                        for content in contents {
                            let auiContent = JinyAUIContent(baseUrl: baseUrl, location: content)
                            self.mediaManager?.startDownload(forMedia: auiContent, atPriority: .low)
                        }
                    }
                }
            }
            
            if let iconSettingDict = initialSounds[constant_iconSetting] as? Dictionary<String, IconSetting> {
                if let baseUrl = htmlBaseUrl {
                    self.baseUrl = baseUrl
                    for (_, value) in iconSettingDict {
                        let auiContent = JinyAUIContent(baseUrl: baseUrl, location: value.htmlUrl ?? "")
                        self.mediaManager?.startDownload(forMedia: auiContent, atPriority: .low)
                    }
                }
            }
            self.fetchSoundConfig()
        }
    }
    
    func hasClientCallBack() -> Bool {
        guard let managerDelegate = delegate else { return false }
        return managerDelegate.isClientCallbackRequired()
    }
    
    func sendEvent(event: Dictionary<String, Any>) {
        delegate?.eventGenerated(event: event)
    }
    
    func performNativeAssist(instruction: Dictionary<String, Any>, view: UIView?, localeCode: String) {
        setupDefaultValues(instruction:instruction, langCode: localeCode, view: view, rect: nil, webview: nil)
        guard let view = currentTargetView else {
            performKeyWindowInstruction(instruction: instruction, iconInfo: [:])
            return
        }
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
              let type = assistInfo[constant_type] as? String else { return }
        performInViewNativeInstruction(instruction: instruction, inView: view, type: type)
    }
    
    func performWebAssist(instruction: Dictionary<String,Any>, rect: CGRect, webview: UIView?, localeCode: String) {
        setupDefaultValues(instruction:instruction, langCode: localeCode, view: nil, rect: rect, webview: webview)
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
              let type = assistInfo[constant_type] as? String,
              let anchorWebview = webview else { return }
        performInViewWebInstruction(instruction: instruction, rect: rect, inWebview: anchorWebview, type: type,iconInfo:nil)
    }
    
    func performNativeDiscovery(instruction: Dictionary<String, Any>, view: UIView?,  localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, Any>, localeHtmlUrl: String?) {
        setupDefaultValues(instruction: instruction, langCode: nil, view: view, rect: nil, webview: nil)
        showLanguageOptions(withLocaleCodes: localeCodes, iconInfo: iconInfo, localeHtmlUrl: localeHtmlUrl) { (languageChose) in
            self.setupDefaultValues(instruction: instruction, langCode: nil, view: view, rect: nil, webview: nil)
            if languageChose {
                guard let anchorView = view else {
                    self.performKeyWindowInstruction(instruction: instruction, iconInfo: iconInfo)
                    return
                }
                guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
                      let type = assistInfo[constant_type] as? String else { return }
                self.performInViewNativeInstruction(instruction: instruction, inView: anchorView, type: type)
                self.dismissJinyButton()
            }
            else { self.presentJinyButton(for: IconSetting(with: iconInfo), iconEnabled: true) }
        }
    }
    
    func performWebDiscovery(instruction: Dictionary<String, Any>, rect: CGRect, webview: UIView?,  localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, Any>, localeHtmlUrl: String?) {
        setupDefaultValues(instruction: instruction, langCode: nil, view: nil, rect: rect, webview: webview)
        showLanguageOptions(withLocaleCodes: localeCodes, iconInfo: iconInfo, localeHtmlUrl: localeHtmlUrl) { (languageChose) in
            if languageChose {
                self.setupDefaultValues(instruction: instruction, langCode: nil, view: nil, rect: rect, webview: webview)
                guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
                      let type = assistInfo[constant_type] as? String,
                      let anchorWebview = webview else { return }
                self.dismissJinyButton()
                self.performInViewWebInstruction(instruction: instruction, rect: rect, inWebview: anchorWebview, type: type,iconInfo:nil)
            }
            else { self.presentJinyButton(for: IconSetting(with: iconInfo), iconEnabled: true) }
        }
    }
    
    func performNativeStage(instruction: Dictionary<String, Any>, view: UIView?, iconInfo: Dictionary<String, Any>) {
        setupDefaultValues(instruction:instruction, langCode: nil, view: view, rect: nil, webview: nil)
        guard let view = currentTargetView else {
            performKeyWindowInstruction(instruction: instruction, iconInfo: nil)
            return
        }
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
              let type = assistInfo[constant_type] as? String else { return }
        performInViewNativeInstruction(instruction: instruction, inView: view, type: type)
        presentJinyButton(for: IconSetting(with: iconInfo), iconEnabled: true)
    }
    
    func performWebStage(instruction: Dictionary<String, Any>, rect: CGRect, webview: UIView?, iconInfo: Dictionary<String, Any>) {
        setupDefaultValues(instruction:instruction, langCode:nil, view: nil, rect: rect, webview: webview)
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
              let type = assistInfo[constant_type] as? String else { return }
        guard let anchorWebview = webview else { return }
        performInViewWebInstruction(instruction: instruction, rect: rect, inWebview: anchorWebview, type: type,iconInfo:nil)
        presentJinyButton(for: IconSetting(with: iconInfo), iconEnabled: true)
    }
    
    func updateRect(rect: CGRect, inWebView: UIView?) {
        
        if let swipePointer = currentAssist as? JinySwipePointer {
            
            swipePointer.updateRect(newRect: rect, inView: inWebView)
        }
        
        if let fingerPointer = currentAssist as? JinyFingerRipplePointer {
            
            fingerPointer.updateRect(newRect: rect, inView: inWebView)
        }
        
        if let label = currentAssist as? JinyLabel {
            
            label.updateRect(newRect: rect, inView: inWebView)
        }
        
        if let tooltip = currentAssist as? JinyToolTip {
            
            tooltip.updatePointer(toRect: rect, inView: inWebView)
        }
        
        if let tooltip = currentAssist as? JinyHighlight {
            
            tooltip.updateHighlight(toRect: rect, inView: inWebView)
        }
        
        if let tooltip = currentAssist as? JinySpot {
            
            tooltip.updateSpot(toRect: rect, inView: inWebView)
        }
        
        if let beacon = currentAssist as? JinyBeacon {
            
            beacon.updateRect(newRect: rect, inView: inWebView)
        }
    }
    
    func updateView(inView view:UIView) {
        if isViewInVisibleArea(view: view) {
            if isViewHiddenByKeyboard(view){ if scrollArrow ==  nil { showArrow() } }
            else {
                scrollArrow?.removeFromSuperview()
                scrollArrow = nil
            }
        } else { if scrollArrow ==  nil { showArrow() } }
    }
    
    func presentLanguagePanel(languages: Array<String>) {
        currentAssist?.remove(byContext: false, byUser: false, autoDismissed: false, panelOpen: true, action: nil)
        currentAssist = nil
        jinyButton?.isHidden = true
        languagePanel = JinyLanguagePanel(withDelegate: self, frame: .zero, languageTexts: languages, theme: UIColor(red: 0.05, green: 0.56, blue: 0.27, alpha: 1.00))
        languagePanel?.presentPanel()
    }
    
    func presentOptionPanel(mute: String, repeatText: String, language: String?) {
        currentAssist?.remove(byContext: false, byUser: false, autoDismissed: false, panelOpen: true, action: nil)
        currentAssist = nil
        jinyButton?.isHidden = true
        optionPanel = JinyOptionPanel(withDelegate: self, repeatText: repeatText, muteText: mute, languageText: language)
        optionPanel?.presentPanel()
    }
    
    func dismissJinyButton() {
        jinyButton?.isHidden = true
    }
    
    func removeAllViews() {
        currentAssist?.remove(byContext: true, byUser: false, autoDismissed: false, panelOpen: false, action: nil)
        currentAssist = nil
        jinyButton?.isHidden = true
    }
    
    func presentJinyButton(for iconSetting: IconSetting, iconEnabled: Bool) {
        guard jinyButton == nil, jinyButton?.window == nil, iconEnabled else {
            JinySharedAUI.shared.iconHtml = iconSetting.htmlUrl
            JinySharedAUI.shared.iconColor = iconSetting.bgColor ?? "#000000"
            jinyButton?.isHidden = false
            return
        }
        JinySharedAUI.shared.iconHtml = iconSetting.htmlUrl
        JinySharedAUI.shared.iconColor = iconSetting.bgColor ?? "#000000"
        jinyButton = JinyMainButton(withThemeColor: UIColor.init(hex: iconSetting.bgColor ?? "#000000") ?? .black, dismissible: iconSetting.dismissible ?? false)
        guard let keyWindow = UIApplication.shared.keyWindow else { return }
        keyWindow.addSubview(jinyButton!)
        jinyButton!.tapGestureRecognizer.addTarget(self, action: #selector(jinyButtonTap))
        jinyButton!.tapGestureRecognizer.delegate = self
        jinyButton!.stateDelegate = self
        jinyButtonBottomConstraint = NSLayoutConstraint(item: keyWindow, attribute: .bottom, relatedBy: .equal, toItem: jinyButton, attribute: .bottom, multiplier: 1, constant: mainIconConstraintConstant)
        jinyButton?.bottomConstraint = jinyButtonBottomConstraint!
        jinyButton?.disableDialog.delegate = self
        var distance = mainIconConstraintConstant
        var cornerAttribute: NSLayoutConstraint.Attribute = .trailing
        if iconSetting.leftAlign ?? false {
            cornerAttribute = .leading
            distance = -mainIconConstraintConstant
        }
        let cornerConstraint = NSLayoutConstraint(item: keyWindow, attribute: cornerAttribute, relatedBy: .equal, toItem: jinyButton, attribute: cornerAttribute, multiplier: 1, constant: distance)
        NSLayoutConstraint.activate([jinyButtonBottomConstraint!, cornerConstraint])
        jinyButton!.htmlUrl = iconSetting.htmlUrl
        jinyButton!.iconSize = mainIconSize
        jinyButton?.configureIconButton()
    }
}

extension JinyAUIManager: UIGestureRecognizerDelegate {
    
    @objc func jinyButtonTap() {
        
        guard let _ = currentAssist else {
            auiManagerCallBack?.jinyTapped()
            return
        }
        presentOptionPanel(mute: "", repeatText: "", language: "")
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension JinyAUIManager: JinyIconStateDelegate {
    func iconDidChange(state: JinyIconState) {
        switch state {
        case .rest:
            DispatchQueue.main.async {
                self.jinyButton?.changeToRest()
            }
        case .loading:
            DispatchQueue.main.async {
                self.jinyButton?.changeToLoading()
            }
        case .audioPlay:
            DispatchQueue.main.async {
                self.jinyButton?.changeToAudioPlay()
            }
        }
    }
}

extension JinyAUIManager: JinyDisableAssistanceDelegate {
    func shouldDisableAssistance() {
        
        auiManagerCallBack?.disableAssistance()
    }
}

// MARK: - Media Fetch And Handling
extension JinyAUIManager {
    
    func startDefaultSoundDownload(_ dict:Dictionary<String,Any>) {
        let langCode = auiManagerCallBack?.getLanguageCode()
        guard let baseUrl = dict[constant_baseUrl] as? String, let code = langCode,
           let allLangSoundsDict = dict[constant_jinySounds] as? Dictionary<String,Any>,
           let soundsDictArray = allLangSoundsDict[code] as? Array<Dictionary<String,Any>> else { return }
        for soundDict in soundsDictArray {
            if let url = soundDict[constant_url] as? String{
                let sound = JinySound(baseUrl: baseUrl, location: url, code: code, info: soundDict)
                mediaManager?.startDownload(forMedia: sound, atPriority: .normal)
            }
        }
    }
    
    func fetchSoundConfig() {
        let url = URL(string: "http://dashboard.jiny.mockable.io/sounds")
        var req = URLRequest(url: url!)
        req.addValue(ASIdentifierManager.shared().advertisingIdentifier.uuidString, forHTTPHeaderField: constant_identifier)
        let session = URLSession.shared
        let configTask = session.dataTask(with: req) { (data, response, error) in
            guard let resultData = data else {
                self.fetchSoundConfig()
                return
            }
            do {
                let audioDict = try JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as! Dictionary<String,Any>
                guard let dataDict = audioDict[constant_data] as? Dictionary<String,Any> else { return }
                let _ = dataDict[constant_baseUrl] as? String
                guard let jinySoundsJson = dataDict[constant_jinySounds] as? Dictionary<String,Array<Dictionary<String,Any>>> else { return }
                self.soundsJson = jinySoundsJson
                self.startStageSoundDownload()
            } catch {
                return
            }
        }
        configTask.resume()
    }
    
    func startStageSoundDownload() {
        guard let code = auiManagerCallBack?.getLanguageCode() else { return }
        guard let soundDictsArray = self.soundsJson?[code] as? Array<Dictionary<String,Any>> else { return }
        for soundDict in soundDictsArray {
            let sound = JinySound(baseUrl: soundDict[constant_url] as! String, location: "", code: code, info: soundDict)
            mediaManager?.startDownload(forMedia: sound, atPriority: .low, completion: { [weak self] (_) in
                DispatchQueue.main.async { self?.playAudio() }
            })
        }
    }
}

extension JinyAUIManager: JinyPointerDelegate {
    
    func pointerPresented() {
        self.didPresentAssist()
    }
    
    func nextClicked() {}
    
    func pointerRemoved() {
        
    }
}

// MARK: - Show Language Options for Discovery
extension JinyAUIManager {
    
    func showLanguageOptions(withLocaleCodes localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, Any>, localeHtmlUrl: String?, handler: ((_ success: Bool) -> Void)? = nil) {
        
        func showLanguageOptions() {
            let auiContent = JinyAUIContent(baseUrl: self.baseUrl, location: localeHtmlUrl ?? "")
            self.mediaManager?.startDownload(forMedia: auiContent, atPriority: .veryHigh, completion: { (success) in
                DispatchQueue.main.async {
                    let jinyLanguageOptions = JinyLanguageOptions(withDict: [:], iconDict: iconInfo, withLanguages: localeCodes, withHtmlUrl: localeHtmlUrl) { success, languageCode in
                        if success, let code = languageCode { JinyPreferences.shared.setUserLanguage(code) }
                        JinyPreferences.shared.currentLanguage = languageCode
                        handler?(success)
                    }
                    UIApplication.shared.keyWindow?.addSubview(jinyLanguageOptions)
                    jinyLanguageOptions.showBottomSheet()
                }
            })
        }
        
        if localeCodes.count == 1 {
            JinyPreferences.shared.currentLanguage = localeCodes.first?[constant_localeId]
            handler?(true)
            return
        }
        guard let userLanguage = JinyPreferences.shared.getUserLanguage() else {
            showLanguageOptions()
            return
        }
        let localeDict = localeCodes.first { $0[constant_localeId] == userLanguage }
        guard let alreadySelectedLanguageDict = localeDict, let langCode = alreadySelectedLanguageDict[constant_localeId] else {
            showLanguageOptions()
            return
        }
        JinyPreferences.shared.currentLanguage = langCode
        handler?(true)
    }
}

// MARK: - PRESENT AUI COMPONENTS
extension JinyAUIManager {
    
    private func setupDefaultValues(instruction:Dictionary<String,Any>, langCode:String?, view:UIView?, rect:CGRect?, webview:UIView?) {
        if let code = langCode { JinyPreferences.shared.currentLanguage = code }
        currentInstruction = instruction
        currentTargetView = view
        currentTargetRect = rect
        currentWebView = webview
    }
    
    private func performInViewNativeInstruction(instruction:Dictionary<String,Any>, inView:UIView, type:String, iconInfo:Dictionary<String,Any>? = nil) {
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any> else { return }
        
        // Autoscroll
        arrowClicked()
        
        //Set autofocus
        inView.becomeFirstResponder()
        
        // Present Assist
        switch type {
        case FINGER_RIPPLE:
            let fingerPointer = JinyFingerRipplePointer(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil)
            currentAssist = fingerPointer
            fingerPointer.pointerDelegate = self
            fingerPointer.presentPointer(view: inView)
            
        case TOOLTIP:
            let tooltip = JinyToolTip(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil)
            currentAssist = tooltip
            tooltip.presentPointer()
            
        case HIGHLIGHT_WITH_DESC:
            let highlight = JinyHighlight(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil)
            currentAssist = highlight
            highlight.presentHighlight()
            
        case SPOT:
            let spot = JinySpot(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil)
            currentAssist = spot
            spot.presentSpot()
            
        case LABEL:
            let label = JinyLabel(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil)
            currentAssist = label
            label.presentLabel()
            
        case BEACON:
            let beacon = JinyBeacon(withDict: assistInfo, toView: inView)
            currentAssist = beacon
            beacon.presentBeacon()
            
        case SWIPE_LEFT, SWIPE_RIGHT, SWIPE_UP, SWIPE_DOWN:
            let swipePointer = JinySwipePointer(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil)
            swipePointer.type = JinySwipePointerType(rawValue: type)!
            currentAssist = swipePointer
            swipePointer.pointerDelegate = self
            swipePointer.presentPointer(view: inView)
        default:
            performKeyWindowInstruction(instruction: instruction, iconInfo: iconInfo)
        }
    }
    
    private func performInViewWebInstruction(instruction:Dictionary<String,Any>, rect:CGRect, inWebview:UIView, type:String, iconInfo:Dictionary<String,Any>? = nil) {
        
        guard  let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any> else { return }
        
        arrowClicked()
        
        if let webIdentfier = assistInfo[constant_identifier] as? String, let focusScript = auiManagerCallBack?.getWebScript(webIdentfier) {
            //Do auto focus for web element
            if let wkweb = inWebview as? WKWebView { wkweb.evaluateJavaScript(focusScript,completionHandler: nil) }
            else if let uiweb = inWebview as? UIWebView { let _ = uiweb.stringByEvaluatingJavaScript(from: focusScript) }
        }
        
        switch type {
        case FINGER_RIPPLE:
            let pointer = JinyFingerRipplePointer(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil)
            currentAssist = pointer
            pointer.pointerDelegate = self
            pointer.presentPointer(toRect: rect, inView: inWebview)
            
        case SWIPE_LEFT, SWIPE_RIGHT, SWIPE_UP, SWIPE_DOWN:
            let swipePointer = JinySwipePointer(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil)
            swipePointer.type = JinySwipePointerType(rawValue: type)!
            currentAssist = swipePointer
            swipePointer.pointerDelegate = self
            swipePointer.presentPointer(toRect: rect, inView: inWebview)
            
        case TOOLTIP:
            let tooltip = JinyToolTip(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil)
            currentAssist = tooltip
            tooltip.presentPointer(toRect: rect, inView: inWebview)
            
        case HIGHLIGHT_WITH_DESC:
            let highlight = JinyHighlight(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil)
            currentAssist = highlight
            highlight.presentHighlight(toRect: rect, inView: inWebview)
            
        case SPOT:
            let spot = JinySpot(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil)
            currentAssist = spot
            spot.presentSpot(toRect: rect, inView: inWebview)
            
        case LABEL:
            let label = JinyLabel(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil)
            currentAssist = label
            label.presentLabel(toRect: rect, inView: inWebview)
            
        case BEACON:
            let beacon = JinyBeacon(withDict: assistInfo, toView: inWebview)
            currentAssist = beacon
            beacon.presentBeacon(toRect: rect, inView: inWebview)
            
        default:
            performKeyWindowInstruction(instruction: instruction, iconInfo: iconInfo)
        }
    }
    
    private func performKeyWindowInstruction(instruction: Dictionary<String, Any>, iconInfo: Dictionary<String, Any>? = [:]) {
        
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any> else {
            auiManagerCallBack?.failedToPerform()
            return
        }
        
        if let type = assistInfo[constant_type] as? String {
            switch type {
            case POPUP:
                let jinyPopup = JinyPopup(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinyPopup
                UIApplication.shared.keyWindow?.addSubview(jinyPopup)
                jinyPopup.showPopup()
            case DRAWER:
                let jinyDrawer = JinyDrawer(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinyDrawer
                UIApplication.shared.keyWindow?.addSubview(jinyDrawer)
                jinyDrawer.showDrawer()
            case FULLSCREEN:
                let jinyFullScreen = JinyFullScreen(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinyFullScreen
                UIApplication.shared.keyWindow?.addSubview(jinyFullScreen)
                jinyFullScreen.showFullScreen()
            case BOTTOMUP:
                let jinyBottomSheet = JinyBottomSheet(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinyBottomSheet
                UIApplication.shared.keyWindow?.addSubview(jinyBottomSheet)
                jinyBottomSheet.showBottomSheet()
            case NOTIFICATION:
                let jinyNotification = JinyNotification(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinyNotification
                UIApplication.shared.keyWindow?.addSubview(jinyNotification)
                jinyNotification.showNotification()
            case SLIDEIN:
                let jinySlideIn = JinySlideIn(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinySlideIn
                UIApplication.shared.keyWindow?.addSubview(jinySlideIn)
                jinySlideIn.showSlideIn()
            case CAROUSEL:
                let jinyCarousel = JinyCarousel(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinyCarousel
                UIApplication.shared.keyWindow?.addSubview(jinyCarousel)
                jinyCarousel.showCarousel()
                
            case PING:
                self.jinyButton?.layoutIfNeeded()
                UIView.animate(withDuration: 0.2) {
                    self.jinyButtonBottomConstraint?.constant = mainIconConstraintConstant
                    self.jinyButton?.layoutIfNeeded()
                }
                jinyButton?.isHidden = true
                
                let jinyPing = JinyPing(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinyPing
                UIApplication.shared.keyWindow?.addSubview(jinyPing)
                jinyPing.showPing()
                
            default:
                break
            }
        }
    }
    
}

extension JinyAUIManager: JinyLanguagePanelDelegate {
    
    func languagePanelPresented() { auiManagerCallBack?.languagePanelOpened() }
    
    func failedToPresentLanguagePanel() {}
    
    func indexOfLanguageSelected(_ languageIndex: Int) { auiManagerCallBack?.languagePanelLanguageSelected(atIndex: languageIndex) }
    
    func languagePanelCloseClicked() { auiManagerCallBack?.languagePanelClosed() }
    
    func languagePanelSwipeDismissed() { auiManagerCallBack?.languagePanelClosed() }
    
    func languagePanelTappedOutside() { auiManagerCallBack?.languagePanelClosed() }
    
}

extension JinyAUIManager: JinyOptionPanelDelegate {
    
    func failedToShowOptionPanel() { auiManagerCallBack?.optionPanelClosed() }
    
    func optionPanelPresented() { auiManagerCallBack?.optionPanelOpened() }
    
    func muteButtonClicked() { auiManagerCallBack?.optionPanelMuteClicked() }
    
    func repeatButtonClicked() { auiManagerCallBack?.optionPanelRepeatClicked() }
    
    func chooseLanguageButtonClicked() {
        guard let langs = auiManagerCallBack?.getLanguages() else {
            auiManagerCallBack?.optionPanelClosed()
            return
        }
        presentLanguagePanel(languages: langs)
    }
    
    func optionPanelDismissed() { auiManagerCallBack?.optionPanelClosed() }
    
    func optionPanelCloseClicked() { auiManagerCallBack?.optionPanelClosed() }
}

extension JinyAUIManager:AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        jinyButton?.iconState = .rest
        startAutoDismissTimer()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        jinyButton?.iconState = .rest
        startAutoDismissTimer()
    }
}

extension JinyAUIManager:AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        startAutoDismissTimer()
    }
}

extension JinyAUIManager:JinyMediaManagerDelegate {
    
}

extension JinyAUIManager {
    
    func isViewInVisibleArea(view:UIView) -> Bool {
        let viewFrame = view.frame
        let windowFrame = UIApplication.shared.keyWindow?.frame
        let viewFrameWRTToWindowFrame = view.superview!.convert(viewFrame, to: nil)
        return windowFrame!.contains(viewFrameWRTToWindowFrame)
    }
    
    func isRectInVisbleArea(rect:CGRect, inView:UIView) -> Bool {
        return inView.frame.contains(rect)
    }
    
    func isViewHiddenByKeyboard(_ view:UIView) -> Bool {
        guard keyboardHeight > 0 else { return false }
        let viewWRTWindow = view.superview!.convert(view.frame, to: nil)
        return viewWRTWindow.origin.y > (UIApplication.shared.keyWindow!.frame.height - CGFloat(keyboardHeight))
    }
    
    func getScrollViews(_ forView:UIView) -> Array<UIView> {
        var scrollViews:Array<UIView> = [forView]
        guard var tempView = forView.superview else { return scrollViews }
        while !tempView.isKind(of: UIWindow.self) {
            if let scrollView = tempView as? UIScrollView { scrollViews.append(scrollView) }
            tempView = tempView.superview!
        }
        return scrollViews
    }
    
    func makeViewVisible(_ nestedScrolls:Array<UIView>,_ animated:Bool) {
        for i in 0..<nestedScrolls.count-1 {
            let parentView = nestedScrolls[nestedScrolls.count - 1 - i]
            let childView = nestedScrolls[nestedScrolls.count - 1 - i - 1]
            if let scroller = parentView as? UIScrollView {
                let childViewRectWRTParent = childView.superview!.convert(childView.frame, to: scroller)
                scroller.scrollRectToVisible(childViewRectWRTParent, animated: animated)
            }
        }
    }
    
    func showArrow() {
        if scrollArrow != nil {
            scrollArrow?.removeFromSuperview()
            scrollArrow = nil
        }
        scrollArrow = UIButton(frame: .zero)
        scrollArrow?.backgroundColor = UIColor.green
        scrollArrow?.layer.cornerRadius = 20
        scrollArrow?.layer.masksToBounds = true
        scrollArrow?.setTitle("↓", for: .normal)
        scrollArrow?.addTarget(self, action: #selector(arrowClicked), for: .touchUpInside)
        let currentVC = UIApplication.getCurrentVC()
        let superView = currentVC!.view
        superView!.addSubview(scrollArrow!)
        scrollArrow?.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConstraint = NSLayoutConstraint(item: scrollArrow!, attribute: .leading, relatedBy: .equal, toItem: superView!, attribute: .leading, multiplier: 1, constant: 20)
        scrollArrowBottomConstraint = NSLayoutConstraint(item: superView!, attribute: .bottom, relatedBy: .equal, toItem: scrollArrow!, attribute: .bottom, multiplier: 1, constant: 20)
        let heightConstraint = NSLayoutConstraint(item: scrollArrow!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 40)
        let widthConstraint = NSLayoutConstraint(item: scrollArrow!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 40)
        NSLayoutConstraint.activate([leadingConstraint, scrollArrowBottomConstraint!, heightConstraint, widthConstraint])
    }
    
    @objc func arrowClicked() {
        guard let assistInfo = currentInstruction?[constant_assistInfo] as? Dictionary<String,Any> else { return }
        let isWeb = assistInfo[constant_isWeb] as? Bool ?? false
        if isWeb {
            guard let webview = currentWebView, let rect = currentTargetRect else { return }
            if let wkweb = webview as? WKWebView {
                wkweb.scrollView.scrollRectToVisible(rect, animated: true)
            } else if let uiweb = webview as? UIWebView {
                uiweb.scrollView.scrollRectToVisible(rect, animated: false)
            }
        } else {
            let nestedScrolls = getScrollViews(currentTargetView!)
            makeViewVisible(nestedScrolls, true)
            let currentVc = UIApplication.getCurrentVC()
            let view = currentVc!.view!
            view.endEditing(true)
        }
        scrollArrow?.removeFromSuperview()
        scrollArrow = nil
    }
    
    func startAutoDismissTimer() {
        guard let instruction = currentAssist, let dismissTimer = instruction.assistInfo?.autoDismissDelay, dismissTimer > 0 else { return }
        if autoDismissTimer != nil {
            autoDismissTimer?.invalidate()
            autoDismissTimer = nil
        }
        autoDismissTimer = Timer.init(timeInterval: dismissTimer/1000, repeats: false, block: { (timer) in
            self.currentAssist?.remove(byContext: false, byUser: false, autoDismissed: true, panelOpen: false, action: nil)
            self.currentAssist = nil
            self.jinyButton?.isHidden = true
            self.autoDismissTimer?.invalidate()
            self.autoDismissTimer = nil
        })
        RunLoop.main.add(autoDismissTimer!, forMode: .default)
    }
}

extension JinyAUIManager: JinyAssistDelegate {
    
    func didPresentAssist() {
        playAudio()
        auiManagerCallBack?.didPresentView()
    }
    
    func failedToPresentAssist() { auiManagerCallBack?.failedToPerform() }
    
    func didDismissAssist(byContext: Bool, byUser: Bool, autoDismissed: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
        currentAssist = nil
        jinyButton?.isHidden = true
        auiManagerCallBack?.didDismissView(byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
    }
    
}
