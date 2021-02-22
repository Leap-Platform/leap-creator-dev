//
//  LeapMediaManager.swift
//  LeapAUI
//
//  Created by Aravind GS on 25/09/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation


enum LeapDownloadStatus:Int {
    case notDownloaded
    case isDownloading
    case downloaded
}

class LeapWeakDlOperations {
    weak var op:LeapDownloadOperation?
    init(operation:LeapDownloadOperation) { op = operation }
}

class LeapMediaManager {
    
    var statusTracker:Dictionary<String,LeapDownloadStatus> = [:]
    var dlTracker:Dictionary<String,LeapWeakDlOperations> = [:]
    
    func startDownload(forMedia:LeapMedia, atPriority:Operation.QueuePriority,
                       completion: ((_ success: Bool) -> Void)? = nil) {
        var code:String?
        var key = forMedia.name
        if let sound = forMedia as? LeapSound {
            code = sound.langCode
            key = key + "_\(code!)"
        }
        guard !isAlreadyDownloaded(media: forMedia) else {
            updateStatus(key: key, status: .downloaded)
            completion?(true)
            return
        }
        updateStatus(key: key, status: .notDownloaded)
        let dlOp = LeapDownloadOperation(forMedia) { [weak self] (isRunning, isFinished, isSuccess, location) in
            if isRunning { self?.updateStatus(key: key, status: .isDownloading) }
            else if isFinished {
                self?.updateStatus(key: key, status: isSuccess ? .downloaded : .notDownloaded)
                completion?(isSuccess)
            }
        }
        dlOp.queuePriority = atPriority
        dlTracker[key] = LeapWeakDlOperations(operation: dlOp)
        LeapNetWorker.shared.downloadQueue.addOperation(dlOp)
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
    
    func isAlreadyDownloaded(media:LeapMedia) -> Bool {
        let filePath = LeapSharedAUI.shared.getFilePath(media: media)
        return FileManager.default.fileExists(atPath: filePath.path)
    }
    
    func getCurrentMediaStatus(_ media:LeapMedia) -> LeapDownloadStatus {
        var key = media.name
        if let sound = media as? LeapSound { key = key + "_\(sound.langCode!)"}
        if let status = statusTracker[key] { return status }
        let path = LeapSharedAUI.shared.getFilePath(media: media)
        if FileManager.default.fileExists(atPath: path.path) { return .downloaded }
        return .notDownloaded
    }
    
    func getDlOp(forMedia:String, langCode:String?) -> LeapDownloadOperation? {
        let key = langCode != nil ? "\(forMedia)_\(langCode!)" : forMedia
        return dlTracker[key]?.op
    }
    
    func updateStatus(key:String, status:LeapDownloadStatus) {
        DispatchQueue.main.async { self.statusTracker[key] = status }
    }
    
}
