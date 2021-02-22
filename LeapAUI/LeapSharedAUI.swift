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
    
    func getFolderPath(media:LeapMedia) -> URL {
        if let sound = media as? LeapSound { return getSoundsFolderPath(langCode: sound.langCode!) }
        return getAUIContentFolderPath()
    }
    
    func getFilePath(media:LeapMedia) -> URL {
        guard let sound = media as? LeapSound else { return getAUIContentFolderPath().appendingPathComponent(media.name) }
        return getSoundsFolderPath(langCode: sound.langCode!).appendingPathComponent(sound.name).appendingPathExtension(sound.format)
    }
    
    func getFilePath(mediaName:String, langCode:String?) -> URL? {
        var folderPath = langCode != nil ? getSoundsFolderPath(langCode: langCode!) : getAUIContentFolderPath()
        if let code = langCode { folderPath.appendPathComponent(code) }
        return nil
    }
    
    func getSoundFilePath(name:String, code:String, format:String = "mp3") -> URL {
        let soundsFolder = getSoundsFolderPath(langCode: code)
        let soundPath = soundsFolder.appendingPathComponent(name).appendingPathExtension(format)
        return soundPath
    }
    
}
