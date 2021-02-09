//
//  JinyMediaManager.swift
//  JinyAUI
//
//  Created by Aravind GS on 25/09/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation


enum JinyDownloadStatus:String {
    case notDownloaded = "notDownloaded"
    case isDownloading = "isDownloading"
    case downloaded = "downloaded"
}

protocol JinyMediaManagerDelegate {
    
}

class JinyMediaManager {
    
    let delegate:JinyMediaManagerDelegate
    var statusTracker:Dictionary<String,JinyDownloadStatus> = [:]
    var dlTracker:Dictionary<String,JinyDownloadOperation> = [:]
    
    init (withDelegate:JinyMediaManagerDelegate) {
        delegate = withDelegate
    }
    
    func startDownload(forMedia:JinyMedia, atPriority:Operation.QueuePriority, completion: ((_ sucess: Bool) -> Void)? = nil) {
        var code:String?
        if let sound = forMedia as? JinySound {
            code = sound.langCode
        }
        if isAlreadyDownloaded(mediaName: forMedia.name, langCode: code){
            statusTracker[forMedia.name] = .downloaded
            completion?(true)
            return
        }
        
        if getCurrentMediaStatus(forMedia.name) == nil  {
            let dlop = JinyDownloadOperation(forMedia) { (isRunning, isFinished, isSuccess, location) in
                if isRunning {
                    self.statusTracker[forMedia.name] = .isDownloading
                    
                }
                else if isFinished{
                    if isSuccess {
                        
                        completion?(true)
                        self.statusTracker[forMedia.name] = .downloaded
                        self.dlTracker[forMedia.name] = nil
                    }
                    else {
                        self.statusTracker[forMedia.name] = .notDownloaded
                        completion?(false)
                    }
                }
            }
            dlop.queuePriority = atPriority
            JinyNetWorker.shared.downloadQueue.addOperation(dlop)
            dlTracker[forMedia.name] = dlop
//            statusTracker[forMedia.name] = .notDownloaded
        }
    }
    
    func updatePriority(mediaName:String, toPriority:Operation.QueuePriority) {
        guard let dlop = getDlOp(forMedia: mediaName) else { return }
        dlop.queuePriority = toPriority
    }
    
    func isAlreadyDownloaded(mediaName:String, langCode:String?) -> Bool {
        var fileDest = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileDest = fileDest.appendingPathComponent("Jiny")
        if let code = langCode {
            fileDest = fileDest.appendingPathComponent(code)
        } else {
            fileDest.appendPathComponent("aui_component")
        }
        fileDest = fileDest.appendingPathComponent(mediaName)
        
        if let _ = langCode {
            
           fileDest = fileDest.appendingPathExtension("mp3")
        }
        
        return FileManager.default.fileExists(atPath: fileDest.path)
    }
    
    func getCurrentMediaStatus(_ mediaName:String) -> JinyDownloadStatus? {
        guard let status = statusTracker[mediaName] else { return nil }
        return status
    }
    
    func getDlOp(forMedia:String) -> JinyDownloadOperation? {
        return dlTracker[forMedia]
    }
    
}
