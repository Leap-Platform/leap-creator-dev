//
//  LeapContextDetector.swift
//  LeapCore
//
//  Created by Aravind GS on 06/05/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// LeapContextDetectorDelegate is a protocol that is to be implemented by the class that needs to communicate with the LeapContextDetector class. This protocol provides callbacks regarding which discovery, page and stage is identifed. It also asks the delegate to provide the relevant flow/discoveries to check from.
protocol LeapContextDetectorDelegate:NSObjectProtocol {
    
    func getWebIdentifier(identifierId:String) -> LeapWebIdentifier?
    func getNativeIdentifier(identifierId:String) -> LeapNativeIdentifier?
    func getNativeIdentifierDict() -> [String:LeapNativeIdentifier]
    func getWebIdentifierDict() -> [String:LeapWebIdentifier]
    
    func getContextsToCheck() -> Array<LeapContext>
    func getLiveContext() -> LeapContext?
    func contextDetected(context:LeapContext, view:UIView?, rect: CGRect?, webview:UIView?)
    func noContextDetected()
    
    func isDiscoveryFlowMenu() -> Bool
    func getFlowMenuDiscovery() -> LeapDiscovery?
    func getCurrentFlow() -> LeapFlow?
    func getParentFlow() -> LeapFlow?
    func isStaticFlow() -> Bool
    
    func pageIdentified(_ page:LeapPage)
    func pageNotIdentified(flowMenuIconNeeded:Bool?)
    
    func getStagesToCheck() -> Array<LeapStage>
    func getCurrentStage() -> LeapStage?
    func stageIdentified(_ stage:LeapStage, pointerView:UIView?, pointerRect:CGRect?, webviewForRect:UIView?,flowMenuIconNeeded:Bool?)
    func stageNotIdentified(flowMenuIconNeeded:Bool?)
}

enum LeapContextDetectionState {
    case Discovery
    case Stage
}

/// LeapContextDetector class fetches the assist,discovery or flow to be detected  using its delegate and identifies the dsicovery or stage every 1 second. It informs it delegate which assist, discovery, page, stage has been identified
class LeapContextDetector:NSObject {
    
    private weak var delegate:LeapContextDetectorDelegate?
    private var contextTimer:Timer?
    private var state:LeapContextDetectionState = .Discovery
    private lazy var clickHandler:LeapClickHandler = {
        let clickHandler = LeapClickHandler.shared
        clickHandler.delegate = self
        return clickHandler
    }()
    
    /// Initialzation method
    /// - Parameter contextDetectorDelegate: Object implementing context detector delegate methods to assist in to and fro communication
    init(withDelegate contextDetectorDelegate:LeapContextDetectorDelegate) {
        delegate = contextDetectorDelegate
        super.init()
    }
    
    /// Get current state of context detection. Is it searching for a discovery  or  a stage?
    /// - Returns: The state
    func getState() ->LeapContextDetectionState { return state }
    
    /// Switch the state of the context detection
    func switchState() {
        switch state {
        case .Discovery:
            state = .Stage
        case .Stage:
            state = .Discovery
        }
    }
}

// MARK: - TIMER HANDLER
extension LeapContextDetector {
    
    /// Start context detection by starting one second timer
    func start() {
        contextTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(fetchViewPropsHierarchy), userInfo: nil, repeats: true)
    }
    
    /// Stop context detection by invalidating and removing timer
    func stop() {
        contextTimer?.invalidate()
        contextTimer = nil
    }
}

// MARK: - HIERARCHY FETCHER
extension LeapContextDetector {
    
    /// Get hierachy and proceed to find context
    @objc private func fetchViewPropsHierarchy() {
        let controller:String? = {
            guard let currentVC = UIApplication.getCurrentVC() else { return nil }
            return String(describing: type(of: currentVC.self))
        }()
        
        let hierarchyFetcher = LeapHierarchyFetcher(forController: controller)
        let viewPropsHierarchy = hierarchyFetcher.fetchHierarchy()
        identifyContext(in: viewPropsHierarchy)
    }
    
}

// MARK: - ASSIST/DISCOVERY IDENTIFICATION
extension LeapContextDetector {
    
    /// Identify valid contexts from all relevant contexts (assists & discoveries)
    /// - Parameter hierachy: The hierarchy to check contexts in
    private func identifyContext(in hierachy:[String:LeapViewProperties]) {
        switch state {
        case .Discovery:
            guard let relevantContexts = self.delegate?.getContextsToCheck() else { return }
            let nativeIdDict = self.delegate?.getNativeIdentifierDict() ?? [:]
            let webIdDict = self.delegate?.getWebIdentifierDict() ?? [:]
            let contextValidator = LeapContextsValidator<LeapContext>(withNativeDict: nativeIdDict, webDict: webIdDict)
            contextValidator.findValidContextsIn(hierachy,
                                                 contexts: relevantContexts) {[weak self] validContexts in
                self?.triggerAssistOrDiscovery(validContexts, inHierarchy: hierachy, using: contextValidator)
            }
        case .Stage:
            if delegate?.isStaticFlow() ?? false { self.findValidStages(inHierarchy: hierachy) }
            else { findValidPages(inHierachy: hierachy, from: delegate?.getCurrentFlow()) }
        }
    }
    
    /// Trigger the most relevant contex
    /// - Parameters:
    ///   - validContexts: All passing contexts in current hierarchy
    ///   - hierarchy: The hierarchy in which the context is relevant
    ///   - contextValidator: The validator that helps to determine the most relevant context to trigger
    private func triggerAssistOrDiscovery(_ validContexts:[LeapContext], inHierarchy hierarchy:[String:LeapViewProperties], using contextValidator:LeapContextsValidator<LeapContext>) {
        guard validContexts.count > 0 else {
            self.delegate?.noContextDetected()
            return
        }
        let liveContext = self.delegate?.getLiveContext()
        contextValidator.getTriggerableContext(liveContext,
                                               validContexts: validContexts,
                                               hierarchy: hierarchy) {[weak self] contextToTrigger, anchorViewId, anchorRect, anchorWebview in
            guard let context = contextToTrigger else {
                self?.addClickListenersIfNeeded(validContexts, inHierarchy: hierarchy)
                self?.delegate?.noContextDetected()
                return
            }
            self?.clickHandler.removeAllClickListeners()
            let anchorView = hierarchy[anchorViewId ?? "nil"]?.weakView
            self?.delegate?.contextDetected(context: context, view: anchorView, rect: anchorRect, webview: anchorWebview)
        }
    }
}


// MARK: - PAGE AND STAGE DETECTION
extension LeapContextDetector {
    
    /// Finds the list of valid pages if a flow is opted in
    /// - Parameters:
    ///   - inHierachy: The hierarchy to check in
    ///   - flow: The flow that has been opted in
    private func findValidPages(inHierachy:[String:LeapViewProperties], from flow:LeapFlow?) {
        
        guard let flow = flow else {
            showFlowMenuButton(inHierarchy: inHierachy) {[weak self] show in
                self?.delegate?.pageNotIdentified(flowMenuIconNeeded: show)
            }
            return
        }
        let nativeIdDict = self.delegate?.getNativeIdentifierDict() ?? [:]
        let webIdDict = self.delegate?.getWebIdentifierDict() ?? [:]
        let pageValidator = LeapContextsValidator<LeapPage>(withNativeDict: nativeIdDict, webDict: webIdDict)
        pageValidator.findValidContextsIn(inHierachy,
                                          contexts: flow.pages) {[weak self] validPages in
            guard validPages.count > 0 else {
                self?.findValidPages(inHierachy: inHierachy, from: self?.delegate?.getParentFlow())
                return
            }
            self?.getRelevantPage(from: validPages, in: inHierachy, using: pageValidator)
        }
    }
    
    /// Find the most relevant page from the list of valid pages
    /// - Parameters:
    ///   - validPages: Valid pages in the flow to check in
    ///   - hierarchy: The hierarchy in which the valid pages have been identified
    ///   - pageValidator: The page validator object to help to determine the most relevant page
    private func getRelevantPage(from validPages:[LeapPage], in hierarchy:[String:LeapViewProperties], using pageValidator:LeapContextsValidator<LeapPage>) {
        guard let relevantPage = pageValidator.highestPreferredContext(validPages) else {
            findValidPages(inHierachy: hierarchy, from: delegate?.getParentFlow())
            return
        }
        self.delegate?.pageIdentified(relevantPage)
        findValidStages(inHierarchy: hierarchy)
    }
    
    /// Find valid stages from list of stages relevant to identified page or to check if next stage is valid in static flow
    /// - Parameter inHierarchy: The hierachy to check the valid stages in
    private func findValidStages(inHierarchy:[String:LeapViewProperties]) {
        guard let stagesToCheck = delegate?.getStagesToCheck(), stagesToCheck.count > 0 else {
            showFlowMenuButton(inHierarchy: inHierarchy) {[weak self] show in
                self?.delegate?.stageNotIdentified(flowMenuIconNeeded: show)
            }
            return
        }
        let nativeIdDict = self.delegate?.getNativeIdentifierDict() ?? [:]
        let webIdDict = self.delegate?.getWebIdentifierDict() ?? [:]
        let stageValidator = LeapContextsValidator<LeapStage>(withNativeDict: nativeIdDict, webDict: webIdDict)
        let allStagesToCheck = self.delegate?.getStagesToCheck() ?? []
        stageValidator.findValidContextsIn(inHierarchy, contexts:allStagesToCheck) {[weak self] validStages in
            guard validStages.count > 0 else {
                self?.showFlowMenuButton(inHierarchy: inHierarchy) { show in
                    self?.delegate?.stageNotIdentified(flowMenuIconNeeded: show)
                }
                return
            }
            self?.triggerRelevantStage(from: validStages, in: inHierarchy, using: stageValidator)
        }
    }
    
    /// To trigger the most relevant stage from the list of valid stages
    /// - Parameters:
    ///   - validStages: List of valid stages in the current page
    ///   - hierarchy: The hierarchy in which the stages are valid
    ///   - stageValidator: The stage validator object which helps in identifiying most relevant stage to trigger
    private func triggerRelevantStage(from validStages:[LeapStage], in hierarchy:[String:LeapViewProperties], using stageValidator:LeapContextsValidator<LeapStage>) {
        let liveStage = self.delegate?.getCurrentStage()
        stageValidator.getTriggerableContext(liveStage, validContexts: validStages, hierarchy: hierarchy) {[weak self] stageToTrigger, anchorViewId, anchorRect, anchorWebview in
            guard let contextToTrigger = stageToTrigger else {
                self?.addClickListenersIfNeeded(validStages, inHierarchy: hierarchy)
                self?.showFlowMenuButton(inHierarchy: hierarchy, completion: { show in
                    self?.delegate?.stageNotIdentified(flowMenuIconNeeded: show)
                })
                return
            }
            self?.clickHandler.removeAllClickListeners()
            let anchorView = hierarchy[anchorViewId ?? "nil"]?.weakView
            self?.showFlowMenuButton(inHierarchy: hierarchy, completion: { show in
                self?.delegate?.stageIdentified(contextToTrigger, pointerView: anchorView, pointerRect: anchorRect, webviewForRect: anchorWebview, flowMenuIconNeeded: show)
            })
        }
    }
    
    /// Helps to determine if the leap icon is to be shown in case it is a flow menu launch screen
    /// - Parameters:
    ///   - inHierarchy: The hierarchy to check in
    ///   - completion: Completion callback returning a bool value, showing if the icon is to be shown
    private func showFlowMenuButton(inHierarchy:[String:LeapViewProperties], completion:@escaping(_ show:Bool?)->Void) {
        guard delegate?.isDiscoveryFlowMenu() ?? false, let discovery = delegate?.getFlowMenuDiscovery() else {
            completion(nil)
            return
        }
        let nativeIdDict = self.delegate?.getNativeIdentifierDict() ?? [:]
        let webIdDict = self.delegate?.getWebIdentifierDict() ?? [:]
        let contextValidator = LeapContextsValidator<LeapContext>(withNativeDict: nativeIdDict, webDict: webIdDict)
        contextValidator.findValidContextsIn(inHierarchy,
                                             contexts: [discovery]) { validContexts in
            completion(validContexts.contains(discovery))
        }
    }
    
}

// MARK: - CLICK LISTENER IMPLEMENTERS
extension LeapContextDetector {
    
    /// Add click event listeners to event triggered  contexts
    /// - Parameters:
    ///   - contexts: List of valid event triggered contexts
    ///   - inHierarchy: Hierarchy in which the valid contexts exists
    private func addClickListenersIfNeeded(_ contexts:[LeapContext], inHierarchy:[String:LeapViewProperties]) {
        
        let clickEventTriggeredContexts = contexts.filter { context in
            guard let trigger = context.trigger else { return true }
            guard let _ = context.instruction?.assistInfo?.identifier else { return false }
            return trigger.type == .event
        }
        guard clickEventTriggeredContexts.count > 0 else { return }
        
        let (nativeContexts,webContexts):([LeapContext],[LeapContext]) = clickEventTriggeredContexts.reduce(([],[])) { (partialResult, context) -> ([LeapContext],[LeapContext]) in
            var (tempNativeContexts, tempWebContexts) = partialResult
            if let isWeb = context.instruction?.assistInfo?.isWeb {
                if isWeb { tempWebContexts.append(context) }
                else { tempNativeContexts.append(context) }
            }
            return(tempNativeContexts,tempWebContexts)
        }
        
        if nativeContexts.count > 0 { addNativeClickListeners(nativeContexts: nativeContexts, inHierarchy: inHierarchy) }
        if webContexts.count > 0 { addWebClickListeners(webContexts: webContexts, inHierarchy: inHierarchy) }
    }
    
    /// Add native click listeners to valid contexts whose identifiers are native elements
    /// - Parameters:
    ///   - nativeContexts: The valid native contexts
    ///   - inHierarchy: The hierarchy in which the contexts are valid
    func addNativeClickListeners(nativeContexts:[LeapContext], inHierarchy:[String:LeapViewProperties]) {
        let nativeViewFinder = LeapNativeViewFinder(with: inHierarchy)
        let contextIdViewTuples = nativeContexts.compactMap { context -> (Int,UIView)? in
            guard let identifier = context.instruction?.assistInfo?.identifier,
                  let nativeIdentifier = self.delegate?.getNativeIdentifier(identifierId: identifier),
                  let viewId = nativeViewFinder.viewIdFor(nativeIdentifier),
                  let targetView = inHierarchy[viewId]?.weakView else { return nil }
            return (context.id, targetView)
        }
        clickHandler.addClickListeners(contextIdViewTuples)
    }
    
    /// Add web click listenters to valid contexts whose identifiers are web elements
    /// - Parameters:
    ///   - webContexts: The valid web contexts to setup click listeners for
    ///   - inHierarchy: The hierarchy in which contexts are valid
    func addWebClickListeners(webContexts:[LeapContext], inHierarchy:[String:LeapViewProperties]) {
        var allContextInfo:[WKWebView:[[String:Any]]] = [:]
        var webIdsToCheck = webContexts.map { (context) -> String? in
            return context.instruction?.assistInfo?.identifier
        }.compactMap{ return $0 }
        
        func getWebIdIdentifierTuples(_ idsToCheck:[String]) -> [(String,LeapWebIdentifier)] {
            return webIdsToCheck.compactMap { webId -> (String,LeapWebIdentifier)? in
                guard let identifier = self.delegate?.getWebIdentifier(identifierId: webId) else { return nil }
                return(webId,identifier)
            }
        }
        
        let leapWebViewFinder = LeapWebViewFinder(with: inHierarchy)
        let webviews:[WKWebView] = leapWebViewFinder.webviewProps.compactMap { return $0.weakView as? WKWebView }
        var counter = 0
        var completion:((_:[String])->Void)?
        completion = {[weak self] passedIds in
            if passedIds.count > 0 {
                webIdsToCheck = webIdsToCheck.filter { !passedIds.contains($0) }
                for passedId in passedIds {
                    let contextsPassedForId = webContexts.filter{ $0.instruction?.assistInfo?.identifier ?? "" == passedId}
                    let contextInfo:[[String:Any]] = contextsPassedForId.compactMap { context -> [String:Any]? in
                        guard let webIdentifier = self?.delegate?.getWebIdentifier(identifierId: passedId) else { return nil }
                        return [ "id" : context.id, "identifier" : webIdentifier ]
                    }
                    if contextInfo.count > 0 { allContextInfo[webviews[counter]] = contextInfo }
                }
            }
            counter += 1
            guard counter < webviews.count else {
                self?.clickHandler.addClickListener(to: allContextInfo)
                return
            }
            leapWebViewFinder.webIdsPassingIn(getWebIdIdentifierTuples(webIdsToCheck), passingIn: webviews[counter], completion: completion!)
        }
        leapWebViewFinder.webIdsPassingIn(getWebIdIdentifierTuples(webIdsToCheck), passingIn: webviews[counter], completion: completion!)
    }
    
}

// MARK: - CLICK HANDLER DELEGATE METHODS
extension LeapContextDetector:LeapClickHandlerDelegate {
    func nativeClickEventForContext(id: Int, onView: UIView) {
        guard let allContexts = state == .Discovery ? delegate?.getContextsToCheck() : delegate?.getStagesToCheck() else { return }
        let contextFound = allContexts.first { $0.id == id }
        guard let triggerContext = contextFound else { return }
        stop()
        switch self.state {
        case .Discovery:
            self.delegate?.contextDetected(context: triggerContext, view: onView, rect: nil, webview: nil)
        case .Stage:
            guard let stage = triggerContext as? LeapStage else { return }
            self.delegate?.stageIdentified(stage, pointerView: onView, pointerRect: nil, webviewForRect: nil, flowMenuIconNeeded: false)
        }
        start()
    }
    
    func webClickEventForContext(id:Int) {
        guard let allContexts = state == .Discovery ? delegate?.getContextsToCheck() : delegate?.getStagesToCheck() else { return }
        let contextFound = allContexts.first { $0.id == id }
        guard let triggerContext = contextFound,
              let controller = UIApplication.getCurrentVC() else { return }
        let controllerString = String(describing: type(of: controller.self))
        let hierarchyFetcher = LeapHierarchyFetcher(forController: controllerString)
        let hierarchy = hierarchyFetcher.fetchHierarchy()
        var webviews:[WKWebView] = []
        hierarchy.forEach { _, viewProps in
            if let webview = viewProps.weakView as? WKWebView { webviews.append(webview) }
        }
        stop()
        let nativeDict = self.delegate?.getNativeIdentifierDict() ?? [:]
        let webDict = self.delegate?.getWebIdentifierDict() ?? [:]
        let contextValidator = LeapContextsValidator<LeapContext>(withNativeDict: nativeDict, webDict: webDict)
        contextValidator.getTriggerableContext(nil,
                                               validContexts: [triggerContext],
                                               hierarchy: hierarchy) {[weak self] contextToTrigger, anchorViewId, anchorRect, anchorWebview in
            if let contextToTrigger = contextToTrigger, let state = self?.state {
                switch state {
                case .Discovery:
                    self?.delegate?.contextDetected(context: contextToTrigger, view: nil, rect: anchorRect, webview: anchorWebview)
                case .Stage:
                    guard let stage = triggerContext as? LeapStage else { return }
                    self?.delegate?.stageIdentified(stage, pointerView: nil, pointerRect: anchorRect, webviewForRect: anchorWebview, flowMenuIconNeeded: false)
                }
            }
            self?.start()
        }
    }
}
