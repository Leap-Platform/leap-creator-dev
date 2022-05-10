//
//  LeapConfigRepository.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 09/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation

public protocol LeapConfigRepositoryDelegate: AnyObject {
    func fetchConfig(projectId: String?, completion: ((_ config: Dictionary<String, AnyHashable>) -> Void)?)
}

enum StatusCode: Int {
    case success = 200
    case unauthorized = 401
    case fileNotFound = 404
    case badRequest = 400
}

// MARK: - LOCAL/REMOTE CONFIGURATION HANDLING
class LeapConfigRepository {
    
    private let prefs = UserDefaults.standard
    
    private let remoteConfigHandler: LeapRemoteConfigHandler?
    
    private weak var remoteHandlerDelegate: LeapRemoteHandlerDelegate?
    
    init(token: String) {
        remoteConfigHandler = LeapRemoteConfigHandler(token: token)
        remoteHandlerDelegate = remoteConfigHandler
    }
    
    func setConfig(projectId: String?, configDict: Dictionary<String, AnyHashable> = [:], response: URLResponse) {
        
        switch StatusCode(rawValue: (response as? HTTPURLResponse)?.statusCode ?? StatusCode.badRequest.rawValue) {
            
        case .fileNotFound, .unauthorized:
            guard let projectId = projectId else {
                remoteConfigHandler?.resetSavedHeaders()
                self.resetSavedConfig()
                break
            }
            self.resetProjectConfigFor(projectId: projectId)
            
        case .success:
            guard let projectId = projectId else {
                self.saveConfig(config: configDict)
                fallthrough
            }
            self.saveProjectConfig(projectId: projectId, config: configDict)
            
        default:
            if projectId == nil {
                if let httpResponse = response as? HTTPURLResponse {
                    remoteConfigHandler?.saveHeaders(headers: httpResponse.allHeaderFields)
                }
            }
        }
    }
    
    func getConfig(projectId: String?) -> Dictionary<String, AnyHashable> {
        
        guard let projectId = projectId else {
            return self.getSavedConfig()
        }
        
        let savedProjectConfig = self.getSavedProjectConfigFor(projectId: projectId)
        return savedProjectConfig
    }
    
    func saveConfig(config:Dictionary<String,AnyHashable>) {
        guard let configData = try? JSONSerialization.data(withJSONObject: config, options: .prettyPrinted),
              let configString = String(data: configData, encoding: .utf8) else { return }
        let prefs = UserDefaults.standard
        prefs.setValue(configString, forKey: "leap_config")
    }
    
    func getSavedConfig() -> Dictionary<String,AnyHashable> {
        guard let configString = prefs.value(forKey: "leap_config") as? String,
              let configData = configString.data(using: .utf8),
              let config = try? JSONSerialization.jsonObject(with: configData, options: .allowFragments) as? Dictionary<String,AnyHashable> else { return [:] }
        return config
    }
    
    func resetSavedConfig() {
        prefs.setValue([:], forKey: "leap_config")
    }
    
    func saveProjectConfig(projectId:String, config:Dictionary<String,AnyHashable>) {
        var savedConfigs = getSavedProjectConfigs()
        savedConfigs[projectId] = config
        guard let newSavedConfigsData = try? JSONSerialization.data(withJSONObject: savedConfigs, options: .prettyPrinted),
              let newSavedConfigsString = String(data: newSavedConfigsData, encoding: .utf8) else { return }
        prefs.setValue(newSavedConfigsString, forKey: "leap_project_configs")
    }
    
    func getSavedProjectConfigFor(projectId:String) -> Dictionary<String,AnyHashable> {
        let savedProjectConfigs = getSavedProjectConfigs()
        return savedProjectConfigs[projectId] ?? [:]
    }
    
    func getSavedProjectConfigs() -> Dictionary<String,Dictionary<String,AnyHashable>> {
        guard let savedProjectConfigsString = prefs.value(forKey: "leap_project_configs") as? String,
              let savedConfigsData = savedProjectConfigsString.data(using: .utf8),
              let savedProjectConfigs = try? JSONSerialization.jsonObject(with: savedConfigsData, options: .allowFragments) as? Dictionary<String,Dictionary<String,AnyHashable>> else { return [:] }
        return savedProjectConfigs
    }
    
    func resetProjectConfigFor(projectId: String) {
        var savedProjectConfigs = getSavedProjectConfigs()
        savedProjectConfigs.removeValue(forKey: projectId)
        guard let newSavedConfigsData = try? JSONSerialization.data(withJSONObject: savedProjectConfigs, options: .prettyPrinted),
              let newSavedConfigsString = String(data: newSavedConfigsData, encoding: .utf8) else { return }
        prefs.setValue(newSavedConfigsString, forKey: "leap_project_configs")
    }
}

extension LeapConfigRepository: LeapConfigRepositoryDelegate {
    
    func fetchConfig(projectId: String?, completion: ((_ config: Dictionary<String, AnyHashable>) -> Void)?) {
        
        remoteHandlerDelegate?.fetchConfig(projectId: projectId, completion: { [weak self] (result: Result<ResponseData, RequestError>?) in
            
            DispatchQueue.main.async {
                
                switch result {
                    
                case .success(let responseData):
                    
                    let configDict: Dictionary<String, AnyHashable> = {
                        let dict = try? JSONSerialization.jsonObject(with: responseData.data, options: .allowFragments) as? Dictionary<String, AnyHashable>
                        return dict ?? [:]
                    }()
                    
                    guard !configDict.isEmpty else { return }
                    
                    // make sure to set config before get config.
                    self?.setConfig(projectId: projectId, configDict: configDict, response: responseData.response)
                    guard let config = self?.getConfig(projectId: projectId) else { return }
                    completion?(config)
                    
                case .failure(let requestErrorResponse):
                    
                    var failureResponse: URLResponse?
                    
                    switch(requestErrorResponse) {
                        
                    case let .clientError(response): failureResponse = response
                        
                    case let .serverError(response): failureResponse = response
                        
                    case .noData: print("Failure")
                        
                    case .dataDecodingError: print("Failure") }
                    
                    guard let failureResponse = failureResponse else { return }
                    
                    // make sure to set config before get config.
                    self?.setConfig(projectId: projectId, response: failureResponse)
                    guard let config = self?.getConfig(projectId: projectId) else { return }
                    completion?(config)
                    
                    case .none: print("Failure") }
            }
        })
    }
}
