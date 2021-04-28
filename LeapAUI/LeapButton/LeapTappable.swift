//
//  LeapTappable.swift
//  LeapSDK
//
//  Created by Ajay S on 28/04/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

protocol LeapTappableDelegate: class {
    
    func iconDidTap()
}

class LeapTappable: UITapGestureRecognizer {
    
    weak var tappableDelegate: LeapTappableDelegate?
    
    init() {
        super.init(target: nil, action: nil)
        self.addTarget(self, action: #selector(didTapHappen(_:)))
        self.delegate = self
    }
    
    @objc func didTapHappen(_ sender: UIPanGestureRecognizer) {
        self.tappableDelegate?.iconDidTap()
    }
}

extension LeapTappable: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
