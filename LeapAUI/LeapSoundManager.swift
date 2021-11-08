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
        #elseif PREPROD
            return "https://odin-preprod.leap.is/odin/api/v1/sounds"
        #elseif PROD
            return "https://odin.leap.is/odin/api/v1/sounds"
        #else
            return "https://odin.leap.is/odin/api/v1/sounds"
        #endif
    }()
    
    var discoverySoundsJson: Dictionary<String,Array<LeapSound>> = [:]
    var stageSoundsJson: Dictionary<String,Array<LeapSound>> = [:]
    
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
