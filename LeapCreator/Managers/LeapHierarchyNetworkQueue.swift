//
//  LeapImageNetworkQueue.swift
//  LeapCreatorSDK
//
//  Created by Aravind GS on 26/08/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation


class LeapHierarchyOperation:Operation {
    
    let socket:WebSocket
    let stringToSend:String

    override var isAsynchronous: Bool {
        get {
            return true
        }
    }
    
    private var _executing = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    override var isExecuting: Bool {
        return _executing
    }
    
    private var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isFinished: Bool {
        return _finished
    }
    
    func executing (_ executing:Bool) {
        _executing = executing
    }
    
    func finished(_ finished:Bool) {
        _finished = finished
    }
    
    required init(socketTask:WebSocket, string:String) {
        socket = socketTask
        stringToSend = string
    }

    override func main() {
        guard isCancelled == false else {
            finished(true)
            return
        }
        self.executing(true)
        socket.write(string: self.stringToSend) {
            self.finished(true)
        }
    }
}

class LeapHierarchyNetworkQueue {
    
    static var shared = LeapHierarchyNetworkQueue()
    var tempOpsArray: Array<LeapHierarchyOperation> = []
    var observation:NSKeyValueObservation?
    lazy var hierarchyQueue:OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Leap Hierarchy Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    init() {
        self.observation = hierarchyQueue.observe(\.operationCount, options: NSKeyValueObservingOptions.new, changeHandler: {[unowned self] queue, changed in
            guard changed.newValue == 0 else { return }
            self.addOperations(ops: self.tempOpsArray)
        })
    }
    
    func operationToSend(ops:Array<LeapHierarchyOperation>) {
        tempOpsArray += ops
        addOperations(ops: tempOpsArray)
    }
    
    func addOperations(ops:Array<LeapHierarchyOperation>) {
        guard hierarchyQueue.operationCount == 0, tempOpsArray.count > 0 else { return }
        let lastIndex = tempOpsArray.count > 20 ? 20 : tempOpsArray.count
        let subArray:Array<LeapHierarchyOperation> = Array(tempOpsArray[0..<lastIndex])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.hierarchyQueue.addOperations(subArray, waitUntilFinished: false)
            self.tempOpsArray.removeFirst(lastIndex)
        }
    }
}
