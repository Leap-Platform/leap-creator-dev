//
//  JinyPageManager.swift
//  JinySDK
//
//  Created by Aravind GS on 27/01/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation

protocol JinyPageManagerDelegate:NSObjectProtocol {
    func newPageIdentified()
}

class JinyPageManager {
 
    private weak var delegate:JinyPageManagerDelegate?
    private var currentPage:JinyPage?
    
    init(_ pageDelegate:JinyPageManagerDelegate) {
        delegate = pageDelegate
    }
    
    func setCurrentPage(_ page:JinyPage?) {
        if currentPage == nil && page == nil { return }
        if currentPage == page { return }
        currentPage = page?.copy()
        if page != nil { delegate?.newPageIdentified() }
    }
    
    func getCurrentPage() -> JinyPage? { return currentPage }
    
    func removeStage(_ stage:JinyStage) {
        guard let _ = currentPage else { return }
        currentPage!.stages = currentPage!.stages.filter{ $0 != stage }
    }
    
}
