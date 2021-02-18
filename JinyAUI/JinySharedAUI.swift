//
//  JinySharedAUI.swift
//  JinyAUI
//
//  Created by Ajay S on 17/12/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

class JinySharedAUI {
    
    static let shared = JinySharedAUI()
    let fm = FileManager.default
    var iconHtml: String?
    var iconColor = "#000000"
    
    
    func checkIfFolderExists(folder:URL) -> Bool {
        var isDirectory = ObjCBool(true)
        guard fm.fileExists(atPath: folder.path, isDirectory: &isDirectory), isDirectory.boolValue else { return false }
        return true
    }
    
    func getParentJinyFolder() -> URL {
        return (fm.urls(for: .documentDirectory, in: .userDomainMask)[0]).appendingPathComponent(Constants.Networking.downloadsFolder)
    }
    
    func getSoundsFolderPath(langCode:String) -> URL {
        return getParentJinyFolder().appendingPathComponent(langCode)
    }
    
    func getAUIContentFolderPath() -> URL {
        return getParentJinyFolder().appendingPathComponent("aui_component")
    }
    
    func getFolderPath(media:JinyMedia) -> URL {
        if let sound = media as? JinySound { return getSoundsFolderPath(langCode: sound.langCode!) }
        return getAUIContentFolderPath()
    }
    
    func getFilePath(media:JinyMedia) -> URL {
        guard let sound = media as? JinySound else { return getAUIContentFolderPath().appendingPathComponent(media.name) }
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
