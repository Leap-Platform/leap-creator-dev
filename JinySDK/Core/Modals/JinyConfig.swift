//
//  JinyConfig.swift
//  JinySDK
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation


class JinyConfig {
    
    var flows:Array<JinyFlow> = []
    var triggers:Array<JinyTrigger> = []
    var languages:Array<JinyLanguage> = []
    var defaultSounds:Array<JinySound> = []
    var discoverySounds:Array<JinySound> = []
    var sounds:Array<JinySound> = []
    
    init(withConfig configDict:Dictionary<String,Any>) {
        
        if let triggerDictsArray = configDict["jiny_initial_trigger"] as? Array<Dictionary<String,Any>>  { for triggerDict in triggerDictsArray {
            let trigger = JinyTrigger(withTriggerDict: triggerDict)
            triggers.append(trigger)
            }
        }
        
        if let flowDictsArray = configDict["jiny_flows"] as? Array<Dictionary<String,Any>>  {
            for flowDict in flowDictsArray {
                let flow = JinyFlow(withFlowDict: flowDict)
                flows.append(flow)
            }
        }
        
        if let languageDictsArray = configDict["jiny_languages"] as? Array<Dictionary<String,String>> {
            for languageDict in languageDictsArray {
                let language = JinyLanguage(withLanguageDict: languageDict)
                languages.append(language)
            }
        }
        
        if let discoverySoundsDict = configDict["discovery_sounds"] as? Dictionary<String,Any> {
            discoverySounds = processSoundDict(dict: discoverySoundsDict)
        }
        
        if let defaultSoundsDict = configDict["default_sounds"] as? Dictionary<String,Any> {
            defaultSounds = processSoundDict(dict: defaultSoundsDict)
            
        }
        
        
    }
    
    
    private func processSoundDict(dict:Dictionary<String,Any>) -> Array<JinySound> {
        let baseUrl = dict["base_url"] as? String
        guard let jinySoundsDict = dict["jiny_sounds"] as? Dictionary<String,Array<Dictionary<String,Any>>> else { return [] }
        var soundsArray:Array<JinySound> = []
        jinySoundsDict.forEach { (langCode,soundDictsArray) in
            for soundDict in soundDictsArray {
                soundsArray.append(JinySound(withSoundDict: soundDict, langCode: langCode, baseUrl: baseUrl))
            }
        }
        return soundsArray
    }
}
