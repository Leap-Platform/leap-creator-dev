//
//  JinyConfig.swift
//  JinySDK
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import Gzip

class JinyConfig {
    
    var webIdentifiers:Dictionary<String,JinyWebIdentifier> = [:]
    var nativeIdentifiers:Dictionary<String,JinyNativeIdentifier> = [:]
    var assists:Array<JinyAssist> = []
    var discoveries:Array<JinyDiscovery> = []
    var flows:Array<JinyFlow> = []
    var languages:Array<JinyLanguage> = []
    var supportedAppLocales:Array<String> = []
    var discoverySounds:Array<Dictionary<String,Any>> = []
    var defaultSounds:Array<Dictionary<String,Any>> = []
    var auiContent:Array<Dictionary<String,Any>> = []
    var iconSetting: Dictionary<String, IconSetting> = [:]
    
    var params:Dictionary<String,Any> = [:]
    var webViewList:Array<Dictionary<String,Any>> = []
    
    init(withDict dataDict:Dictionary<String,Any>) {
        
        var configsArray:Array<Dictionary<String,Any>> = []
        if let base64ConfigStrings  = dataDict[constant_data] as? Array<String> {
            for base64ConfigString in base64ConfigStrings {
                let base64DecodedData = Data(base64Encoded: base64ConfigString)
                if let decompressedData = try? base64DecodedData?.gunzipped(), let jsonDict = try? JSONSerialization.jsonObject(with: decompressedData, options: .allowFragments) as? Dictionary<String,Any> {
                    configsArray.append(jsonDict)
                }
            }
            
        } else {
            guard let data = dataDict[constant_data] as? Array<Dictionary<String,Any>> else { return }
            configsArray = data
        }
        guard configsArray.count > 0  else { return }
        for configDict in configsArray {
            if let webIdentifiersDict = configDict[constant_webIdentifiers] as? Dictionary<String,Dictionary<String,Any>>  {
                webIdentifiersDict.forEach { (webId, idObject) in
                    webIdentifiers[webId] = JinyWebIdentifier(withDict: idObject)
                }
            }
            if let nativeIdentifiersDict = configDict[constant_nativeIdentifiers] as? Dictionary<String,Dictionary<String,Any>> {
                nativeIdentifiersDict.forEach { (nativeId, idObject) in
                    nativeIdentifiers[nativeId] = JinyNativeIdentifier(withDict: idObject)
                }
            }
            if let flowDictsArray = configDict[constant_flows] as? Array<Dictionary<String,Any>> {
                for flowDicts in flowDictsArray {
                    flows.append(JinyFlow(withDict: flowDicts))
                }
            }
            if let languageDictsArray = configDict[constant_languages] as? Array<Dictionary<String,Any>> {
                for languageDict in languageDictsArray {
                    languages.append(JinyLanguage(withLanguageDict: languageDict))
                }
            }
            if let discoveryDictsArray = configDict[constant_discoveryList] as? Array<Dictionary<String,Any>> {
                for discoveryDict in discoveryDictsArray {
                    discoveries.append(JinyDiscovery(withDict: discoveryDict))
                    if let discoveryId = discoveryDict[constant_id] as? Int, let iconSetting = configDict[constant_iconSetting] as? Dictionary<String, Any> {
                        if let discoveryIconSetting = iconSetting[String(discoveryId)] as? Dictionary<String, Any> {
                           self.iconSetting[String(discoveryId)] = IconSetting(with: discoveryIconSetting)
                        }
                    }
                }
            }
            if let assistsDictsArray = configDict[constant_assists] as? Array<Dictionary<String,Any>> {
                for assistDict in assistsDictsArray {
                    assists.append(JinyAssist(withDict: assistDict))
                }
            }
            if let discoverySoundsDict = configDict[constant_discoverySounds] as? Dictionary<String,Any> {
                discoverySounds.append(discoverySoundsDict)
            }
            if let defaultSoundsDict = configDict[constant_defaultSounds] as? Dictionary<String,Any> {
                defaultSounds.append(defaultSoundsDict)
            }
            if let auiContentsDict = configDict[constant_auiContent] as? Dictionary<String,Any> {
                auiContent.append(auiContentsDict)
            }

            if let newSupportedAppLocale = configDict[constant_supportedAppLocales] as? Array<String> {
                supportedAppLocales = Array(Set(supportedAppLocales+newSupportedAppLocale))
            }
        }
        
    }
    
}
