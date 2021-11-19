//
//  LeapInternal.swift
//  LeapCore
//
//  Created by Aravind GS on 17/03/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

fileprivate let configUrl:String = {
    #if DEV
    return "https://odin-dev-gke.leap.is/odin/api/v1/config/fetch"
    #elseif STAGE
    return "https://odin-stage-gke.leap.is/odin/api/v1/config/fetch"
    #elseif PREPROD
    return "https://odin-preprod.leap.is/odin/api/v1/config/fetch"
    #elseif PROD
    return "https://odin.leap.is/odin/api/v1/config/fetch"
    #else
    return "https://odin.leap.is/odin/api/v1/config/fetch"
    #endif
}()

fileprivate func getSavedHeaders() -> Dictionary<String,String> {
    let prefs = UserDefaults.standard
    let headers = prefs.object(forKey: "leap_saved_headers") as? Dictionary<String,String> ?? [:]
    return headers
}

fileprivate func getCommonHeaders() -> Dictionary<String,String> {
    guard let apiKey = LeapSharedInformation.shared.getAPIKey(), let versionCode = LeapSharedInformation.shared.getVersionCode(), let versionName = LeapSharedInformation.shared.getVersionName() else { return [:] }
    let headers = [
        "x-jiny-client-id"      : apiKey,
        "x-app-version-code"    : versionCode,
        "x-app-version-name"    : versionName,
        "x-leap-id"             : LeapSharedInformation.shared.getLeapId(),
        "Content-Type"          : "application/json"
    ]
    return headers
}

fileprivate func getAllHeaders() -> Dictionary<String,String> {
    guard let _ = LeapSharedInformation.shared.getAPIKey() else { return [:] }
    var headers = getCommonHeaders()
    getSavedHeaders().forEach { headers[$0.key] = $0.value }
    return headers
}

fileprivate func getPayload() -> Dictionary<String,String> {
    
    let defaultStringProperties = LeapPropertiesHandler.shared.getDefaultStringProperties()
    let defaultLongProperties = LeapPropertiesHandler.shared.getDefaultLongProperties()
    let defaultIntProperties = LeapPropertiesHandler.shared.getDefaultIntProperties()
    
    let customLongProperties = LeapPropertiesHandler.shared.getCustomLongProperties()
    let customStringProperties = LeapPropertiesHandler.shared.getCustomStringProperties()
    let customIntProperties = LeapPropertiesHandler.shared.getCustomIntProperties()
    
    
    var payload:Dictionary<String,String> = customStringProperties
    defaultStringProperties.forEach { (key, value) in
        payload[key] = value
    }
    
    customIntProperties.forEach { (key,value) in
        payload[key] = "\(value)"
    }
    
    defaultIntProperties.forEach { (key, value) in
        payload[key] = "\(value)"
    }
    
    customLongProperties.forEach { (key,value) in
        let timeElapsed = Int64(Date(timeIntervalSince1970: TimeInterval(value)).timeIntervalSinceNow * -1)
        payload[key] = "\(timeElapsed)"
    }
    
    defaultLongProperties.forEach { (key, value) in
        let timeElapsed = Int64(Date(timeIntervalSince1970: TimeInterval(value)).timeIntervalSinceNow * -1)
        payload[key] = "\(timeElapsed)"
    }
    
    return payload
}

// MARK: - CONFIG ACTION
enum ConfigAction {
    case UseNewConfig
    case UseCachedConfig
    case ResetConfig
}

// MARK: - LEAPINTERNAL CLASS
class LeapInternal:NSObject {
    var contextManager:LeapContextManager
    
    var fetchedProjectIds:Array<String> = []
    var currentEmbeddedProjectId:String?
    lazy var fetchQueue:OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Leap Config Fetch Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    init(_ token : String, uiManager:LeapAUIHandler?) {
        self.contextManager = LeapContextManager(withUIHandler: uiManager)
        super.init()
        self.contextManager.delegate = self
        resetSavedHeaders(for: token)
        LeapSharedInformation.shared.setAPIKey(token)
        LeapSharedInformation.shared.setSessionId()
        fetchConfig()
    }
    
    func auiCallback() -> LeapAUICallback? {
        return self.contextManager
    }
    
}

// MARK: - CONFIGURATION DOWNLOAD AND HANDLING
extension LeapInternal {
    
    private func fetchConfig() {
        let configOp = LeapConfigFetchOperation(projectId: nil) { response, data, error in
            DispatchQueue.main.async {
                let configDict:Dictionary<String,AnyHashable> = {
                    guard let resultData = data else { return [:] }
                    let dict = try? JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as? Dictionary<String,AnyHashable>
                    return dict ?? [:]
                }()
                switch self.getConfigActionToTake(data: data, response: response) {
                case .ResetConfig:
                    self.resetSavedHeaders()
                    self.resetSavedConfig()
                case .UseNewConfig:
                    self.saveConfig(config: configDict)
                    fallthrough
                case .UseCachedConfig:
                    if let httpResponse = response as? HTTPURLResponse {
                        self.saveHeaders(headers: httpResponse.allHeaderFields)
                    }
                }
                let savedConfig = self.getSavedConfig()
                self.startContextDetection(config: savedConfig)
            }
        }
        fetchQueue.addOperation(configOp)
    }
    
    public func startProject(projectId:String, resetProject:Bool, isEmbedProject:Bool) {
        let projIds = projectId.components(separatedBy: "#")
        guard let mainProjId = projIds.first else { return }
        let subFlowId:String? = {
            guard projIds.count == 2 else { return  nil }
            return projIds[1]
        }()
        let isEmbeddedFlow = contextManager.isFlowEmbedFor(projectId: mainProjId)
        if isEmbedProject {
            contextManager.resetForProjectId(mainProjId)
            guard mainProjId != currentEmbeddedProjectId else { return }
        } else {
            if resetProject { contextManager.resetForProjectId(mainProjId) }
            else {
                guard !fetchedProjectIds.contains(mainProjId) else {
                    let savedProjectConfig = self.getSavedProjectConfigFor(projectId: mainProjId)
                    let projectConfig = LeapConfig(withDict: savedProjectConfig, isPreview: false)
                    contextManager.appendProjectConfig(withConfig: projectConfig, resetProject: resetProject)
                    return
                }
            }
        }
        if let currentEmbed = currentEmbeddedProjectId {
            contextManager.removeConfigFor(projectId: currentEmbed)
            currentEmbeddedProjectId = nil
        }
        let configOp = LeapConfigFetchOperation(projectId: mainProjId) { response, data, error in
            DispatchQueue.main.async {
                if !isEmbedProject { self.fetchedProjectIds.append(mainProjId) }
                let configDict:Dictionary<String,AnyHashable> = {
                    guard let resultData = data else { return [:] }
                    let dict = try? JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as? Dictionary<String,AnyHashable>
                    return dict ?? [:]
                }()
                switch self.getConfigActionToTake(data: data, response: response) {
                case .ResetConfig:
                    self.resetProjectConfigFor(projectId: mainProjId)
                case .UseCachedConfig:
                    break
                case .UseNewConfig:
                    self.saveProjectConfig(projectId: mainProjId, config: configDict)
                }
                let savedProjectConfig = self.getSavedProjectConfigFor(projectId: mainProjId)
                let projectConfig = LeapConfig(withDict: savedProjectConfig, isPreview: false)
                if isEmbeddedFlow {
                    var projParams:LeapProjectParameters?
                    projectConfig.contextProjectParametersDict.forEach { key, parameters in
                        if key.hasPrefix("discovery_") && parameters.deploymentId == mainProjId {
                            projParams = parameters
                        }
                    }
                    if let projectParameters = projParams {
                        projectParameters.setEmbed(embed: true)
                        projectParameters.setEnabled(enabled: true)
                    }
                }
                self.contextManager.appendProjectConfig(withConfig: projectConfig, resetProject: resetProject)
                guard let subflowProjectId = subFlowId else { return }
                self.contextManager.startSubproj(mainProjId: mainProjId, subProjId: subflowProjectId)
            }
        }
        fetchQueue.addOperation(configOp)
        
    }
    
}


// MARK: - APP CONFIG, HEADERS GETTERS & SETTERS
extension LeapInternal {
    
    private func saveHeaders(headers:Dictionary<AnyHashable, Any>) {
        var toSaveHeaders:Dictionary<String,String> = [:]
        headers.forEach { (key,value) in
            if let headerField = key as? String, let valueField = value as? String {
                if headerField.starts(with: "x-jiny-") { toSaveHeaders[headerField] = valueField }
            }
        }
        let prefs = UserDefaults.standard
        prefs.set(toSaveHeaders, forKey: "leap_saved_headers")
    }
    
    private func resetSavedHeaders() {
        let prefs = UserDefaults.standard
        prefs.setValue([:], forKey: "leap_saved_headers")
    }
    
    private func resetSavedHeaders(for token: String) {
        if token != LeapSharedInformation.shared.getAPIKey() { resetSavedHeaders() }
    }
    
    private func saveConfig(config:Dictionary<String,AnyHashable>) {
        guard let configData = try? JSONSerialization.data(withJSONObject: config, options: .prettyPrinted),
              let configString = String(data: configData, encoding: .utf8) else { return }
        let prefs = UserDefaults.standard
        prefs.setValue(configString, forKey: "leap_config")
    }
    
    private func getSavedConfig() -> Dictionary<String,AnyHashable> {
        let prefs = UserDefaults.standard
        guard let configString = prefs.value(forKey: "leap_config") as? String,
              let configData = configString.data(using: .utf8),
              let config = try? JSONSerialization.jsonObject(with: configData, options: .allowFragments) as? Dictionary<String,AnyHashable> else { return [:] }
        return config
    }
    
    private func resetSavedConfig() {
        let prefs = UserDefaults.standard
        prefs.setValue([:], forKey: "leap_config")
    }
}

// MARK: - PROJECT CONFIG SETTERS AND GETTERS
extension LeapInternal {
    
    private func saveProjectConfig(projectId:String, config:Dictionary<String,AnyHashable>) {
        let prefs = UserDefaults.standard
        var savedConfigs = getSavedProjectConfigs()
        savedConfigs[projectId] = config
        guard let newSavedConfigsData = try? JSONSerialization.data(withJSONObject: savedConfigs, options: .prettyPrinted),
              let newSavedConfigsString = String(data: newSavedConfigsData, encoding: .utf8) else { return }
        prefs.setValue(newSavedConfigsString, forKey: "leap_project_configs")
    }
    
    private func getSavedProjectConfigFor(projectId:String) -> Dictionary<String,AnyHashable> {
        let savedProjectConfigs = getSavedProjectConfigs()
        return savedProjectConfigs[projectId] ?? [:]
    }
    
    private func getSavedProjectConfigs() -> Dictionary<String,Dictionary<String,AnyHashable>> {
        let prefs = UserDefaults.standard
        guard let savedProjectConfigsString = prefs.value(forKey: "leap_project_configs") as? String,
              let savedConfigsData = savedProjectConfigsString.data(using: .utf8),
              let savedProjectConfigs = try? JSONSerialization.jsonObject(with: savedConfigsData, options: .allowFragments) as? Dictionary<String,Dictionary<String,AnyHashable>> else { return [:] }
        return savedProjectConfigs
    }
    
    private func resetProjectConfigFor(projectId:String) {
        let prefs = UserDefaults.standard
        var savedProjectConfigs = getSavedProjectConfigs()
        savedProjectConfigs.removeValue(forKey: projectId)
        guard let newSavedConfigsData = try? JSONSerialization.data(withJSONObject: savedProjectConfigs, options: .prettyPrinted),
              let newSavedConfigsString = String(data: newSavedConfigsData, encoding: .utf8) else { return }
        prefs.setValue(newSavedConfigsString, forKey: "leap_project_configs")
    }
}

// MARK: - CONFIG PROCESSING
extension LeapInternal {
    
    private func getConfigActionToTake(data:Data?, response:URLResponse?) -> ConfigAction {
        guard let _ = data,
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode != 304 else { return .UseCachedConfig }
        if httpResponse.statusCode == 404  { return .ResetConfig }
        return .UseNewConfig
    }
    
}

// MARK: - CONTEXT DETECTION METHODS
extension LeapInternal {
    private func startContextDetection(config:Dictionary<String,AnyHashable>) {
        DispatchQueue.main.async {
            let configuration = LeapConfig(withDict: config,isPreview: false)
            self.contextManager.initialize(withConfig: configuration)
        }
    }
}

extension LeapInternal: LeapContextManagerDelegate {
    
    func fetchUpdatedConfig(config:@escaping(_ :LeapConfig?)->Void) {
        let configOp = LeapConfigFetchOperation(projectId: nil) { response, data, error in
            DispatchQueue.main.async {
                let configDict:Dictionary<String,AnyHashable> = {
                    guard let resultData = data else { return [:] }
                    let dict = try? JSONSerialization.jsonObject(with: resultData, options: .allowFragments) as? Dictionary<String,AnyHashable>
                    return dict ?? [:]
                }()
                switch self.getConfigActionToTake(data: data, response: response) {
                case .ResetConfig:
                    self.resetSavedHeaders()
                    self.resetSavedConfig()
                case .UseNewConfig:
                    guard !configDict.isEmpty else {
                        config(nil)
                        return
                    }
                    self.saveConfig(config: configDict)
                    fallthrough
                case .UseCachedConfig:
                    if let httpResponse = response as? HTTPURLResponse {
                        self.saveHeaders(headers: httpResponse.allHeaderFields)
                    }
                }
                let savedConfig = self.getSavedConfig()
                let updatedConfig = LeapConfig(withDict: savedConfig, isPreview: false)
                config(updatedConfig)
                self.currentEmbeddedProjectId = nil
                for projId in self.fetchedProjectIds {
                    let projectConfigDict = self.getSavedProjectConfigFor(projectId: projId)
                    let projectConfig  = LeapConfig(withDict: projectConfigDict, isPreview: false)
                    self.contextManager.appendProjectConfig(withConfig: projectConfig, resetProject: false)
                }
            }
        }
        self.fetchQueue.addOperation(configOp)
    }
    
    func getCurrentEmbeddedProjectId() -> String? {
        return self.currentEmbeddedProjectId
    }
    
    func resetCurrentEmbeddedProjectId() {
        self.currentEmbeddedProjectId = nil
    }
}


class LeapConfigFetchOperation:Operation {
    
    let projectId:String?
    let configCallCompletion:(_:URLResponse?, _:Data?, _:Error?)->Void
    
    override var isAsynchronous: Bool {
        get {
            return true
        }
    }
    
    private var _executing = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    override var isExecuting: Bool {
        return _executing
    }
    
    private var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isFinished: Bool {
        return _finished
    }
    
    func executing (_ executing:Bool) {
        _executing = executing
    }
    
    func finished(_ finished:Bool) {
        _finished = finished
    }
    
    required init(projectId:String?, completion:@escaping(_:URLResponse?,_:Data?, _:Error?)->Void) {
        self.projectId = projectId
        self.configCallCompletion = completion
    }
    
    override func main() {
        guard isCancelled == false else {
            finished(true)
            configCallCompletion(nil, nil, nil)
            return
        }
        self.executing(true)
        fetchConfig(self.projectId) { data, response, error in
            self.configCallCompletion(response,data,error)
            self.finished(true)
        }
    }
    
    private func fetchConfig(_ projectId:String? = nil, completion : @escaping(_ data:Data?, _ response:URLResponse?, _ error:Error?)->Void) {
        
        let payload = getPayload()
        let payloadData:Data = {
            guard let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed) else { return Data() }
            return payloadData
        }()
        guard let url = URL(string: configUrl) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.httpBody = payloadData
        if let projId = projectId {
            getCommonHeaders().forEach { req.addValue($0.value, forHTTPHeaderField: $0.key) }
            req.addValue("[\"\(projId)\"]", forHTTPHeaderField: "x-jiny-deployment-ids")
        } else {
            getAllHeaders().forEach { req.addValue($0.value, forHTTPHeaderField: $0.key) }
        }
        
        let configTask = URLSession.shared.dataTask(with: req) { (data, response, error) in
            completion(data,response,error)
        }
        configTask.resume()
    }
}
