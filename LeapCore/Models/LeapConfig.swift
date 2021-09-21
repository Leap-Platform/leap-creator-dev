//
//  LeapConfig.swift
//  LeapCore
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation

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
    var projectContextDict:Dictionary<String,Int> = [:]
    var localeSounds:Array<Dictionary<String,Any>> = []
    var contextProjectParametersDict:Dictionary<String,LeapProjectParameters> = [:]
    
    init(withDict dataDict:Dictionary<String,Any>, isPreview:Bool) {
        
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
            
            let currentProjectParameters:LeapProjectParameters? = {
                guard let projectParamsDict = configDict[constant_projectParameters] as? Dictionary<String, Any> else { return nil }
                return LeapProjectParameters(withDict: projectParamsDict)
            }()
            
            if let flowDictsArray = configDict[constant_flows] as? Array<Dictionary<String,Any>> {
                flows += flowDictsArray.map({ (flowDict) -> LeapFlow? in
                    let flow = LeapFlow(withDict: flowDict)
                    if let tempParams = currentProjectParameters,
                       let projId = tempParams.projectId, let flowId = flow.id {
                        projectContextDict["flow_\(projId)"] = flowId
                        currentProjectParameters?.id = flowId
                        contextProjectParametersDict["flow_\(flowId)"] = currentProjectParameters
                    }
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
                    let discovery = LeapDiscovery(withDict: discoveryDict,isPreview: isPreview)
                    if let tempParams = currentProjectParameters, let projId = tempParams.projectId {
                        projectContextDict["discovery_\(projId)"] = discovery.id
                        currentProjectParameters?.id = discovery.id
                        contextProjectParametersDict["discovery_\(discovery.id)"] = currentProjectParameters
                    }
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
                    let assist = LeapAssist(withDict: assistDict,isPreview: isPreview)
                    if let tempParams = currentProjectParameters, let projId = tempParams.projectId {
                        projectContextDict["assist_\(projId)"] = assist.id
                        currentProjectParameters?.id = assist.id
                        contextProjectParametersDict["assist_\(assist.id)"] = currentProjectParameters
                    }
                    if assists.contains(assist) { return nil }
                    return assist
                }).compactMap{ return $0 }
            }
            if let discoverySoundsDict = configDict[constant_discoverySounds] as? Dictionary<String,Any> {
                discoverySounds.append(discoverySoundsDict)
            }
            if let localeSoundsDict = configDict[constant_localeSounds] as? Dictionary<String,Any> {
                localeSounds.append(localeSoundsDict)
            }
            if var auiContentsDict = configDict[constant_auiContent] as? Dictionary<String,Any> {
                var contents = auiContentsDict[constant_content] as? Array<AnyHashable> ?? []
                contents = contents.filter { !($0 is NSNull) }.compactMap { return $0 }
                auiContentsDict[constant_content] = contents
                auiContent.append(auiContentsDict)
            }
            if let newSupportedAppLocale = configDict[constant_supportedAppLocales] as? Array<String> {
                supportedAppLocales = Array(Set(supportedAppLocales+newSupportedAppLocale))
            }
            if let currentProjectParams = currentProjectParameters { projectParameters.append(currentProjectParams) }
        }
        
    }
    
}
