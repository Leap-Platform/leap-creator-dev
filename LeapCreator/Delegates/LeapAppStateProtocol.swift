//
//  LeapAppStateProtocol.swift
//  LeapCreator
//
//  Created by Shreyansh Sharma on 30/10/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit

protocol LeapAppStateProtocol {
    
    func onApplicationInForeground()->Void
    func onApplicationInBackground()->Void
    func onApplicationInTermination()->Void
    
}
