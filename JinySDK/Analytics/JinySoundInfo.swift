//
//  JinySoundInfo.swift
//  JinySDK
//
//  Created by Aravind GS on 29/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import AVFoundation

class JinySoundInfo:Codable {
    
    var sound_name:String
    var sound_version:String
    var volume_level:String
    var player_type:String
    
    init(sound:JinySound) {
        sound_name = sound.name
        sound_version = String(sound.version)
        volume_level = String(AVAudioSession.sharedInstance().outputVolume)
        player_type = ""
    }
    
}
