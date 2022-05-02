//
//  LeapRemoteHandler.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 02/05/22.
//  Copyright © 2022 Aravind GS. All rights reserved.
//

import Foundation

class LeapRemoteConfigHandler {
    
    lazy var fetchQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Leap Config Fetch Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    init(token: String) {
        resetSavedHeaders(for: token)
    }
    
    func fetchConfig(projectId: String? = nil, completion: @escaping (Result<ResponseData, RequestError>?) -> Void) {
        let configOp = LeapConfigFetchOperation(projectId: projectId) { (result: Result<ResponseData, RequestError>?) in
            completion(result)
        }
        fetchQueue.addOperation(configOp)
    }
    
    func saveHeaders(headers:Dictionary<AnyHashable, Any>) {
        var toSaveHeaders:Dictionary<String,String> = [:]
        headers.forEach { (key,value) in
            if let headerField = key as? String, let valueField = value as? String {
                if headerField.starts(with: "x-jiny-") { toSaveHeaders[headerField] = valueField }
            }
        }
        let prefs = UserDefaults.standard
        prefs.set(toSaveHeaders, forKey: "leap_saved_headers")
    }
    
    func resetSavedHeaders() {
        let prefs = UserDefaults.standard
        prefs.setValue([:], forKey: "leap_saved_headers")
    }
    
    func resetSavedHeaders(for token: String) {
        if token != LeapSharedInformation.shared.getAPIKey() { resetSavedHeaders() }
    }
}

fileprivate class LeapConfigFetchOperation: Operation {
    
    let projectId: String?
    let configCallCompletion: (Result<ResponseData, RequestError>?) -> Void
    
    private let networkService = LeapNetworkService()
    
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
    
    required init(projectId: String?, completion: @escaping (Result<ResponseData, RequestError>?) -> Void) {
        self.projectId = projectId
        self.configCallCompletion = completion
    }
    
    override func main() {
        guard isCancelled == false else {
            finished(true)
            configCallCompletion(nil)
            return
        }
        self.executing(true)
        fetchConfig(self.projectId) { [weak self] (result: Result<ResponseData, RequestError>?) in
            self?.configCallCompletion(result)
            self?.finished(true)
        }
    }
    
    private func fetchConfig(_ projectId:String? = nil, completion : @escaping (Result<ResponseData, RequestError>) -> Void) {
        
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
        self.networkService.makeUrlRequest(req) { (result: Result<ResponseData, RequestError>) in
            completion(result)
        }
    }
}

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
