//
//  AppStateProtocol.swift
//  JinyAuthSDK
//
//  Created by Shreyansh Sharma on 30/10/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

protocol AppStateProtocol {
    
    func onApplicationInForeground()->Void
    func onApplicationInBackground()->Void
    func onApplicationInTermination()->Void
    
}
