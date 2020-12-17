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

class JinyAUIManager:NSObject {
    
    weak var auiManagerCallBack:JinyAUICallback?
    
    var keyboardHeight:Float = 0
    var audioPlayer:AVAudioPlayer?
    var pointer:JinyPointer?
    var tooltip: JinyToolTip?
    var highlight: JinyHighlight?
    var beacon: JinyBeacon?
    var spot: JinySpot?
    var label: JinyLabel?
    var optionPanel:JinyOptionPanel?
    var languagePanel:JinyLanguagePanel?
    var jinyButton:JinyMainButton?
    var synthesizer:AVSpeechSynthesizer?
    var utterance:AVSpeechUtterance?
    let audioSession = AVAudioSession.sharedInstance()
    var currentAssist:JinyAssist?
    var mediaManager:JinyMediaManager?
    var soundsJson:Dictionary<String,Any>?
    var scrollArrow:UIButton?
    var currentInstruction:Dictionary<String,Any>?
    weak var currentTargetView:UIView?
    var currentTargetRect:CGRect?
    weak var currentWebView:UIView?
    var jinyButtonBottomConstraint:NSLayoutConstraint?
    var scrollArrowBottomConstraint:NSLayoutConstraint?
    
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
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            keyboardHeight = Float(keyboardRectangle.height)
            if let targetView = currentTargetView {
                if isViewHiddenByKeyboard(targetView) {
                    showArrow()
                    scrollArrowBottomConstraint?.constant = CGFloat(keyboardHeight + 20)
                    scrollArrow?.updateConstraints()
                }
            }
        }
        if jinyButton != nil {
            jinyButtonBottomConstraint?.constant = CGFloat(keyboardHeight + 20)
            jinyButton?.updateConstraints()
        }
    }
    
    @objc func keyboardDidHide(_ notification:NSNotification) {
        keyboardHeight = 0
        guard let assistInfo = currentInstruction?["assist_info"] as? Dictionary<String,Any>, let autoScroll = assistInfo["auto_scroll"] as? Bool else {
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
        
        guard let callback = auiManagerCallBack else { return }
        
        callback.willPlayAudio()
        
        let code = callback.getLanguageCode()
        
        guard let mediaName = currentInstruction?["sound_name"] as? String else { return }
        
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

            } catch let error as NSError {
                
                print(error.description)
            }
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
            
            if let defaultSoundsDict = initialSounds["default_sounds"] {
                self.startDefaultSoundDownload(defaultSoundsDict)
            }
            if let discoverySoundsDict = initialSounds["discovery_sounds"] {
                self.startDefaultSoundDownload(discoverySoundsDict)
            }
            if let auiContentDict = initialSounds["aui_content"] {
                if let baseUrl = auiContentDict["base_url"] as? String, let contents = auiContentDict["content"] as? Array<String> {
                    for content in contents {
                        let auiContent = JinyAUIContent(baseUrl: baseUrl, location: content)
                        self.mediaManager?.startDownload(forMedia: auiContent, atPriority: .low)
                    }
                    if let iconSettingDict = initialSounds["iconSetting"] as? Dictionary<String, IconSetting> {
                        for (_, value) in iconSettingDict {
                            let auiContent = JinyAUIContent(baseUrl: baseUrl, location: value.htmlUrl ?? "")
                            self.mediaManager?.startDownload(forMedia: auiContent, atPriority: .low)
                        }
                    }
                }
            }
            self.fetchSoundConfig()
            
        }
    }
    
    func performInstruction(instruction: Dictionary<String, Any>, inView: UIView, iconInfo:Dictionary<String,Any>) {
        
        currentInstruction = instruction
        currentTargetView = inView
        currentWebView = nil
        currentTargetRect = nil
        
        
        //        guard let _ = instruction["sound_name"] as? String else { return }
        guard let assistInfo = instruction["assist_info"] as? Dictionary<String,Any> else {
            auiManagerCallBack?.failedToPerform()
            return
        }
        
        if let type = assistInfo["type"] as? String {
            auiManagerCallBack?.willPresentView()
            switch type {
                
            case "FINGER_POINTER":
                if !isViewInVisibleArea(view: inView) {
                    if let autoscroll = assistInfo["auto_scroll"] as? Bool {
                        let scrollViews = getScrollViews(inView)
                        if scrollViews.count > 0 {
                            if autoscroll { makeViewVisible(scrollViews, false) }
                            else { showArrow() }
                        }
                    } else {
                        showArrow()
                    }
                }
                
                pointer = JinyFingerRipplePointer()
                pointer?.pointerDelegate = self
                pointer?.presentPointer(view: inView)
                
            case "TOOLTIP":
                tooltip = JinyToolTip(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil)
                currentAssist = tooltip
                tooltip?.delegate = self
                tooltip?.presentPointer()
                
            case "HIGHLIGHT":
                highlight = JinyHighlight(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil)
                currentAssist = highlight
                highlight?.delegate = self
                highlight?.presentPointer()
        
            case "BEACON":
                beacon = JinyBeacon(withDict: assistInfo, toView: inView)
                currentAssist = beacon
                beacon?.delegate = self
                beacon?.presentBeacon()
                
            case "SPOT":
                spot = JinySpot(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil)
                currentAssist = spot
                spot?.delegate = self
                spot?.showSpot()
                
            case "LABEL":
                label = JinyLabel(withDict: assistInfo, iconDict: iconInfo, toView: inView, insideView: nil)
                currentAssist = label
                label?.delegate = self
                label?.presentLabel()
                
            default:
                performKeyWindowInstruction(instruction: instruction, iconInfo: iconInfo)
            }
        }
        
    }
    
    func performInstrcution(instruction: Dictionary<String, Any>, rect: CGRect, inWebview: UIView?, iconInfo:Dictionary<String,Any>) {
        currentInstruction = instruction
        currentTargetView = nil
        currentWebView = inWebview
        currentTargetRect = rect
        guard let _ = instruction["sound_name"] as? String else { return }
        guard let assistInfo = instruction["assist_info"] as? Dictionary<String,Any> else {
            auiManagerCallBack?.failedToPerform()
            return
        }
        if let type = assistInfo["type"] as? String {
            switch type {
                
            case "FINGER_POINTER":
                if !isRectInVisbleArea(rect: rect, inView: inWebview!) {
                    if let autoscroll = assistInfo["auto_scroll"] as? Bool {
                        if autoscroll {
                            if let _ = inWebview as? UIWebView {
                                
                            } else if let wkweb = inWebview as? WKWebView {
                                wkweb.scrollView.scrollRectToVisible(rect, animated: false)
                            }
                        }
                        else {
                            
                        }
                    } else {
                        
                    }
                }
                
                pointer = JinyFingerRipplePointer()
                pointer?.presentPointer(toRect: rect, inView: inWebview)
            default:
                performKeyWindowInstruction(instruction: instruction, iconInfo: iconInfo)
            }
        }
    }
    
    func dismissCurrentAssist() {
        
    }
    
    func performInstruction(instruction: Dictionary<String,Any>) {
        currentInstruction = instruction
        currentTargetView = nil
        currentWebView = nil
        currentTargetRect = nil
        guard let _ = instruction["sound_name"] as? String else { return }
        guard let assistInfo = instruction["assist_info"] as? Dictionary<String,Any> else {
            playAudio()
            return
        }
        if let type = assistInfo["type"] as? String {
            switch type {
                
            case "FINGER_POINTER":
                auiManagerCallBack?.failedToPerform()
                break
            default:
                performKeyWindowInstruction(instruction: instruction)
            }
        }
    }
    
    func performKeyWindowInstruction(instruction: Dictionary<String, Any>, iconInfo: Dictionary<String, Any>? = [:]) {
        guard let _ = instruction["sound_name"] as? String else { return }
        guard let assistInfo = instruction["assist_info"] as? Dictionary<String,Any> else {
            auiManagerCallBack?.failedToPerform()
            return
        }
        
        if let type = assistInfo["type"] as? String {
            switch type {
            case "POPUP":
                let jinyPopup = JinyPopup(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinyPopup
                currentAssist?.delegate = self
                UIApplication.shared.keyWindow?.addSubview(jinyPopup)
                jinyPopup.showPopup()
            case "DRAWER":
                let jinyDrawer = JinyDrawer(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinyDrawer
                currentAssist?.delegate = self
                UIApplication.shared.keyWindow?.addSubview(jinyDrawer)
                jinyDrawer.showDrawer()
            case "FULLSCREEN":
                let jinyFullScreen = JinyFullScreen(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinyFullScreen
                currentAssist?.delegate = self
                UIApplication.shared.keyWindow?.addSubview(jinyFullScreen)
                jinyFullScreen.showFullScreen()
            case "BOTTOM_SHEET":
                let jinyBottomSheet = JinyBottomSheet(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinyBottomSheet
                currentAssist?.delegate = self
                UIApplication.shared.keyWindow?.addSubview(jinyBottomSheet)
                jinyBottomSheet.showBottomSheet()
            case "NOTIFICATION":
                let jinyNotification = JinyNotification(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinyNotification
                currentAssist?.delegate = self
                UIApplication.shared.keyWindow?.addSubview(jinyNotification)
                jinyNotification.showNotification()
            case "SLIDEIN":
                let jinySlideIn = JinySlideIn(withDict: assistInfo, iconDict: iconInfo)
                currentAssist = jinySlideIn
                currentAssist?.delegate = self
                UIApplication.shared.keyWindow?.addSubview(jinySlideIn)
                jinySlideIn.showSlideIn()
            default:
                break
            }
            currentAssist?.delegate = self
        }
    }
    
    func updateRect(rect:CGRect, inWebView:UIView?) {
        
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
        currentAssist?.remove()
        currentAssist = nil
        optionPanel?.dismissOptionPanel { self.optionPanel = nil }
        languagePanel?.dismissLanguagePanel { self.languagePanel = nil }
    }
    
    func removeAllViews() {
        pointer?.removePointer()
        pointer = nil
        currentAssist?.remove()
        currentAssist = nil
        jinyButton?.isHidden = true
    }
    
    func presentJinyButton(with html: String?, color: String) {
        guard jinyButton == nil, jinyButton?.window == nil else {
            jinyButton?.isHidden = false
            return
        }
        JinySharedAUI.shared.iconHtml = html
        JinySharedAUI.shared.iconColor = color
        jinyButton = JinyMainButton(withThemeColor: UIColor.init(hex: color)!)
        guard let keyWindow = UIApplication.shared.keyWindow else { return }
        keyWindow.addSubview(jinyButton!)
        jinyButton!.tapGestureRecognizer.addTarget(self, action: #selector(jinyButtonTap))
        jinyButton!.tapGestureRecognizer.delegate = self
        jinyButton!.stateDelegate = self
        jinyButtonBottomConstraint = NSLayoutConstraint(item: keyWindow, attribute: .bottom, relatedBy: .equal, toItem: jinyButton, attribute: .bottom, multiplier: 1, constant: 45)
        let trailingConst = NSLayoutConstraint(item: keyWindow, attribute: .trailing, relatedBy: .equal, toItem: jinyButton, attribute: .trailing, multiplier: 1, constant: 45)
        NSLayoutConstraint.activate([jinyButtonBottomConstraint!, trailingConst])
        jinyButton!.htmlUrl = html
        jinyButton!.iconSize = 56
        jinyButton?.configureIconButon()
    }
}

extension JinyAUIManager: UIGestureRecognizerDelegate {
    
    @objc func jinyButtonTap() { auiManagerCallBack?.jinyTapped() }
    
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
            mediaManager?.startDownload(forMedia: sound, atPriority: .low, completion: { [weak self] (_) in
                DispatchQueue.main.async {
                    self?.playAudio()
                }
            })
        }
    }
    
    
}

extension JinyAUIManager: JinyPointerDelegate {
    
    func pointerPresented() {
        self.didPresentAssist()
    }
    
    func nextClicked() { auiManagerCallBack?.stagePerformed() }
    
    func pointerRemoved() {
        
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
        self.auiManagerCallBack?.didPlayAudio()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        jinyButton?.iconState = .rest
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

extension JinyAUIManager {
    
    func isViewInVisibleArea(view:UIView) -> Bool {
        let viewFrame = view.frame
        let windowFrame = UIApplication.shared.keyWindow?.frame
        let viewFrameWRTToWindowFrame = view.superview!.convert(viewFrame, to: nil)
        return windowFrame!.contains(viewFrameWRTToWindowFrame)
    }
    
    func isRectInVisbleArea(rect:CGRect, inView:UIView) -> Bool {
        return true
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
        let nestedScrolls = getScrollViews(currentTargetView!)
        makeViewVisible(nestedScrolls, true)
        let currentVc = UIApplication.getCurrentVC()
        let view = currentVc!.view!
        view.endEditing(true)
        scrollArrow?.removeFromSuperview()
        scrollArrow = nil
    }
}

extension JinyAUIManager: JinyAssistDelegate {
    
    func willPresentAssist() { auiManagerCallBack?.willPresentView() }
    
    func didPresentAssist() {
                
        playAudio()
        
        auiManagerCallBack?.didPresentView()
    }
    
    func failedToPresentAssist() { auiManagerCallBack?.failedToPerform() }
    
    func didDismissAssist() { auiManagerCallBack?.didDismissView() }
    
    func didSendAction(dict: Dictionary<String, Any>) {
        auiManagerCallBack?.didReceiveInstruction(dict: dict)
        if let body = dict["body"] as? Dictionary<String,Any> {
            if let opt_in = body["opt_in"] as? Bool {
                if opt_in{
                    auiManagerCallBack?.discoveryOptedInFlow(atIndex: 0)
                }
            }
        }
    }
    
    func didExitAnimation() { auiManagerCallBack?.willDismissView() }
    
    func didTapAssociatedJinyIcon() { auiManagerCallBack?.jinyTapped() }
}

extension JinyAUIManager: JinyBottomDiscoveryDelegate {
    func discoveryPresentedWithOptInButton(_ button: UIButton) {
        
    }
    
    func discoverySheetDismissed() {
        auiManagerCallBack?.discoveryDismissed()
    }
    
    func optOutButtonClicked() {
        auiManagerCallBack?.discoveryDismissed()
    }
    
    func optInButtonClicked() {
        
    }
    
    func discoveryLanguageButtonClicked() {
        
    }
}
