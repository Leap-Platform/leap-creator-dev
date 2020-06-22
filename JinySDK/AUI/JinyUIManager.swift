//
//  JinyUIManager.swift
//  JinySDK
//
//  Created by Aravind GS on 20/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

protocol JinyUIManagerDelegate {
    // Flow selector
    func subFlowSelected(_ flow:JinyFlow)
    
    // Fetch methods
    func getCurrentAudio() -> JinySound?
    func getLanguages() ->Array<String>
    
    // Pointer methods
    func nextClicked()
    
    // Discovery methods
    func discoveryPresented()
    func discoveryMuted()
    func discoveryCompleted()
    func flowOptedIn(atIndex:Int)
    
    // JinyButton methods
    func jinyButtonClicked()
    
    // Option panel methods
    func optionPanelPresented()
    func jinyMuteClicked()
    func repeatButtonClicked()
    func changeLanguageButtonClicked()
    func optionPanelDismissed()
    
    // Language panel methods
    func languagePanelDetected()
    func langugagePanelClosed()
    func langugePanelLanguageSelected(atIndex:Int)
    
}

class JinyUIManager:NSObject {
    
    let delegate:JinyUIManagerDelegate
    var ptr:JinyPointer?
    var audioPlayer:AVAudioPlayer?
    var bottomDiscovery:JinyBottomDiscovery?
    var optionPanel:JinyOptionPanel?
    var languagePanel:JinyLanguagePanel?
    var jinyButton:JinyMainButton?
    var flowSelector:JinyFlowSelector?
    
    init(_ uiManagerDelegate:JinyUIManagerDelegate) {
        delegate = uiManagerDelegate
    }
    
    func presentPointer(ofPointerType:JinyPointerType, forStageType:JinyStageType, toView:UIView) {
        ptr = getPointerType(stageType: forStageType, pointerType: ofPointerType)
        guard let pointer = ptr else { return }
        pointer.pointerDelegate = self
        pointer.toView = toView
        pointer.presentPointer(view: toView)
    }
    
    func presentPointer(ofPointerType:JinyPointerType, forStageType:JinyStageType, toRect:CGRect) {
        removeAllViews()
        ptr = getPointerType(stageType: forStageType, pointerType: ofPointerType)
        guard let pointer = ptr else { return }
        pointer.pointerDelegate = self
        pointer.presentPointer(toRect: toRect)
    }
    
    func updateRect(_ updatedRect:CGRect) {
        
    }
    
    func presentFlowSelector(_ flows:Array<JinyFlow>, _ title:Dictionary<String,Any>) {
        removeAllViews()
        dismissJinyButton()
        flowSelector = JinyFlowSelector(withDelegate: self, listOfFlows: flows, branchTitle: title)
        flowSelector?.setupView()
    }
    
    func getPointerType(stageType:JinyStageType, pointerType:JinyPointerType) -> JinyPointer? {
        var pointer:JinyPointer?
        switch stageType {
        case .Normal:
            if pointerType == .Normal { pointer = JinyFingerRipplePointer()}
            else if pointerType == .NegativeUI { pointer = JinyHighlightManualSequencePointer() }
        case .Sequence:
            pointer = JinyHighlightPointer()
        case .ManualSequence:
            pointer = JinyHighlightManualSequencePointer()
        default:
            pointer = nil
        }
        return pointer
    }
    
    func presentDiscovery(trigger:JinyTrigger, _ langCode:String) {
        dismissJinyButton()
        removeAllViews()
        if trigger.mode == .Single {
            guard let discoveryInfo = trigger.discoveryInfo else { return }
            if discoveryInfo.type == .Bottom{
                let header = (discoveryInfo.triggerText[langCode])?[0] ?? ""
                var langArray = delegate.getLanguages()
                if langArray.count < 2 { langArray = [] }
                let optInText = discoveryInfo.optInText[langCode] ?? ""
                let optOutText = discoveryInfo.optOutText[langCode] ?? ""
                let themeColor = UIColor(red: 0.05, green: 0.56, blue: 0.27, alpha: 1.00)
                bottomDiscovery = JinyBottomDiscovery(withDelegate: self, header: header, jinyLanguages: langArray, optIn: optInText, optOut: optOutText, color: themeColor)
                bottomDiscovery?.presentBottomDiscovery()
            }
        } else {
            
        }
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
    
    func dismissJinyButton() {
        guard let mainButton = jinyButton, mainButton.superview != nil else { return }
        mainButton.removeFromSuperview()
        jinyButton = nil
    }
    
    func presentOptionPanel(repeatText:String, muteText:String, languageText:String?) {
        removeAllViews()
        if optionPanel != nil {
            if optionPanel!.window != nil { optionPanel?.removeFromSuperview() }
            optionPanel = nil
        }
        optionPanel = JinyOptionPanel(withDelegate: self, repeatText: repeatText, muteText: muteText, languageText: languageText)
        optionPanel?.presentPanel()
    }
    
    func presentLanguagePanel() {
        removeAllViews()
        languagePanel = JinyLanguagePanel(withDelegate: self, frame: .zero, languageTexts: delegate.getLanguages(), theme: UIColor(red: 0.05, green: 0.56, blue: 0.27, alpha: 1.00))
        languagePanel?.presentPanel()
    }
    
    @objc func jinyButtonTap() {
        delegate.jinyButtonClicked()
    }
    
    func removeAllViews() {
        ptr?.removePointer()
        flowSelector?.dismissView()
        languagePanel?.dismissLanguagePanel {}
        optionPanel?.dismissOptionPanel {}
        bottomDiscovery?.dismissView(dismissed: {})
        ptr = nil
    }
}

extension JinyUIManager:JinyPointerDelegate {
    
    func pointerPresented() {
        playSound()
    }
    
    func highlightPointerPresented(nextButton: UIButton) {
        let finger = JinyFingerRipplePointer()
        finger.presentPointer(view: nextButton)
        playSound()
    }
    
    func nextClicked() {
        delegate.nextClicked()
        ptr?.removePointer()
        ptr = nil
    }
    
    func pointerRemoved() {
        
    }
    
}

extension JinyUIManager:JinyFlowSelectorDelegate {
    
    func flowSelectorPresented(selectorView: JinyFlowSelector) {
        playSound()
        presentJinyButton()
    }
    
    func failedToSetupFlowSelector(selectorView: JinyFlowSelector) {}
    
    func flowSelected(_ subflow: JinyFlow) { delegate.subFlowSelected(subflow) }
    
    func selectorViewRemoved(selectorView: JinyFlowSelector) {}
    
    func closeButtonClicked() {
        
    }
    
}


extension JinyUIManager {
    
    func playSound() {
        guard let sound = delegate.getCurrentAudio() else { return }
        guard let file = getAudioFileName(sound) else { return }
        let fm = FileManager.default
        guard fm.fileExists(atPath: file) else { return }
        let audioURL = URL.init(fileURLWithPath: file)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL, fileTypeHint: AVFileType.mp3.rawValue)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0
            audioPlayer?.play()
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    func getAudioFileName(_ sound:JinySound) -> String? {
        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let jinyFolder = dir.appendingPathComponent(Constants.Networking.downloadsFolder) as NSString
        let langFolder = jinyFolder.appendingPathComponent(sound.langCode) as NSString
        do {
            let folderContents = try FileManager.default.contentsOfDirectory(atPath: langFolder as String)
            let filteredFileNames = folderContents.filter { (filename) -> Bool in
                return filename.contains(sound.name)
            }
            let sortedFiles = filteredFileNames.sorted { (str1, str2) -> Bool in
                str1.localizedCaseInsensitiveCompare(str2) == ComparisonResult.orderedAscending
            }
            guard let file = sortedFiles.last else {return nil}
            let finalPath = langFolder.appendingPathComponent(file)
            return finalPath
        } catch let error {
            print(error.localizedDescription)
        }
        return nil
    }
    
}


extension JinyUIManager:AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        
    }
    
}

extension JinyUIManager:JinyBottomDiscoveryDelegate {
    
    func discoveryPresentedWithOptInButton(_ button:UIButton) {
        delegate.discoveryPresented()
        presentPointer(ofPointerType: .Normal, forStageType: .Normal, toView: button)
        playSound()
    }
    
    func discoverySheetDismissed() {
        delegate.discoveryMuted()
    }
    
    func optOutButtonClicked() {
        delegate.discoveryMuted()
    }
    
    func optInButtonClicked() {
        delegate.flowOptedIn(atIndex: 0)
        delegate.discoveryCompleted()
    }
    
    func discoveryLanguageButtonClicked() {
        languagePanel = JinyLanguagePanel(withDelegate: self, frame: .zero, languageTexts: delegate.getLanguages(), theme: UIColor(red: 0.05, green: 0.56, blue: 0.27, alpha: 1.00))
        languagePanel?.presentPanel()
    }
    
}

extension JinyUIManager:JinyLanguagePanelDelegate {
    
    func languagePanelCloseClicked() {
        delegate.langugagePanelClosed()
    }
    
    func languagePanelSwipeDismissed() {
        delegate.langugagePanelClosed()
    }
    
    func languagePanelTappedOutside() {
        delegate.langugagePanelClosed()
    }
    
    func languagePanelPresented() {
        delegate.languagePanelDetected()
    }
    
    func failedToPresentLanguagePanel() {
        
    }
    
    func indexOfLanguageSelected(_ languageIndex: Int) {
        delegate.langugePanelLanguageSelected(atIndex: languageIndex)
    }
    
}

extension JinyUIManager:JinyOptionPanelDelegate {
    func failedToShowOptionPanel() {
        
    }
    
    func optionPanelPresented() {
        delegate.optionPanelPresented()
    }
    
    func muteButtonClicked() {
        delegate.jinyMuteClicked()
    }
    
    func repeatButtonClicked() {
        delegate.repeatButtonClicked()
    }
    
    func chooseLanguageButtonClicked() {
        delegate.changeLanguageButtonClicked()
    }
    
    func optionPanelCloseClicked() {
        delegate.optionPanelDismissed()
    }
    
    func optionPanelDismissed() {
        delegate.optionPanelDismissed()
    }
    
}


extension UIImage {
    
    class func getImageFromBundle(_ name:String) -> UIImage? {
        let image = UIImage(named: name, in: Bundle(for: JinyUIManager.self), compatibleWith: nil)
        return image
    }
    
}
