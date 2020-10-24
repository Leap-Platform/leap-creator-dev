//
//  JinyInstruction.swift
//  JinySDK
//
//  Created by Aravind GS on 29/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

class JinyInstruction {
    
    var soundName:String?
    var assistInfo:JinyAssistInfo?
    
    init(withDict instructionDict:Dictionary<String,Any>) {
        soundName = instructionDict["sound_name"] as? String
        if let assistInfoDict = instructionDict["assist_info"] as? Dictionary<String,Any> {
            assistInfo = JinyAssistInfo(withDict: assistInfoDict)
        }
    }
    
}
