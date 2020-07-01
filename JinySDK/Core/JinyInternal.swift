//
//  JinyInternal.swift
//  JinySDK
//
//  Created by Aravind GS on 17/03/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AdSupport

class JinyInternal:NSObject {
    var announcement: AVAudioPlayer? = nil
    private var apikey:String
    var ptr:JinyPointer?
    var jinyConfig:JinyConfig?
    var jinyConfiguration:JinyConfiguration?
    var contextManager:JinyContextManager?
    var audioManager:JinyAudioManager
    
    init(_ token : String) {
        self.apikey = token
        audioManager = JinyAudioManager()
        super.init()
        audioManager.delegate = self
        JinySharedInformation.shared.setAPIKey(apikey)
        JinySharedInformation.shared.setSessionId()
        addObservers()
        fetchConfig()
    }
    
}


// MARK: - OBSERVER AND LISTENER METHODS

extension JinyInternal {
    
    private func addObservers() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(appLaunched), name: UIApplication.didFinishLaunchingNotification, object: nil)
        nc.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    @objc private func appLaunched() {
        
    }
    
    @objc private func appWillEnterForeground() {
        
    }
    
    @objc private func appDidEnterBackground() {
        
    }
    
    @objc private func appWillTerminate() {
        
    }
}

// MARK: - GENERATE AND RETRIEVE SESSION ID

extension JinyInternal {
    
}

// MARK: - FETCH CONFIGURATION AND AUDIO DOWNLOAD

extension JinyInternal {
    
    func fetchConfig() {
        let url = URL(string: "http://dashboard.jiny.mockable.io/getIosData")
        var req = URLRequest(url: url!)
        req.addValue(ASIdentifierManager.shared().advertisingIdentifier.uuidString, forHTTPHeaderField: "identifier")
        let session = URLSession.shared
        let configTask = session.dataTask(with: req) { (data, response, error) in
            guard let resultData = data else { return }
            guard let configDict = try?  JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as? Dictionary<String,Any> else { return }
            self.jinyConfig = JinyConfig(withConfig: configDict)
            self.setupDefaultLanguage()
            self.startContextDetection()
            self.soundDownload()
            self.fetchAudio()
        }
        configTask.resume()
    }
    
    func setupDefaultLanguage() {
        guard let config = self.jinyConfig else { return }
        if let lang = JinySharedInformation.shared.getLanguage() {
            for language in config.languages { if lang == language.localeId { return } }
        }
        var newDefault:String?
        for lang in config.languages {
            if lang.localeId == "" { continue }
            newDefault = lang.localeId
            break
        }
        guard let defaultLang = newDefault else { return }
        JinySharedInformation.shared.setLanguage(defaultLang)
        
    }
    
    func fetchAudio() {
        let url = URL(string: "http://dashboard.jiny.mockable.io/sounds")
        var req = URLRequest(url: url!)
        req.addValue(ASIdentifierManager.shared().advertisingIdentifier.uuidString, forHTTPHeaderField: "identifier")
        let session = URLSession.shared
        let configTask = session.dataTask(with: req) { (data, response, error) in
            guard let resultData = data else {
                self.fetchAudio()
                return
            }
            do {
                let audioDict = try JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as! Dictionary<String,Any>
                guard let dataDict = audioDict["data"] as? Dictionary<String,Any> else { return }
                let baseUrl = dataDict["base_url"] as? String
                guard let jinySoundsJson = dataDict["jiny_sounds"] as? Dictionary<String,Array<Dictionary<String,Any>>> else { return }
                // FIXME: Process sounds API
                var stageSounds:Array<JinySound> = []
                jinySoundsJson.forEach { (langCode, soundDictsArray) in
                    for soundDict in soundDictsArray {
                        let sound = JinySound(withSoundDict: soundDict, langCode: langCode, baseUrl: baseUrl)
                        stageSounds.append(sound)
                    }
                }
                self.jinyConfig?.sounds = stageSounds
                self.soundDownload()
            } catch {
                print("Error")
                return
            }
        }
        configTask.resume()
    }
    
    func soundDownload(){
        audioManager.registerForDownload()
    }
}

// MARK: - CONTEXT DETECTION METHODS
extension JinyInternal {
    
    func startContextDetection() {
        guard let config = self.jinyConfig else { return }
        DispatchQueue.main.async {
            self.contextManager = JinyContextManager(config: config)
            self.contextManager?.audioManagerDelegate = self.audioManager
            self.contextManager?.initialize()
        }
    }
}


extension JinyInternal:JinyAudioManagerDelegate {
    
    func getDefaultSounds() -> Array<JinySound> {
        return jinyConfig?.defaultSounds ?? []
    }
    
    func getDiscoverySounds() -> Array<JinySound> {
        return jinyConfig?.discoverySounds ?? []
    }
    
    func getStageSounds() -> Array<JinySound> {
        return jinyConfig?.sounds ?? []
    }
    
}
