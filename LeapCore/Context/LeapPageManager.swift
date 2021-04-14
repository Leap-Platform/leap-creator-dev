//
//  LeapPageManager.swift
//  LeapCore
//
//  Created by Aravind GS on 27/01/21.
//  Copyright © 2021 Leap Inc. All rights reserved.
//

import Foundation

protocol LeapPageManagerDelegate:NSObjectProtocol {
    func newPageIdentified()
}

class LeapPageManager {
 
    private weak var delegate:LeapPageManagerDelegate?
    private var currentPage:LeapPage?
    
    init(_ pageDelegate:LeapPageManagerDelegate) {
        delegate = pageDelegate
    }
    
    func setCurrentPage(_ page:LeapPage?) {
        if currentPage == nil && page == nil { return }
        if currentPage == page { return }
        currentPage = page?.copy()
        if page != nil { delegate?.newPageIdentified() }
    }
    
    func getCurrentPage() -> LeapPage? { return currentPage }
    
    func removeStage(_ stage:LeapStage) {
        guard let currentPage = currentPage else { return }
        currentPage.stages = currentPage.stages.filter{ $0 != stage }
    }
    func resetPageManager() { currentPage = nil }
    
}
