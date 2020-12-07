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
    var discoveries:Array<JinyDiscovery> = []
    var flows:Array<JinyFlow> = []
    var languages:Array<JinyLanguage> = []
    var supportedAppLocales:Array<String> = []
    var discoverySounds:Dictionary<String,Any> = [:]
    var defaultSounds:Dictionary<String,Any> = [:]
    var auiContent:Dictionary<String,Any> = [:]
    
    var params:Dictionary<String,Any> = [:]
    var webViewList:Array<Dictionary<String,Any>> = []
    var iconInfo:Dictionary<String,Any> = [:]
    
    init(withDict dataDict:Dictionary<String,Any>) {
        
        
        guard let data = dataDict["data"] as? Array<Dictionary<String,Any>> else {return}
        for configDict in data {
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
            if let languageDictsArray = configDict["languages"] as? Array<Dictionary<String,Any>> {
                for languageDict in languageDictsArray {
                    languages.append(JinyLanguage(withLanguageDict: languageDict))
                }
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
            
            discoverySounds = configDict["discovery_sounds"] as? Dictionary<String,Any> ?? [:]
            defaultSounds = configDict["default_sounds"] as? Dictionary<String,Any> ?? [:]
            auiContent = configDict["aui_content"] as? Dictionary<String,Any> ?? [:]
            supportedAppLocales = configDict["supported_app_locales"] as? Array<String> ?? []
            
        }
        iconInfo = dataDict["icon_info"] as? Dictionary<String,Any> ?? [:]
    }
    
}
