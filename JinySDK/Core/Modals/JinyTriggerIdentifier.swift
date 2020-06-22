//
//  JinyTriggerIdentifiers.swift
//  JinySDK
//
//  Created by Aravind GS on 02/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyTriggerIdentifier {
    
    var nativeIdentifiers:Array<JinyNativeIdentifer> = []
    var webIdentifiers:Array<JinyIdentifier> = []
    
    init(dict:Dictionary<String,Any>) {
        let nativeIdentiferDictsArray = dict["native_identifiers"] as? Array<Dictionary<String,Any>> ?? []
        for nativeIdentiferDict in nativeIdentiferDictsArray {
            let nativeIdentifier = JinyNativeIdentifer(withDict: nativeIdentiferDict)
            nativeIdentifiers.append(nativeIdentifier)
            
        }
        
        let webIdentiferDictsArray = dict["web_identifiers"] as? Array<Dictionary<String,Any>> ?? []
        for webIdentiferDict in webIdentiferDictsArray {
            let webIdentifier = JinyIdentifier(withDict: webIdentiferDict)
            webIdentifiers.append(webIdentifier)
        }
    }
    
}
