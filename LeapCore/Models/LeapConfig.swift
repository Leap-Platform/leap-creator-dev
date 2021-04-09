//
//  LeapConfig.swift
//  LeapCore
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import Gzip

class LeapConfig {
    
    var projectParameters: Array<LeapProjectParameters> = []
    var webIdentifiers:Dictionary<String,LeapWebIdentifier> = [:]
    var nativeIdentifiers:Dictionary<String,LeapNativeIdentifier> = [:]
    var assists:Array<LeapAssist> = []
    var discoveries:Array<LeapDiscovery> = []
    var flows:Array<LeapFlow> = []
    var languages:Array<LeapLanguage> = []
    var supportedAppLocales:Array<String> = []
    var discoverySounds:Array<Dictionary<String,Any>> = []
    var auiContent:Array<Dictionary<String,Any>> = []
    var iconSetting: Dictionary<String, LeapIconSetting> = [:]
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
                    webIdentifiers[webId] = LeapWebIdentifier(withDict: idObject)
                }
            }
            if let nativeIdentifiersDict = configDict[constant_nativeIdentifiers] as? Dictionary<String,Dictionary<String,Any>> {
                nativeIdentifiersDict.forEach { (nativeId, idObject) in
                    nativeIdentifiers[nativeId] = LeapNativeIdentifier(withDict: idObject)
                }
            }
            if let flowDictsArray = configDict[constant_flows] as? Array<Dictionary<String,Any>> {
                flows += flowDictsArray.map({ (flowDict) -> LeapFlow? in
                    let flow = LeapFlow(withDict: flowDict)
                    if flows.contains(flow) { return nil }
                    return flow
                }).compactMap { return $0}
            }
            if let languageDictsArray = configDict[constant_languages] as? Array<Dictionary<String,Any>> {
                languages += languageDictsArray.map { (langDict) -> LeapLanguage? in
                    let lang = LeapLanguage(withLanguageDict: langDict)
                    if languages.contains(lang) { return nil }
                    return lang
                }.compactMap{ return $0 }
            }
            if let discoveryDictsArray = configDict[constant_discoveryList] as? Array<Dictionary<String,Any>> {
                discoveries += discoveryDictsArray.map({ (discoveryDict) -> LeapDiscovery? in
                    let discovery = LeapDiscovery(withDict: discoveryDict)
                    if discoveries.contains(discovery) { return nil }
                    if let discoveryId = discoveryDict[constant_id] as? Int, let iconSetting = configDict[constant_iconSetting] as? Dictionary<String, Any> {
                        if let discoveryIconSetting = iconSetting[String(discoveryId)] as? Dictionary<String, Any> {
                           self.iconSetting[String(discoveryId)] = LeapIconSetting(with: discoveryIconSetting)
                        }
                    }
                    return discovery
                }).compactMap{ return $0 }
            }
            if let assistsDictsArray = configDict[constant_assists] as? Array<Dictionary<String,Any>> {
                assists += assistsDictsArray.map({ (assistDict) -> LeapAssist? in
                    let assist = LeapAssist(withDict: assistDict)
                    if assists.contains(assist) { return nil }
                    return assist
                }).compactMap{ return $0 }
            }
            if let discoverySoundsDict = configDict[constant_discoverySounds] as? Dictionary<String,Any> {
                discoverySounds.append(discoverySoundsDict)
            }
            if let auiContentsDict = configDict[constant_auiContent] as? Dictionary<String,Any> {
                auiContent.append(auiContentsDict)
            }
            if let newSupportedAppLocale = configDict[constant_supportedAppLocales] as? Array<String> {
                supportedAppLocales = Array(Set(supportedAppLocales+newSupportedAppLocale))
            }
            if let projectParams = configDict[constant_projectParameters] as? Dictionary<String, Any>, let discoveryDictsArray = configDict[constant_discoveryList] as? Array<Dictionary<String,Any>>, discoveryDictsArray.count > 0 {
                let projectParameter = LeapProjectParameters(withDict: projectParams)
                let discovery = LeapDiscovery(withDict: discoveryDictsArray.first!)
                projectParameter.id = discovery.id
                projectParameters.append(projectParameter)
            }
            if let projectParams = configDict[constant_projectParameters] as? Dictionary<String, Any>, let assistsDictsArray = configDict[constant_assists] as? Array<Dictionary<String,Any>>, assistsDictsArray.count > 0 {
                let projectParameter = LeapProjectParameters(withDict: projectParams)
                let assist = LeapAssist(withDict: assistsDictsArray.first!)
                projectParameter.id = assist.id
                projectParameters.append(projectParameter)
            }
        }
    }
    
}
