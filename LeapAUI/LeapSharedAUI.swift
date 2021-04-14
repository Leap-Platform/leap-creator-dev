//
//  LeapSharedAUI.swift
//  LeapAUI
//
//  Created by Ajay S on 17/12/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

class LeapSharedAUI {
    
    static let shared = LeapSharedAUI()
    let fm = FileManager.default
    var iconSetting: LeapIconSetting?
    
    func checkIfFolderExists(folder:URL) -> Bool {
        var isDirectory = ObjCBool(true)
        guard fm.fileExists(atPath: folder.path, isDirectory: &isDirectory), isDirectory.boolValue else { return false }
        return true
    }
    
    func getParentLeapFolder() -> URL {
        return (fm.urls(for: .documentDirectory, in: .userDomainMask)[0]).appendingPathComponent(Constants.Networking.downloadsFolder)
    }
    
    func getSoundsFolderPath(langCode:String) -> URL {
        return getParentLeapFolder().appendingPathComponent(langCode)
    }
    
    func getAUIContentFolderPath() -> URL {
        return getParentLeapFolder().appendingPathComponent("aui_component")
    }
    
    func getFolderPath(media:LeapMedia) -> URL? {
        if let sound = media as? LeapSound, let langCode = sound.langCode { return getSoundsFolderPath(langCode: langCode) }
        return getAUIContentFolderPath()
    }
    
    func getFilePath(media:LeapMedia) -> URL {
        guard let sound = media as? LeapSound, let langCode = sound.langCode else { return getAUIContentFolderPath().appendingPathComponent(media.filename) }
        return getSoundsFolderPath(langCode: langCode).appendingPathComponent(sound.filename)
    }
    
    func getFilePath(mediaName:String, langCode:String?) -> URL? {
        var folderPath = langCode != nil ? getSoundsFolderPath(langCode: langCode!) : getAUIContentFolderPath()
        if let code = langCode { folderPath.appendPathComponent(code) }
        return nil
    }
    
    func getSoundFilePath(name:String, code:String) -> URL {
        let soundsFolder = getSoundsFolderPath(langCode: code)
        let soundPath = soundsFolder.appendingPathComponent(name)
        return soundPath
    }
    
}
