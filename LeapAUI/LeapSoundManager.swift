//
//  LeapSoundManager.swift
//  LeapSDK
//
//  Created by Ajay S on 26/04/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

class LeapSoundManager {
    
    var soundUrl: String = {
        #if DEV
            return "https://odin-dev-gke.leap.is/odin/api/v1/sounds"
        #elseif STAGE
            return "https://odin-stage-gke.leap.is/odin/api/v1/sounds"
        #elseif PROD
            return "https://odin.leap.is/odin/api/v1/sounds"
        #else
            return "https://odin.leap.is/odin/api/v1/sounds"
        #endif
    }()
    
    var discoverySoundsJson: Dictionary<String,Array<LeapSound>> = [:]
    var previewSoundsJson: Dictionary<String, Array<LeapSound>> = [:]
    var stageSoundsJson: Dictionary<String,Array<LeapSound>> = [:]
    
    func fetchSoundConfig(_ completion: @escaping SuccessCallBack) {
        guard let url = URL(string: soundUrl) else { return }
        var req = URLRequest(url: url)
        guard let token = LeapPreferences.shared.apiKey else { fatalError("No API Key") }
        req.addValue(token, forHTTPHeaderField: "x-jiny-client-id")
        let bundleShortVersionString = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "Empty"
        req.addValue(bundleShortVersionString, forHTTPHeaderField: "x-app-version-name")
        let bundleVersion = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "Empty"
        req.addValue(bundleVersion, forHTTPHeaderField: "x-app-version-code")
        let session = URLSession.shared
        let configTask = session.dataTask(with: req) {[weak self] (data, response, error) in
            guard let resultData = data else {
                let savedSoundConfigs = self?.getSavedConfig()
                self?.stageSoundsJson = self?.processSoundConfigs(configs: savedSoundConfigs!) ?? [:]
                completion(true)
                return
            }
            guard let audioDict = try? JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as? Dictionary<String, Any> else {
                completion(false)
                return
            }
            guard let soundConfigs = audioDict[constant_data] as? Array<Dictionary<String,Any>> else {
                completion(false)
                return
            }
            self?.saveConfig(config: soundConfigs)
            self?.stageSoundsJson = self?.processSoundConfigs(configs: soundConfigs) ?? [:]
            completion(true)
        }
        configTask.resume()
    }
    
    func processSoundConfigs(configs: Array<Dictionary<String,Any>>) -> Dictionary<String, Array<LeapSound>> {
        var processedSoundsDict: Dictionary<String,Array<LeapSound>> = [:]
        for config in configs {
            let singleConfigProcessed = processSingleConfig(config: config)
            print(singleConfigProcessed)
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
              let leapSounds = config[constant_leapSounds] as? Dictionary<String,Array<Dictionary<String,Any>>> ?? config["sounds"] as? Dictionary<String,Array<Dictionary<String,Any>>> else { return processedSounds }
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
}

extension LeapSoundManager {
    
    private func saveConfig(config:Array<Dictionary<String,Any>>) {
        guard let configData = try? JSONSerialization.data(withJSONObject: config, options: .prettyPrinted),
              let configString = String(data: configData, encoding: .utf8) else { return }
        let prefs = UserDefaults.standard
        prefs.setValue(configString, forKey: "leap_soundConfig")
        prefs.synchronize()
    }
    
    private func getSavedConfig() -> Array<Dictionary<String,Any>> {
        let prefs = UserDefaults.standard
        guard let configString = prefs.value(forKey: "leap_soundConfig") as? String,
              let configData = configString.data(using: .utf8),
              let config = try? JSONSerialization.jsonObject(with: configData, options: .allowFragments) as? Array<Dictionary<String,Any>> else { return [[:]] }
        return config
    }
}
