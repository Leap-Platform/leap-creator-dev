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

class JinyAUIManager:NSObject {
    
    weak var auiManagerCallBack:JinyAUICallback?
    
    var audioPlayer:AVAudioPlayer?
    var pointer:JinyPointer?
    var bottomDiscovery:JinyBottomDiscovery?
    var optionPanel:JinyOptionPanel?
    var languagePanel:JinyLanguagePanel?
    var jinyButton:JinyMainButton?
    var jinyFlowSelector:JinyFlowSelector?
    var synthesizer:AVSpeechSynthesizer?
    var utterance:AVSpeechUtterance?
    let audioSession = AVAudioSession.sharedInstance()
    var mediaManager:JinyMediaManager?
    var soundsJson:Dictionary<String,Any>?
    
    func addIdentifier(identifier:String, value:Any) {
        auiManagerCallBack?.triggerEvent(identifier: identifier, value: value)
    }
    
}

extension JinyAUIManager:JinyAUIHandler {
    
    func startMediaFetch() {
        mediaManager = JinyMediaManager(withDelegate: self)
        guard let callback = auiManagerCallBack else { return }
        let initialSounds = callback.getDefaultMedia()
        
        if let defaultSoundsDict = initialSounds["default_sounds"] {
            startDefaultSoundDownload(defaultSoundsDict)
        }
        if let discoverySoundsDict = initialSounds["discovery_sounds"] {
            startDefaultSoundDownload(discoverySoundsDict)
        }
        if let auiContentDict = initialSounds["aui_content"] {
            if let baseUrl = auiContentDict["base_url"] as? String, let contents = auiContentDict["content"] as? Array<String> {
                for content in contents {
                    let auiContent = JinyAUIContent(baseUrl: baseUrl, location: content)
                    mediaManager?.startDownload(forMedia: auiContent, atPriority: .low)
                }
            }
        }
        fetchSoundConfig()
    }
    
    func performInstruction(instruction: Dictionary<String, Any>, inView: UIView) {
        guard let soundName = instruction["sound_name"] as? String else { return }
        guard let assistInfo = instruction["assist_info"] as? Dictionary<String,Any> else {
            auiManagerCallBack?.failedToPerform()
            return
        }
        if let type = assistInfo["type"] as? String {
            auiManagerCallBack?.willPresentView()
            switch type {
            case "POPUP":
                let jinyPopup = JinyPopup(withDict: assistInfo)
                UIApplication.shared.keyWindow?.addSubview(jinyPopup)
                jinyPopup.showPopup()
            case "DRAWER":
                let jinyDrawer = JinyDrawer(withDict: assistInfo)
                UIApplication.shared.keyWindow?.addSubview(jinyDrawer)
                jinyDrawer.showDrawer()
            case "FULLSCREEN":
                let jinyFullScreen = JinyFullScreen(withDict: assistInfo)
                UIApplication.shared.keyWindow?.addSubview(jinyFullScreen)
                jinyFullScreen.showFullScreen()
            case "BOTTOM_SHEET":
                let jinyBottomSheet = JinyBottomSheet(withDict: assistInfo)
                UIApplication.shared.keyWindow?.addSubview(jinyBottomSheet)
                jinyBottomSheet.showBottomSheet()
            default:
                break
            }
            auiManagerCallBack?.didPresentView()
        }
        
    }
    
    func performInstrcution(instruction: Dictionary<String, Any>, rect: CGRect, inWebview: UIView?) {
        guard let soundName = instruction["sound_name"] as? String else { return }
        guard let assistInfo = instruction["assist_info"] as? Dictionary<String,Any> else {
            auiManagerCallBack?.failedToPerform()
            return
        }
        if let type = assistInfo["type"] as? String {
            auiManagerCallBack?.willPresentView()
            switch type {
            case "POPUP":
                let jinyPopup = JinyPopup(withDict: assistInfo)
                UIApplication.shared.keyWindow?.addSubview(jinyPopup)
                jinyPopup.showPopup()
            case "DRAWER":
                let jinyDrawer = JinyDrawer(withDict: assistInfo)
                UIApplication.shared.keyWindow?.addSubview(jinyDrawer)
                jinyDrawer.showDrawer()
            case "FULLSCREEN":
                let jinyFullScreen = JinyFullScreen(withDict: assistInfo)
                UIApplication.shared.keyWindow?.addSubview(jinyFullScreen)
                jinyFullScreen.showFullScreen()
            case "BOTTOM_SHEET":
                let jinyBottomSheet = JinyBottomSheet(withDict: assistInfo)
                UIApplication.shared.keyWindow?.addSubview(jinyBottomSheet)
                jinyBottomSheet.showBottomSheet()
            default:
                break
            }
            auiManagerCallBack?.didPresentView()
        }
    }
    
    func updateRect(rect:CGRect, inWebView:UIView?) {
        
    }
    
    func playAudio() {
        self.auiManagerCallBack?.willPlayAudio()
        if let tts = auiManagerCallBack?.tryTTS() {
            synthesizer = AVSpeechSynthesizer()
            synthesizer?.delegate = self
            utterance = AVSpeechUtterance(string: tts)
            utterance!.voice = AVSpeechSynthesisVoice(language: "hi-IN")
            utterance!.rate = 0.4
            do {
                try audioSession.setCategory(.playback, options: [.duckOthers])
                try audioSession.setActive(true)
            } catch {
                
            }
            synthesizer!.speak(utterance!)
        } else {
            guard let file = auiManagerCallBack?.getAudioFilePath() else { return }
            let fm = FileManager.default
            guard fm.fileExists(atPath: file) else { return }
            let audioURL = URL.init(fileURLWithPath: file)
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: audioURL, fileTypeHint: AVFileType.mp3.rawValue)
                audioPlayer?.delegate = self
                audioPlayer?.volume = 1.0
                do {
                    try audioSession.setCategory(.playback, options: [.duckOthers])
                    try audioSession.setActive(true)
                } catch {
                    
                }
                audioPlayer?.play()
                
            } catch {
                print(error.localizedDescription)
            }
        }
        
        
    }
    
    
    func playTTS(withLangCode:String) {
        
    }
    
    func presentJinyButton() {
        guard jinyButton == nil, jinyButton?.window == nil else { return }
        jinyButton = JinyMainButton(withThemeColor: UIColor(red: 0.05, green: 0.56, blue: 0.27, alpha: 1.00))
        guard let keyWindow = UIApplication.shared.keyWindow else { return }
        keyWindow.addSubview(jinyButton!)
        jinyButton!.addTarget(self, action: #selector(jinyButtonTap), for: .touchUpInside)
        let bottomConst = NSLayoutConstraint(item: keyWindow, attribute: .bottom, relatedBy: .equal, toItem: jinyButton, attribute: .bottom, multiplier: 1, constant: 45)
        let trailingConst = NSLayoutConstraint(item: keyWindow, attribute: .trailing, relatedBy: .equal, toItem: jinyButton, attribute: .trailing, multiplier: 1, constant: 45)
        NSLayoutConstraint.activate([bottomConst, trailingConst])
    }
    
    @objc func jinyButtonTap() { auiManagerCallBack?.jinyTapped() }
    
    func presentBottomDiscovery(header: String, optInText: String, optOutText: String, languages:Array<String>) {
        bottomDiscovery = JinyBottomDiscovery(withDelegate: self, header: header, jinyLanguages: languages, optIn: optInText, optOut: optOutText, color: UIColor(red: 0.05, green: 0.56, blue: 0.27, alpha: 1.00))
        bottomDiscovery?.presentBottomDiscovery()
        
    }
    
    func presentPingDiscovery() {
        
    }
    
    func presentFlowSelector(branchTitle: String, flowTitles: Array<String>) {
        if jinyFlowSelector != nil {
            jinyFlowSelector?.dismissView()
            jinyFlowSelector = nil
        }
        self.auiManagerCallBack?.willPresentView()
        jinyFlowSelector = JinyFlowSelector(withDelegate: self, listOfFlows: flowTitles, branchTitle: branchTitle)
        jinyFlowSelector?.setupView()
    }
    
    func presentPointer(toView: UIView, ofType: JinyPointerStyle) {
        pointer?.removePointer()
        pointer = nil
        switch ofType {
        case .FingerRipple:
            pointer = JinyFingerRipplePointer()
            break
        case .NegativeUI:
            pointer = JinyHighlightManualSequencePointer()
            break
        }
        pointer?.pointerDelegate = self
        self.auiManagerCallBack?.willPresentView()
        pointer?.presentPointer(view: toView)
    }
    
    func presentPointer(toRect: CGRect, inView: UIView?, ofType: JinyPointerStyle) {
        pointer?.removePointer()
        pointer = nil
        switch ofType {
        case .FingerRipple:
            pointer = JinyFingerRipplePointer()
            break
        case .NegativeUI:
            pointer = JinyHighlightManualSequencePointer()
            break
        }
        pointer?.pointerDelegate = self
        self.auiManagerCallBack?.willPresentView()
        pointer?.presentPointer(toRect: toRect, inView: inView)
    }
    
    func updatePointerRect(newRect: CGRect, inView: UIView?) {
        guard pointer != nil else { return }
        pointer!.updateRect(newRect: newRect, inView: inView)
    }
    
    func presentLanguagePanel(languages: Array<String>) {
        removeAllViews()
        languagePanel = JinyLanguagePanel(withDelegate: self, frame: .zero, languageTexts: languages, theme: UIColor(red: 0.05, green: 0.56, blue: 0.27, alpha: 1.00))
        languagePanel?.presentPanel()
    }
    
    func presentOptionPanel(mute: String, repeatText: String, language: String?) {
        removeAllViews()
        optionPanel = JinyOptionPanel(withDelegate: self, repeatText: repeatText, muteText: mute, languageText: language)
        optionPanel?.presentPanel()
    }
    
    func dismissJinyButton() {
        guard let mainButton = jinyButton, mainButton.superview != nil else { return }
        mainButton.removeFromSuperview()
        jinyButton = nil
    }
    
    func keepOnlyJinyButtonIfPresent() {
        
        pointer?.removePointer()
        pointer = nil
        
        bottomDiscovery?.dismissView { self.bottomDiscovery = nil }
        
        optionPanel?.dismissOptionPanel { self.optionPanel = nil }
        
        languagePanel?.dismissLanguagePanel { self.languagePanel = nil }
        
        jinyFlowSelector?.dismissView()
        jinyFlowSelector = nil
        
    }
    
    func removeAllViews() {
        
        keepOnlyJinyButtonIfPresent()
        dismissJinyButton()
    }
    
}


// MARK: - Media Fetch And Handling
extension JinyAUIManager {
    
    func startDefaultSoundDownload(_ dict:Dictionary<String,Any>) {
        let langCode = auiManagerCallBack?.getLanguageCode()
        if let baseUrl = dict["base_url"] as? String, let code = langCode {
            if let allLangSoundsDict = dict["jiny_sounds"] as? Dictionary<String,Any>,
                let soundsDictArray = allLangSoundsDict[code] as? Array<Dictionary<String,Any>> {
                for soundDict in soundsDictArray {
                    if let url = soundDict["url"] as? String{
                        let sound = JinySound(baseUrl: baseUrl, location: url, code: code, info: soundDict)
                        mediaManager?.startDownload(forMedia: sound, atPriority: .normal)
                    }
                    
                }
            }
        }
    }
    
    func fetchSoundConfig() {
        let url = URL(string: "http://dashboard.jiny.mockable.io/sounds")
        var req = URLRequest(url: url!)
        req.addValue(ASIdentifierManager.shared().advertisingIdentifier.uuidString, forHTTPHeaderField: "identifier")
        let session = URLSession.shared
        let configTask = session.dataTask(with: req) { (data, response, error) in
            guard let resultData = data else {
                self.fetchSoundConfig()
                return
            }
            do {
                let audioDict = try JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as! Dictionary<String,Any>
                guard let dataDict = audioDict["data"] as? Dictionary<String,Any> else { return }
                let _ = dataDict["base_url"] as? String
                guard let jinySoundsJson = dataDict["jiny_sounds"] as? Dictionary<String,Array<Dictionary<String,Any>>> else { return }
                self.soundsJson = jinySoundsJson
                self.startStageSoundDownload()
            } catch {
                print("Error")
                return
            }
        }
        configTask.resume()
    }
    
    func startStageSoundDownload() {
        guard let code = auiManagerCallBack?.getLanguageCode() else { return }
        guard let soundDictsArray = self.soundsJson?[code] as? Array<Dictionary<String,Any>> else { return }
        for soundDict in soundDictsArray {
            let sound = JinySound(baseUrl: soundDict["url"] as! String, location: "", code: code, info: soundDict)
            mediaManager?.startDownload(forMedia: sound, atPriority: .low)
        }
    }
    
    
}


extension JinyAUIManager:JinyPointerDelegate {
    
    func pointerPresented() {
        self.auiManagerCallBack?.didPresentView()
        playAudio()
    }
    
    func nextClicked() { auiManagerCallBack?.stagePerformed() }
    
    func pointerRemoved() {
        
    }
}

extension JinyAUIManager:JinyBottomDiscoveryDelegate {
    
    func discoveryPresentedWithOptInButton(_ button: UIButton) {
        presentPointer(toView: button, ofType: .FingerRipple)
        auiManagerCallBack?.discoveryPresented()
        auiManagerCallBack?.didPresentView()
    }
    
    func discoverySheetDismissed() {
        auiManagerCallBack?.discoveryMuted()
        auiManagerCallBack?.didDismissView()
    }
    
    func optOutButtonClicked() {
        auiManagerCallBack?.discoveryMuted()
        auiManagerCallBack?.didDismissView()
    }
    
    func optInButtonClicked() {
        auiManagerCallBack?.didDismissView()
        auiManagerCallBack?.discoveryOptedInFlow(atIndex: 0)
    }
    
    func discoveryLanguageButtonClicked() {
        auiManagerCallBack?.didDismissView()
        guard let langs = auiManagerCallBack?.getLanguages() else {
            auiManagerCallBack?.discoveryReset()
            return
        }
        presentLanguagePanel(languages: langs)
    }
    
}

extension JinyAUIManager:JinyLanguagePanelDelegate {
    
    func languagePanelPresented() {
        auiManagerCallBack?.languagePanelOpened()
    }
    
    func failedToPresentLanguagePanel() {}
    
    func indexOfLanguageSelected(_ languageIndex: Int) { auiManagerCallBack?.languagePanelLanguageSelected(atIndex: languageIndex) }
    
    func languagePanelCloseClicked() { auiManagerCallBack?.languagePanelClosed() }
    
    func languagePanelSwipeDismissed() { auiManagerCallBack?.languagePanelClosed() }
    
    func languagePanelTappedOutside() { auiManagerCallBack?.languagePanelClosed() }
    
}

extension JinyAUIManager:JinyOptionPanelDelegate {
    
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

extension JinyAUIManager:JinyFlowSelectorDelegate {
    
    func failedToSetupFlowSelector() { auiManagerCallBack?.flowSelectorDismissed() }
    
    func flowSelectorPresented() {
        auiManagerCallBack?.flowSelectorPresented()
        playAudio()
    }
    
    func flowSelected(_ flowSelectedAtIndex: Int) { auiManagerCallBack?.flowSelectorFlowSelected(atIndex:flowSelectedAtIndex) }
    
    func selectorViewRemoved() { auiManagerCallBack?.flowSelectorDismissed() }
    
    func closeButtonClicked() { auiManagerCallBack?.flowSelectorDismissed() }
    
}

extension JinyAUIManager:AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.auiManagerCallBack?.didPlayAudio()
        if pointer != nil {
            if pointer!.isMember(of: JinyHighlightPointer.self) { auiManagerCallBack?.stagePerformed() }
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        self.auiManagerCallBack?.didPlayAudio()
    }
    
}

extension JinyAUIManager:AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        auiManagerCallBack?.didPlayAudio()
    }
    
}

extension JinyAUIManager:JinyMediaManagerDelegate {
    
}
