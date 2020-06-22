//
//  JinyAudioManager.swift
//  JinySDK
//
//  Created by Aravind GS on 20/04/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation


protocol JinyAudioManagerDelegate {
    
    func getDefaultSounds() -> Array<JinySound>
    func getDiscoverySounds() -> Array<JinySound>
    func getStageSounds() -> Array<JinySound>
}

class JinyAudioManager {
    
    var dlTracker:Dictionary<String,Dictionary<String, JinyDownloadOperation>> = [:]
    var delegate:JinyAudioManagerDelegate?
    
    func registerForDownload() {
        if let defaultSounds = delegate?.getDefaultSounds() {
            for defaultSound in defaultSounds {
                if newDlOpToBeCreated(defaultSound) { startDownload(withLink: defaultSound, priority: .normal) }
            }
        }
        
        if let discoverySounds = delegate?.getDiscoverySounds() {
            for discoverySound in discoverySounds {
                 if newDlOpToBeCreated(discoverySound) { startDownload(withLink: discoverySound, priority: .normal) }
            }
        }
        
        if let stageSounds = delegate?.getStageSounds() {
            for stageSound in stageSounds {
                 if newDlOpToBeCreated(stageSound) { startDownload(withLink: stageSound, priority: .low) }
            }
        }
        
    }
    
    func newDlOpToBeCreated(_ sound:JinySound) -> Bool {
        if isDownloaded(sound) {
            JinySharedInformation.shared.setAudioStatus(for: sound.name, in: sound.langCode, to: .downloaded)
            return false
        }
        if isDownloading(sound) {
            JinySharedInformation.shared.setAudioStatus(for: sound.name, in: sound.langCode, to: .isDownloading)
            return false
        }
        JinySharedInformation.shared.setAudioStatus(for: sound.name, in: sound.langCode, to: .notDownloaded)
        if hasDlOpBeenCreatedForSound(sound) { return false }
        return true
    }
    
    func setStatusForSound(_ sound:JinySound, status: JinyDownloadStatus) {
        JinySharedInformation.shared.setAudioStatus(for: sound.name, in: sound.langCode, to: status)
    }
    
    func isDownloaded(_ sound:JinySound) -> Bool{
        if sound.name == "" || sound.url == nil || sound.version == -1 { return false }
        let fileName = getFileLocation(sound)
        return FileManager.default.fileExists(atPath: fileName.path)
    }
    
    func isDownloading(_ sound:JinySound) -> Bool {
        let dlStatus = JinySharedInformation.shared.getAudioStatusForLangCode(sound.langCode, audioName: sound.name)
        return dlStatus == .isDownloading
    }
    

    func startDownload(withLink audioLink:JinySound, priority:Operation.QueuePriority) {
        guard let langCode = JinySharedInformation.shared.getLanguage() else { return }
        guard audioLink.langCode == langCode else { return }
        let dlOp = JinyDownloadOperation(audioLink) { (isRunning, isFinished, isSuccess, finalLocation) in
            if isRunning { self.setStatusForSound(audioLink, status: .isDownloading) }
            if isFinished {
                if isSuccess { self.setStatusForSound(audioLink, status: .downloaded) }
                else { self.setStatusForSound(audioLink, status: .notDownloaded) }
            }
            
        }
        dlOp.queuePriority = priority
        dlTracker[audioLink.langCode] = [audioLink.name:dlOp]
        JinyNetWorker.shared.downloadQueue.addOperation(dlOp)
    }
    
    func saveFile(_ sound:JinySound, _ tempLocation:URL) {
        let finalLocation = getFileLocation(sound)
        if  !checkIfJinyFolderExists() {
            do {
                try FileManager.default.createDirectory(at: getJinyFolderPath().absoluteURL, withIntermediateDirectories: true, attributes: [:])
            } catch let err {
                print(err.localizedDescription)
                return
            }
        }
        do {
            try FileManager.default.copyItem(at: tempLocation, to: finalLocation)
        } catch let copyError {
            print(copyError.localizedDescription)
            return
        }
    }
    
    func checkIfJinyFolderExists() -> Bool {
        var isDirectory = ObjCBool(true)
        if !FileManager.default.fileExists(atPath: getJinyFolderPath().absoluteString, isDirectory: &isDirectory) {return false}
        if !(isDirectory.boolValue) {return false}
        return true
    }
    
    func getFileLocation(_ sound:JinySound) -> URL {
        let fileName = sound.name + "_" + String(sound.version) + ".mp3"
        let completeFilePath = getJinyFolderPath().appendingPathComponent(sound.langCode).appendingPathComponent(fileName)
        return completeFilePath
    }
    
    func getJinyFolderPath() ->URL {
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let jinyFolderPath = documentPath.appendingPathComponent("Jiny")
        return jinyFolderPath
    }
    
    func hasDlOpBeenCreatedForSound(_ sound:JinySound) -> Bool {
        guard let langDict = dlTracker[sound.langCode] else { return false }
        guard let _ = langDict[sound.name] else { return false }
        return true
    }
    
}


extension JinyAudioManager:JinyContextManagerAudioDelegate {
    
    func getAudioStatus(_ sound:JinySound) -> JinyDownloadStatus? {
        return JinySharedInformation.shared.getAudioStatusForLangCode(sound.langCode, audioName: sound.name)
    }

    func changePriorityForSound(_ sound:JinySound, priority:Operation.QueuePriority) {
        guard let langDict = dlTracker[sound.langCode] else { return }
        guard let dlOp = langDict[sound.name] else { return }
        dlOp.queuePriority = priority
    }
    
    func languageChanged() { registerForDownload() }
    
}
