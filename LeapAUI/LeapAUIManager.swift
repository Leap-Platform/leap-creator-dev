//
//  LeapAUIManager.swift
//  LeapAUI
//
//  Created by Aravind GS on 07/07/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import LeapCoreSDK
import AVFoundation
import AdSupport
import WebKit

protocol LeapAUIManagerDelegate: NSObjectProtocol {
    
    func isClientCallbackRequired() -> Bool
    func eventGenerated(event: Dictionary<String,Any>)
}

class LeapAUIManager: NSObject {
    
    weak var auiManagerCallBack: LeapAUICallback?
    weak var delegate: LeapAUIManagerDelegate?
    
    var currentAssist: LeapAssist? { didSet { if let _ = currentAssist { currentAssist?.delegate = self } } }
    
    var keyboardHeight: Float = 0
    var leapButtonBottomConstraint: NSLayoutConstraint?
    
    var audioPlayer: AVAudioPlayer?
    var utterance = AVSpeechUtterance()
    let synthesizer = AVSpeechSynthesizer()
    
    var leapButton: LeapMainButton?
    var leapIconOptions: LeapIconOptions?
    var mediaManager = LeapMediaManager()
    
    var discoverySoundsJson: Dictionary<String,Array<LeapSound>> = [:]
    var stageSoundsJson: Dictionary<String,Array<LeapSound>> = [:]
    lazy var scrollArrowButton = LeapArrowButton(arrowDelegate: self)
    
    var currentInstruction: Dictionary<String,Any>?
    weak var currentTargetView: UIView?
    var currentTargetRect: CGRect?
    weak var currentWebView: UIView?
    
    var autoDismissTimer: Timer?
    private var baseUrl = String()
    
    func addIdentifier(identifier: String, value: Any) {
        auiManagerCallBack?.triggerEvent(identifier: identifier, value: value)
    }
}

extension LeapAUIManager {
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(authLiveNotification(_:)), name: .init("leap_creator_live"), object: nil)
    }
    
    @objc func keyboardDidShow(_ notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
           leapButton != nil
        {
            let keyboardRectangle = keyboardFrame.cgRectValue
            keyboardHeight = Float(keyboardRectangle.height)
            leapButtonBottomConstraint?.constant = CGFloat(keyboardHeight + 20)
            leapButton?.updateConstraints()
        }
    }
    
    @objc func keyboardDidHide(_ notification: NSNotification) {
        keyboardHeight = 0
        if leapButton != nil {
            leapButtonBottomConstraint?.constant = 20.0
            leapButton?.updateConstraints()
        }
    }
    
    @objc func authLiveNotification(_ notification:Notification) { shouldDisableAssistance() }
}


// MARK: - AUIHANDLER METHODS
extension LeapAUIManager: LeapAUIHandler {
    
    func startMediaFetch() {
        
        DispatchQueue.main.async { self.leapButton?.iconState = .loading }
        
        DispatchQueue.global().async {[weak self] in
            
            guard let callback = self?.auiManagerCallBack else { return }
            let initialSounds = callback.getDefaultMedia()
            
            if let discoverySoundsDicts = initialSounds[constant_discoverySounds] as? Array<Dictionary<String,Any>> {
                self?.discoverySoundsJson = self?.processSoundConfigs(configs:discoverySoundsDicts) ?? [:]
                self?.startDiscoverySoundDownload()
            }
            
            var htmlBaseUrl:String?
            if let auiContentDicts = initialSounds[constant_auiContent]  as? Array<Dictionary<String,Any>> {
                for auiContentDict in auiContentDicts {
                    if let baseUrl = auiContentDict[constant_baseUrl] as? String,
                       let contents = auiContentDict[constant_content] as? Array<String> {
                        self?.baseUrl = baseUrl
                        htmlBaseUrl = baseUrl
                        for content in contents {
                            let auiContent = LeapAUIContent(baseUrl: baseUrl, location: content)
                            if let _ = auiContent.url { self?.mediaManager.startDownload(forMedia: auiContent, atPriority: .normal) }
                        }
                    }
                }
            }
            
            if let iconSettingDict = initialSounds[constant_iconSetting] as? Dictionary<String, LeapIconSetting> {
                if let baseUrl = htmlBaseUrl {
                    self?.baseUrl = baseUrl
                    for (_, value) in iconSettingDict {
                        let auiContent = LeapAUIContent(baseUrl: baseUrl, location: value.htmlUrl ?? "")
                        if let _ = auiContent.url { self?.mediaManager.startDownload(forMedia: auiContent, atPriority: .normal) }
                    }
                }
            }
            
            self?.fetchSoundConfig()
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
        guard instruction[constant_assistInfo] as? Dictionary<String,Any> != nil else {
            if let _ = instruction[constant_soundName] as? String { playAudio() }
            return
        }
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
        guard instruction[constant_assistInfo] as? Dictionary<String,Any> != nil else {
            if let _ = instruction[constant_soundName] as? String { playAudio() }
            return
        }
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
              let type = assistInfo[constant_type] as? String,
              let anchorWebview = webview else { return }
        performInViewWebInstruction(instruction: instruction, rect: rect, inWebview: anchorWebview, type: type,iconInfo:nil)
    }
    
    func performNativeDiscovery(instruction: Dictionary<String, Any>, view: UIView?,  localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, AnyHashable>, localeHtmlUrl: String?) {
        setupDefaultValues(instruction: instruction, langCode: nil, view: view, rect: nil, webview: nil)
        showLanguageOptions(withLocaleCodes: localeCodes, iconInfo: iconInfo, localeHtmlUrl: localeHtmlUrl) { (languageChose) in
            self.setupDefaultValues(instruction: instruction, langCode: nil, view: view, rect: nil, webview: nil)
            if languageChose {
                guard let anchorView = view else {
                    self.dismissLeapButton()
                    self.performKeyWindowInstruction(instruction: instruction, iconInfo: iconInfo)
                    return
                }
                guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
                      let type = assistInfo[constant_type] as? String else { return }
                self.performInViewNativeInstruction(instruction: instruction, inView: anchorView, type: type)
                self.dismissLeapButton()
            }
            else { self.presentLeapButton(for: iconInfo, iconEnabled: true) }
        }
    }
    
    func performWebDiscovery(instruction: Dictionary<String, Any>, rect: CGRect, webview: UIView?,  localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, AnyHashable>, localeHtmlUrl: String?) {
        setupDefaultValues(instruction: instruction, langCode: nil, view: nil, rect: rect, webview: webview)
        showLanguageOptions(withLocaleCodes: localeCodes, iconInfo: iconInfo, localeHtmlUrl: localeHtmlUrl) { (languageChose) in
            if languageChose {
                self.setupDefaultValues(instruction: instruction, langCode: nil, view: nil, rect: rect, webview: webview)
                guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
                      let type = assistInfo[constant_type] as? String,
                      let anchorWebview = webview else { return }
                self.dismissLeapButton()
                self.performInViewWebInstruction(instruction: instruction, rect: rect, inWebview: anchorWebview, type: type,iconInfo:nil)
            }
            else { self.presentLeapButton(for: iconInfo, iconEnabled: true) }
        }
    }
    
    func performNativeStage(instruction: Dictionary<String, Any>, view: UIView?, iconInfo: Dictionary<String, AnyHashable>) {
        setupDefaultValues(instruction:instruction, langCode: nil, view: view, rect: nil, webview: nil)
        guard let view = currentTargetView else {
            performKeyWindowInstruction(instruction: instruction, iconInfo: nil)
            presentLeapButton(for: iconInfo, iconEnabled: true)
            return
        }
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
              let type = assistInfo[constant_type] as? String else { return }
        performInViewNativeInstruction(instruction: instruction, inView: view, type: type)
        presentLeapButton(for: iconInfo, iconEnabled: true)
    }
    
    func performWebStage(instruction: Dictionary<String, Any>, rect: CGRect, webview: UIView?, iconInfo: Dictionary<String, AnyHashable>) {
        setupDefaultValues(instruction:instruction, langCode:nil, view: nil, rect: rect, webview: webview)
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
              let type = assistInfo[constant_type] as? String else { return }
        guard let anchorWebview = webview else { return }
        performInViewWebInstruction(instruction: instruction, rect: rect, inWebview: anchorWebview, type: type,iconInfo:nil)
        presentLeapButton(for: iconInfo, iconEnabled: true)
    }
    
    func updateRect(rect: CGRect, inWebView: UIView?) {
        
        if let swipePointer = currentAssist as? LeapSwipePointer { swipePointer.updateRect(newRect: rect, inView: inWebView) }
        else if let fingerPointer = currentAssist as? LeapFingerPointer { fingerPointer.updateRect(newRect: rect, inView: inWebView) }
        else if let label = currentAssist as? LeapLabel { label.updateRect(newRect: rect, inView: inWebView) }
        else if let tooltip = currentAssist as? LeapToolTip { tooltip.updatePointer(toRect: rect, inView: inWebView) }
        else if let highlight = currentAssist as? LeapHighlight { highlight.updateHighlight(toRect: rect, inView: inWebView) }
        else if let spot = currentAssist as? LeapSpot { spot.updateSpot(toRect: rect, inView: inWebView) }
        else if let beacon = currentAssist as? LeapBeacon { beacon.updateRect(newRect: rect, inView: inWebView) }
        scrollArrowButton.updateRect(newRect: rect)

    }
    
    func updateView(inView view: UIView) {
        
        if let swipePointer = currentAssist as? LeapSwipePointer { swipePointer.setPosition() }
        else if let fingerPointer = currentAssist as? LeapFingerPointer { fingerPointer.setPosition() }
        else if let label = currentAssist as? LeapLabel { label.setAlignment() }
        else if let tooltip = currentAssist as? LeapToolTip { tooltip.updatePointer() }
        else if let highlight = currentAssist as? LeapHighlight { highlight.updateHighlight() }
        else if let spot = currentAssist as? LeapSpot { spot.updateSpot() }
        else if let beacon = currentAssist as? LeapBeacon { beacon.setAlignment() }
        scrollArrowButton.checkForView()
    }
    
    func dismissLeapButton() {
        leapButton?.isHidden = true
    }
    
    func removeAllViews() {
        currentAssist?.remove(byContext: true, byUser: false, autoDismissed: false, panelOpen: false, action: nil)
        currentAssist = nil
        currentInstruction = nil
        currentTargetView = nil
        currentTargetRect = nil
        currentWebView = nil
        leapIconOptions?.dismiss(false)
        dismissLeapButton()
    }
    
    func presentLeapButton(for iconInfo: Dictionary<String,AnyHashable>, iconEnabled: Bool) {
        guard iconEnabled, leapIconOptions == nil else {
            if leapIconOptions != nil, leapButton != nil {
            let kw = UIApplication.shared.windows.first{ $0.isKeyWindow }
            if let window = kw {
                window.bringSubviewToFront(leapIconOptions!)
                window.bringSubviewToFront(leapButton!) } }
            return
        }
        let jsonDecoder = JSONDecoder()
        guard let iconData = try? JSONSerialization.data(withJSONObject: iconInfo, options: .prettyPrinted) else { return }
        guard let iconSetting = try? jsonDecoder.decode(LeapIconSetting.self, from: iconData) else { return }
        guard leapButton == nil, leapButton?.window == nil else {
            if !iconSetting.isEqual(LeapSharedAUI.shared.iconSetting) {
                self.leapButton?.removeFromSuperview()
                self.leapButton = nil
                presentLeapButton(for: iconInfo, iconEnabled: iconEnabled)
                return
            }
            leapButton?.isHidden = false
            let kw = UIApplication.shared.windows.first{ $0.isKeyWindow}
            if let keyWindow = kw { keyWindow.bringSubviewToFront(leapButton!) }
            return
        }
        LeapSharedAUI.shared.iconSetting = iconSetting
        leapButton = LeapMainButton(withThemeColor: UIColor.init(hex: iconSetting.bgColor ?? "#00000000") ?? .black, dismissible: iconSetting.dismissible ?? false)
        guard let keyWindow = UIApplication.shared.keyWindow else { return }
        keyWindow.addSubview(leapButton!)
        leapButton!.tapGestureRecognizer.addTarget(self, action: #selector(leapButtonTap))
        leapButton!.tapGestureRecognizer.delegate = self
        leapButton!.stateDelegate = self
        leapButtonBottomConstraint = NSLayoutConstraint(item: keyWindow, attribute: .bottom, relatedBy: .equal, toItem: leapButton, attribute: .bottom, multiplier: 1, constant: mainIconBottomConstant)
        leapButton?.bottomConstraint = leapButtonBottomConstraint!
        leapButton?.disableDialog.delegate = self
        var distance = mainIconCornerConstant
        var cornerAttribute: NSLayoutConstraint.Attribute = .trailing
        if iconSetting.leftAlign ?? false {
            cornerAttribute = .leading
            distance = -mainIconCornerConstant
        }
        let cornerConstraint = NSLayoutConstraint(item: keyWindow, attribute: cornerAttribute, relatedBy: .equal, toItem: leapButton, attribute: cornerAttribute, multiplier: 1, constant: distance)
        NSLayoutConstraint.activate([leapButtonBottomConstraint!, cornerConstraint])
        leapButton!.htmlUrl = iconSetting.htmlUrl
        leapButton!.iconSize = mainIconSize
        leapButton?.configureIconButton()
    }
}


// MARK: - ICON TAP AND GESTURE HANDLING
extension LeapAUIManager: UIGestureRecognizerDelegate {
    
    @objc func leapButtonTap() {
        
        guard let _ = currentAssist else {
            auiManagerCallBack?.leapTapped()
            return
        }
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
        auiManagerCallBack?.optionPanelOpened()
        guard let button = leapButton else { return }
        guard let optionsText = auiManagerCallBack?.getCurrentLanguageOptionsTexts() else { return }
        let stopText = optionsText[constant_stop] ?? "Stop"
        let languageText = optionsText[constant_language]
        leapIconOptions = LeapIconOptions(withDelegate: self, stopText: stopText, languageText: languageText, leapButton: button)
        leapIconOptions?.show()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}


// MARK: - LEAP MAIN BUTTON STATE HANDLING
extension LeapAUIManager: LeapIconStateDelegate {
    func iconDidChange(state: LeapIconState) {
        switch state {
        case .rest:
            DispatchQueue.main.async {
                self.leapButton?.changeToRest()
            }
        case .loading:
            DispatchQueue.main.async {
                self.leapButton?.changeToLoading()
            }
        case .audioPlay:
            DispatchQueue.main.async {
                self.leapButton?.changeToAudioPlay()
            }
        }
    }
}

// MARK: - DISABLE ASSISTANCE DELEGATE METHODS
extension LeapAUIManager: LeapDisableAssistanceDelegate {
    func shouldDisableAssistance() {
        auiManagerCallBack?.disableAssistance()
        removeAllViews()
    }
}

// MARK: - MEDIA FETCH AND HANDLING
extension LeapAUIManager {
    
    func processSoundConfigs(configs: Array<Dictionary<String,Any>>) -> Dictionary<String, Array<LeapSound>> {
        var processedSoundsDict: Dictionary<String,Array<LeapSound>> = [:]
        for config in configs {
            let singleConfigProcessed = processSingleConfig(config: config)
            singleConfigProcessed.forEach { (code, leapSoundsArray) in
                let soundsForEachCode = (processedSoundsDict[code] ?? []) + leapSoundsArray
                processedSoundsDict[code] = soundsForEachCode
            }
        }
        return processedSoundsDict
    }
    
    private func processSingleConfig(config: Dictionary<String,Any>) -> Dictionary<String, Array<LeapSound>> {
        var processedSounds: Dictionary<String,Array<LeapSound>> = [:]
        guard let baseUrl = config[constant_baseUrl] as? String,
              let leapSounds = config[constant_leapSounds] as? Dictionary<String,Array<Dictionary<String,Any>>> else { return processedSounds }
        leapSounds.forEach { (code, soundDictsArray) in
            let processedSoundsArray = self.processLeapSounds(soundDictsArray, code: code, baseUrl: baseUrl)
            let currentCodeSounds =  (processedSounds[code] ?? []) + processedSoundsArray
            processedSounds[code] = currentCodeSounds
        }
        return processedSounds
        
    }
    
    private func processLeapSounds(_ sounds: Array<Dictionary<String,Any>>, code: String, baseUrl: String) -> Array<LeapSound> {
        return sounds.map { (singleSoundDict) -> LeapSound? in
            let url = singleSoundDict[constant_url] as? String
            return LeapSound(baseUrl: baseUrl, location: url, code: code, info: singleSoundDict)
        }.compactMap { return $0 }
    }
    
    func startDiscoverySoundDownload() {
        let code = auiManagerCallBack!.getLanguageCode()
        let discoverySoundsForCode = discoverySoundsJson[code] ?? []
        for sound in discoverySoundsForCode { if sound.url != nil { mediaManager.startDownload(forMedia: sound, atPriority: .normal) } }
    }
    
    func fetchSoundConfig() {
        let url = URL(string: "https://odin-dev-gke.leap.is/odin/api/v1/sounds")
        var req = URLRequest(url: url!)
        guard let token = LeapPreferences.shared.apiKey else { fatalError("No API Key") }
        req.addValue(token, forHTTPHeaderField: "x-jiny-client-id")
        req.addValue(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String, forHTTPHeaderField: "x-app-version-name")
        req.addValue(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String, forHTTPHeaderField: "x-app-version-code")
        let session = URLSession.shared
        let configTask = session.dataTask(with: req) {[weak self] (data, response, error) in
            guard let resultData = data else { return }
            guard let audioDict = try? JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as? Dictionary<String,Any>
            else { return }
            guard let soundConfigs = audioDict[constant_data] as? Array<Dictionary<String,Any>> else { return }
            self?.stageSoundsJson = self?.processSoundConfigs(configs: soundConfigs) ?? [:]
            self?.startStageSoundDownload()
        }
        configTask.resume()
    }
    
    func startStageSoundDownload() {
        let code = auiManagerCallBack!.getLanguageCode()
        let stageSoundsForCode = stageSoundsJson[code] ?? []
        for sound in stageSoundsForCode { if sound.url != nil { mediaManager.startDownload(forMedia: sound, atPriority: .low) } }
    }
    
    func playAudio() {
        DispatchQueue.global().async {
            guard let code = LeapPreferences.shared.currentLanguage,
                  let mediaName = self.currentInstruction?[constant_soundName]  as? String else {
                self.startAutoDismissTimer()
                return
            }
            let soundsArrayForLanguage = self.discoverySoundsJson[code]  ?? []
            var audio = soundsArrayForLanguage.first { $0.name == mediaName }
            if audio ==  nil {
                let stageSounds = self.stageSoundsJson[code] ?? []
                audio = stageSounds.first { $0.name == mediaName }
            }
            guard let currentAudio = audio else {
                self.startAutoDismissTimer()
                return
            }
            if currentAudio.isTTS {
                if let text = currentAudio.text,
                   let ttsCode = self.auiManagerCallBack?.getTTSCodeFor(code: code) {
                    self.tryTTS(text: text, code: ttsCode)
                    return
                }
            }
            let soundPath = LeapSharedAUI.shared.getSoundFilePath(name: mediaName, code: code, format: currentAudio.format)
            let dlStatus = self.mediaManager.getCurrentMediaStatus(currentAudio)
            switch dlStatus {
            case .notDownloaded:
                self.mediaManager.updatePriority(mediaName: mediaName, langCode: code, toPriority: .veryHigh)
                fallthrough
            case .isDownloading:
                self.mediaManager.overrideMediaDownloadCompletion(mediaName, code: code) { [weak self] (success) in
                    guard let instruction = self?.currentInstruction,
                          let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any>,
                          let currentMediaName = assistInfo[constant_soundName] as? String, mediaName == currentMediaName,
                          let newCode = LeapPreferences.shared.currentLanguage, newCode == code, success else { return }
                    self?.playAudioFile(filePath: soundPath)
                }
            case .downloaded:
                self.playAudioFile(filePath: soundPath)
            }
        }
    }
    
    func playAudioFile(filePath: URL) {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            self.audioPlayer = try AVAudioPlayer(contentsOf: filePath)
            self.audioPlayer?.delegate = self
            guard let player = self.audioPlayer else { return }
            player.play()
            if player.isPlaying {
               DispatchQueue.main.async {
                  self.leapButton?.iconState = .audioPlay
               }
            }
        } catch  { }
    }
    
    func tryTTS(text: String, code: String) {
        utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: code)
        utterance.rate = 0.5
        synthesizer.delegate = self
        synthesizer.speak(utterance)
        DispatchQueue.main.async {
           self.leapButton?.iconState = .audioPlay
        }
    }
    
    func stopAudio() {
        
        self.audioPlayer?.stop()
        
        if self.audioPlayer != nil && !(self.audioPlayer?.isPlaying)! {
            self.audioPlayer = nil
            leapButton?.iconState = .rest
            startAutoDismissTimer()
        }
        
        self.synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
    }
}

// MARK: - DISCOVERY LANGUAGE OPTIONS
extension LeapAUIManager {
    
    func showLanguageOptions(withLocaleCodes localeCodes: Array<Dictionary<String, String>>, iconInfo: Dictionary<String, Any>, localeHtmlUrl: String?, handler: ((_ success: Bool) -> Void)? = nil) {
        
        func showLanguageOptions() {
            let auiContent = LeapAUIContent(baseUrl: self.baseUrl, location: localeHtmlUrl ?? "")
            if auiContent.url != nil { self.mediaManager.startDownload(forMedia: auiContent, atPriority: .veryHigh, completion: { (success) in
                DispatchQueue.main.async {
                    let languageOptions = LeapLanguageOptions(withDict: [:], iconDict: iconInfo, withLanguages: localeCodes, withHtmlUrl: localeHtmlUrl, baseUrl: nil) { success, languageCode in
                        if success, let code = languageCode { LeapPreferences.shared.setUserLanguage(code) }
                        LeapPreferences.shared.currentLanguage = languageCode
                        if let webAssist = self.currentAssist as? LeapWebAssist, let code = LeapPreferences.shared.currentLanguage {
                            webAssist.changeLanguage(locale: code)
                        }
                        self.startDiscoverySoundDownload()
                        self.startStageSoundDownload()
                        handler?(success)
                    }
                    languageOptions.showBottomSheet()
                }
            }) }
        }
        
        if localeCodes.count == 1 {
            LeapPreferences.shared.currentLanguage = localeCodes.first?[constant_localeId]
            self.startDiscoverySoundDownload()
            self.startStageSoundDownload()
            handler?(true)
            return
        }
        guard let userLanguage = LeapPreferences.shared.getUserLanguage() else {
            showLanguageOptions()
            return
        }
        let localeDict = localeCodes.first { $0[constant_localeId] == userLanguage }
        guard let alreadySelectedLanguageDict = localeDict, let langCode = alreadySelectedLanguageDict[constant_localeId] else {
            showLanguageOptions()
            return
        }
        LeapPreferences.shared.currentLanguage = langCode
        self.startDiscoverySoundDownload()
        self.startStageSoundDownload()
        handler?(true)
    }
}

// MARK: - PRESENT AUI COMPONENTS
extension LeapAUIManager {
    
    private func setupDefaultValues(instruction: Dictionary<String,Any>, langCode: String?, view: UIView?, rect: CGRect?, webview: UIView?) {
        if let code = langCode {
            LeapPreferences.shared.currentLanguage = code
            self.startDiscoverySoundDownload()
            self.startStageSoundDownload()
        }
        currentInstruction = instruction
        currentTargetView = view
        currentTargetRect = rect
        currentWebView = webview
    }
    
    private func performInViewNativeInstruction(instruction: Dictionary<String,Any>, inView: UIView, type: String, iconInfo: Dictionary<String,Any>? = nil) {
        guard let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any> else { return }
        scrollArrowButton.setView(view: inView)
        //Set autofocus
        inView.becomeFirstResponder()
        
        // Present Assist
        switch type {
        case FINGER_RIPPLE:
            let fingerPointer = LeapFingerPointer(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil,baseUrl: nil)
            currentAssist = fingerPointer
            fingerPointer.presentPointer(view: inView)
            
        case TOOLTIP:
            let tooltip = LeapToolTip(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil, baseUrl: baseUrl)
            currentAssist = tooltip
            tooltip.presentPointer()
            
        case HIGHLIGHT_WITH_DESC:
            let highlight = LeapHighlight(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil, baseUrl: baseUrl)
            currentAssist = highlight
            highlight.presentHighlight()
            
        case SPOT:
            let spot = LeapSpot(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil, baseUrl: baseUrl)
            currentAssist = spot
            spot.presentSpot()
            
        case LABEL:
            let label = LeapLabel(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil, baseUrl: baseUrl)
            currentAssist = label
            label.presentLabel()
            
        case BEACON:
            let beacon = LeapBeacon(withDict: assistInfo, toView: inView)
            currentAssist = beacon
            beacon.presentBeacon()
            
        case SWIPE_LEFT, SWIPE_RIGHT, SWIPE_UP, SWIPE_DOWN:
            let swipePointer = LeapSwipePointer(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil, baseUrl: nil)
            swipePointer.type = LeapSwipePointerType(rawValue: type)!
            currentAssist = swipePointer
            swipePointer.presentPointer(view: inView)
        default:
            performKeyWindowInstruction(instruction: instruction, iconInfo: iconInfo)
        }
    }
    
    private func performInViewWebInstruction(instruction: Dictionary<String,Any>, rect: CGRect, inWebview: UIView, type: String, iconInfo: Dictionary<String,Any>? = nil) {
        
        guard  let assistInfo = instruction[constant_assistInfo] as? Dictionary<String,Any> else { return }
        if let wkweb = inWebview as? WKWebView { scrollArrowButton.setRect(rect, in: wkweb) }
        
        if let webIdentfier = assistInfo[constant_identifier] as? String, let focusScript = auiManagerCallBack?.getWebScript(webIdentfier) {
            //Do auto focus for web element
            if let wkweb = inWebview as? WKWebView { wkweb.evaluateJavaScript(focusScript,completionHandler: nil) }
        }
        
        switch type {
        case FINGER_RIPPLE:
            let pointer = LeapFingerPointer(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil, baseUrl: nil)
            currentAssist = pointer
            pointer.presentPointer(toRect: rect, inView: inWebview)
            
        case SWIPE_LEFT, SWIPE_RIGHT, SWIPE_UP, SWIPE_DOWN:
            let swipePointer = LeapSwipePointer(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil, baseUrl: nil)
            swipePointer.type = LeapSwipePointerType(rawValue: type)!
            currentAssist = swipePointer
            swipePointer.presentPointer(toRect: rect, inView: inWebview)
            
        case TOOLTIP:
            let tooltip = LeapToolTip(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil, baseUrl: baseUrl)
            currentAssist = tooltip
            tooltip.presentPointer(toRect: rect, inView: inWebview)
            
        case HIGHLIGHT_WITH_DESC:
            let highlight = LeapHighlight(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil, baseUrl: baseUrl)
            currentAssist = highlight
            highlight.presentHighlight(toRect: rect, inView: inWebview)
            
        case SPOT:
            let spot = LeapSpot(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil, baseUrl: baseUrl)
            currentAssist = spot
            spot.presentSpot(toRect: rect, inView: inWebview)
            
        case LABEL:
            let label = LeapLabel(withDict: assistInfo, iconDict: iconInfo, toView: inWebview, insideView: nil, baseUrl: baseUrl)
            currentAssist = label
            label.presentLabel(toRect: rect, inView: inWebview)
            
        case BEACON:
            let beacon = LeapBeacon(withDict: assistInfo, toView: inWebview)
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
                let popup = LeapPopup(withDict: assistInfo, iconDict: iconInfo, baseUrl: baseUrl)
                currentAssist = popup
                popup.showPopup()
            case DRAWER:
                let drawer = LeapDrawer(withDict: assistInfo, iconDict: iconInfo, baseUrl: baseUrl)
                currentAssist = drawer
                drawer.showDrawer()
            case FULLSCREEN:
                let fullScreen = LeapFullScreen(withDict: assistInfo, iconDict: iconInfo, baseUrl: baseUrl)
                currentAssist = fullScreen
                fullScreen.showFullScreen()
            case BOTTOMUP:
                let bottomSheet = LeapBottomSheet(withDict: assistInfo, iconDict: iconInfo, baseUrl: baseUrl)
                currentAssist = bottomSheet
                bottomSheet.showBottomSheet()
            case NOTIFICATION:
                let notification = LeapNotification(withDict: assistInfo, iconDict: iconInfo, baseUrl: baseUrl)
                currentAssist = notification
                notification.showNotification()
            case SLIDEIN:
                let slideIn = LeapSlideIn(withDict: assistInfo, iconDict: iconInfo, baseUrl: baseUrl)
                currentAssist = slideIn
                slideIn.showSlideIn()
            case CAROUSEL:
                let carousel = LeapCarousel(withDict: assistInfo, iconDict: iconInfo, baseUrl: baseUrl)
                currentAssist = carousel
                carousel.showCarousel()
                
            case PING:
                self.leapButton?.layoutIfNeeded()
                UIView.animate(withDuration: 0.2) {
                    self.leapButtonBottomConstraint?.constant = mainIconBottomConstant
                    self.leapButton?.layoutIfNeeded()
                }
                dismissLeapButton()
                let ping = LeapPing(withDict: assistInfo, iconDict: iconInfo, baseUrl: nil)
                currentAssist = ping
                ping.showPing()
                
            default:
                break
            }
        }
    }
}

// MARK: - AUDIO PLAYER DELEGATES
extension LeapAUIManager: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.audioPlayer = nil
        leapButton?.iconState = .rest
        startAutoDismissTimer()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        self.audioPlayer = nil
        leapButton?.iconState = .rest
        startAutoDismissTimer()
    }
}

// MARK: - TTS HANDLING
extension LeapAUIManager: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        leapButton?.iconState = .rest
        startAutoDismissTimer()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        leapButton?.iconState = .rest
        startAutoDismissTimer()
    }
}

// MARK: - ARROW AND KEYBOARD HANDLING
extension LeapAUIManager {
    
    func startAutoDismissTimer() {
        guard let instruction = currentAssist, let dismissTimer = instruction.assistInfo?.autoDismissDelay else { return }
        if autoDismissTimer != nil {
            autoDismissTimer?.invalidate()
            autoDismissTimer = nil
        }
        autoDismissTimer = Timer.init(timeInterval: dismissTimer/1000, repeats: false, block: { (timer) in
            self.currentAssist?.remove(byContext: false, byUser: false, autoDismissed: true, panelOpen: false, action: nil)
            self.currentAssist = nil
            self.dismissLeapButton()
            self.autoDismissTimer?.invalidate()
            self.autoDismissTimer = nil
        })
        RunLoop.main.add(autoDismissTimer!, forMode: .default)
    }
}

// MARK: - CURRENT ASSIST DELEGATE METHODS
extension LeapAUIManager: LeapAssistDelegate {
    
    func didPresentAssist() {
        playAudio()
        auiManagerCallBack?.didPresentView()
    }
    
    func failedToPresentAssist() { auiManagerCallBack?.failedToPerform() }
    
    func didDismissAssist(byContext: Bool, byUser: Bool, autoDismissed: Bool, panelOpen: Bool, action: Dictionary<String, Any>?) {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
        currentAssist = nil
        stopAudio()
        scrollArrowButton.noAssist()
        dismissLeapButton()
        auiManagerCallBack?.didDismissView(byUser: byUser, autoDismissed: autoDismissed, panelOpen: panelOpen, action: action)
    }    
}

// MARK: - ICON OPTIONS DELEGATE METHODS
extension LeapAUIManager:LeapIconOptionsDelegate {
    
    func stopClicked() {
        removeAllViews()
        currentInstruction = nil
        currentTargetView = nil
        currentTargetRect = nil
        currentWebView = nil
        auiManagerCallBack?.optionPanelStopClicked()
    }
    
    func languageClicked() {
        guard let localeCodes = auiManagerCallBack?.getLanguagesForCurrentInstruction(),
              let iconInfo = auiManagerCallBack?.getIconInfoForCurrentInstruction(),
              let htmlUrl = auiManagerCallBack?.getLanguageHtmlUrl() else {
            auiManagerCallBack?.optionPanelOpened()
            return
        }
        let leapLanguageOptions = LeapLanguageOptions(withDict: [:], iconDict: iconInfo, withLanguages: localeCodes, withHtmlUrl: htmlUrl, baseUrl: nil) { success, languageCode in
            if success, let code = languageCode { LeapPreferences.shared.setUserLanguage(code) }
            LeapPreferences.shared.currentLanguage = languageCode
            if let webAssist = self.currentAssist as? LeapWebAssist, let code = LeapPreferences.shared.currentLanguage {
                webAssist.changeLanguage(locale: code)
            }
            self.startDiscoverySoundDownload()
            self.startStageSoundDownload()
            self.auiManagerCallBack?.optionPanelClosed()
            
        }
        leapLanguageOptions.showBottomSheet()
        
    }
    
    func iconOptionsClosed() {
        auiManagerCallBack?.optionPanelClosed()
    }
    
    func iconOptionsDismissed() {
        leapIconOptions = nil
    }
}


// MARK: - ARROW BUTTON DELEGATES
extension LeapAUIManager:LeapArrowButtonDelegate {
    
    func arrowShown() {
    }
    
    func arrowHidden() {
        
    }
    
}
