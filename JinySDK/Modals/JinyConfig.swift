//
//  JinyConfig.swift
//  JinySDK
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyConfig {
    
    var webIdentifiers:Dictionary<String,JinyWebIdentifier> = [:]
    var nativeIdentifiers:Dictionary<String,JinyNativeIdentifier> = [:]
    var assists:Array<JinyAssist> = []
    var flows:Array<JinyFlow> = []
    var analytics:Dictionary<String,Any> = [:]
    var params:Dictionary<String,Any> = [:]
    var languages:Array<JinyLanguage> = []
    var defaultSounds:Array<JinySound> = []
    var discoverySounds:Array<JinySound> = []
    var discoveries:Array<JinyDiscovery> = []
    var feature:Dictionary<String,Any> = [:]
    var supportedAppLocales:Array<String> = []
    var webViewList:Array<Dictionary<String,Any>> = []
    var sounds:Array<JinySound> = []
    
    
    init(withDict dataDict:Dictionary<String,Any>) {
        
        guard let configDict = dataDict["data"] as? Dictionary<String,Any> else { return }
        
        if let webIdentifiersDict = configDict["web_identifiers"] as? Dictionary<String,Dictionary<String,Any>>  {
            webIdentifiersDict.forEach { (webId, idObject) in
                webIdentifiers[webId] = JinyWebIdentifier(withDict: idObject)
            }
        }
        
        if let nativeIdentifiersDict = configDict["native_identifiers"] as? Dictionary<String,Dictionary<String,Any>> {
            nativeIdentifiersDict.forEach { (nativeId, idObject) in
                nativeIdentifiers[nativeId] = JinyNativeIdentifier(withDict: idObject)
            }
        }
        
        if let flowDictsArray = configDict["flows"] as? Array<Dictionary<String,Any>> {
            for flowDicts in flowDictsArray {
                flows.append(JinyFlow(withDict: flowDicts))
            }
        }
        
        if let languageDictsArray = configDict["languages"] as? Array<Dictionary<String,String>> {
            for languageDict in languageDictsArray {
                languages.append(JinyLanguage(withLanguageDict: languageDict))
            }
        }
        
        if let discoverySoundsDict = configDict["discovery_sounds"] as? Dictionary<String,Any> {
            discoverySounds = processSoundDict(dict: discoverySoundsDict)
        }
        
        if let defaultSoundsDict = configDict["default_sounds"] as? Dictionary<String,Any> {
            defaultSounds = processSoundDict(dict: defaultSoundsDict)
            
        }
        
        if let discoveryDictsArray = configDict["discovery_list"] as? Array<Dictionary<String,Any>> {
            for discoveryDict in discoveryDictsArray {
                discoveries.append(JinyDiscovery(withDict: discoveryDict))
            }
        }
        
        if let assistsDictsArray = configDict["assists"] as? Array<Dictionary<String,Any>> {
            for assistDict in assistsDictsArray {
                assists.append(JinyAssist(withDict: assistDict))
            }
        }
        
        supportedAppLocales = configDict["supported_app_locales"] as? Array<String> ?? []
        
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
