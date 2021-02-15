//
//  JinyMediaManager.swift
//  JinyAUI
//
//  Created by Aravind GS on 25/09/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation


enum JinyDownloadStatus:Int {
    case notDownloaded
    case isDownloading
    case downloaded
}

class WeakOp {
    weak var op:JinyDownloadOperation?
    init(operation:JinyDownloadOperation) { op = operation }
}

class JinyMediaManager {
    
    var statusTracker:Dictionary<String,JinyDownloadStatus> = [:]
    var dlTracker:Dictionary<String,WeakOp> = [:]
    
    func startDownload(forMedia:JinyMedia, atPriority:Operation.QueuePriority,
                       completion: ((_ success: Bool) -> Void)? = nil) {
        var code:String?
        var key = forMedia.name
        if let sound = forMedia as? JinySound {
            code = sound.langCode
            key = key + "_\(code!)"
        }
        guard !isAlreadyDownloaded(media: forMedia) else {
            updateStatus(key: key, status: .downloaded)
            completion?(true)
            return
        }
        updateStatus(key: key, status: .notDownloaded)
        let dlOp = JinyDownloadOperation(forMedia) { [weak self] (isRunning, isFinished, isSuccess, location) in
            if isRunning { self?.updateStatus(key: key, status: .isDownloading) }
            else if isFinished {
                self?.updateStatus(key: key, status: isSuccess ? .downloaded : .notDownloaded)
                completion?(isSuccess)
            }
        }
        dlOp.queuePriority = atPriority
        dlTracker[key] = WeakOp(operation: dlOp)
        JinyNetWorker.shared.downloadQueue.addOperation(dlOp)
    }
    
    func overrideMediaDownloadCompletion(_ media:String, code:String?, finished:@escaping(_ isSuccess:Bool)->Void){
        guard let dlOp = getDlOp(forMedia: media, langCode: code) else {
            finished(false)
            return
        }
        dlOp.statusUpdate = {[weak self] isRunning, isFinished, isSuccess, location in
            let key = code != nil ? "\(media)_\(code!)" : media
            if isRunning { self?.updateStatus(key: key, status: .isDownloading) }
            else if isFinished {
                self?.updateStatus(key: key, status: isSuccess ? .downloaded : .notDownloaded)
                finished(isSuccess)
            }
        }
    }
    
    func updatePriority(mediaName:String, langCode:String?, toPriority:Operation.QueuePriority) {
        guard let dlop = getDlOp(forMedia: mediaName, langCode: langCode) else { return }
        dlop.queuePriority = toPriority
    }
    
    func isAlreadyDownloaded(media:JinyMedia) -> Bool {
        let filePath = JinySharedAUI.shared.getFilePath(media: media)
        return FileManager.default.fileExists(atPath: filePath.path)
    }
    
    func getCurrentMediaStatus(_ media:JinyMedia) -> JinyDownloadStatus {
        var key = media.name
        if let sound = media as? JinySound { key = key + "_\(sound.langCode!)"}
        if let status = statusTracker[key] { return status }
        let path = JinySharedAUI.shared.getFilePath(media: media)
        if FileManager.default.fileExists(atPath: path.path) { return .downloaded }
        return .notDownloaded
    }
    
    func getDlOp(forMedia:String, langCode:String?) -> JinyDownloadOperation? {
        let key = langCode != nil ? "\(forMedia)_\(langCode!)" : forMedia
        return dlTracker[key]?.op
    }
    
    func updateStatus(key:String, status:JinyDownloadStatus) {
        DispatchQueue.main.async { self.statusTracker[key] = status }
    }
    
}
