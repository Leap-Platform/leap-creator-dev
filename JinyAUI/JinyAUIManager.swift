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

class JinyAUIManager:NSObject {
    
    weak var auiManagerCallBack:JinyAUICallback?
    
    var audioPlayer:AVAudioPlayer?
    var pointer:JinyPointer?
    var bottomDiscovery:JinyBottomDiscovery?
    var optionPanel:JinyOptionPanel?
    var languagePanel:JinyLanguagePanel?
    var jinyButton:JinyMainButton?
    var jinyFlowSelector:JinyFlowSelector?
    
    
}

extension JinyAUIManager:JinyAUIHandler {
    
    func playAudio() {
        guard let file = auiManagerCallBack?.getAudioFilePath() else { return }
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


extension JinyAUIManager:JinyPointerDelegate {
    
    func pointerPresented() { playAudio() }
    
    func nextClicked() { auiManagerCallBack?.stagePerformed() }
    
    func pointerRemoved() { }
}

extension JinyAUIManager:AVAudioPlayerDelegate {
 
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if pointer != nil {
            if pointer!.isMember(of: JinyHighlightPointer.self) { auiManagerCallBack?.stagePerformed() }
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    }
    
}

extension JinyAUIManager:JinyBottomDiscoveryDelegate {
    
    func discoveryPresentedWithOptInButton(_ button: UIButton) {
        presentPointer(toView: button, ofType: .FingerRipple)
        auiManagerCallBack?.discoveryPresented()
    }
    
    func discoverySheetDismissed() { auiManagerCallBack?.discoveryMuted() }
    
    func optOutButtonClicked() { auiManagerCallBack?.discoveryMuted() }
    
    func optInButtonClicked() { auiManagerCallBack?.discoveryOptedInFlow(atIndex: 0) }
    
    func discoveryLanguageButtonClicked() {
        guard let langs = auiManagerCallBack?.getLanguages() else {
            auiManagerCallBack?.discoveryReset()
            return
        }
        presentLanguagePanel(languages: langs)
    }
    
}


extension JinyAUIManager:JinyLanguagePanelDelegate {
    
    func languagePanelPresented() { auiManagerCallBack?.languagePanelOpened() }
    
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
