//
//  JinyNetworking.swift
//  JinySDK
//
//  Created by Aravind GS on 17/03/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import Foundation

// MARK: - JINY OPERATIONS CLASS

class JinyOperation:Operation {
    
    var request:URLRequest
    var statusUpdate: ((_ isRunning:Bool,_ isFinished:Bool,_ isSuccess:Bool, _ location:URL?) -> Void)
    
    var session:URLSession = URLSession.shared
    
    lazy var fm:FileManager = {
        return FileManager.default
    }()
    
    override var isAsynchronous: Bool {
        get {
            return true
        }
    }
    
    private var _executing = false {
        willSet {
            willChangeValue(forKey: Constants.Networking.isExecuting)
        }
        didSet {
            didChangeValue(forKey: Constants.Networking.isExecuting)
        }
    }
    
    override var isExecuting: Bool {
        return _executing
    }
    
    private var _finished = false {
        willSet {
            willChangeValue(forKey: Constants.Networking.isFinished)
        }
        didSet {
            didChangeValue(forKey: Constants.Networking.isFinished)
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
    
    required init(_ request:URLRequest,  _ success: @escaping ((Bool, Bool, Bool, URL?) -> Void)) {
        self.request = request
        self.statusUpdate = success
    }

    override func main() {
        guard isCancelled == false else {
            finished(true)
            return
        }
        statusUpdate(true, false, false, nil)
        self.executing(true)
        
    }
    
}

// MARK: - JINY DOWNLOAD OPERATION CLASS - SUBCLASS OF JINY OPERATION

class JinyDownloadOperation: JinyOperation {
    
    let media:JinyMedia
    
    init(_ file: JinyMedia, _ success: @escaping ((Bool, Bool, Bool, URL?) -> Void)) {
        media = file
        let request = URLRequest(url: media.url)
        super.init(request,success)
    }
    
    required init(_ request: URLRequest, _ success: @escaping ((Bool, Bool, Bool, URL?) -> Void)) {
        fatalError("init(_:_:) has not been implemented")
    }
    
    override func main() {
        super.main()
        downloadFile()
    }
    
    func downloadFile() {
        let filePath = JinySharedAUI.shared.getFilePath(media: media)
        guard !fm.fileExists(atPath: filePath.path) else {
            self.executing(false)
            self.finished(true)
            self.statusUpdate(false,true,true,filePath)
            return
        }
        let request = URLRequest(url: media.url)
        let dlTask = session.downloadTask(with: request) { (fileUrl, urlResponse, error) in
            self.executing(false)
            self.finished(true)
            guard let tempLocation = fileUrl else {
                self.statusUpdate(false, true, false, nil)
                return
            }
            self.copyFileToJinyFolder(tempLocation)
            self.statusUpdate(false, true, true, filePath)
        }
        dlTask.resume()
    }
    
    func copyFileToJinyFolder(_ inputLocation: URL) {
        let folderPath = JinySharedAUI.shared.getFolderPath(media: media)
        if !JinySharedAUI.shared.checkIfFolderExists(folder: folderPath) {
            do { try fm.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: [:]) }
            catch let folderCreationError { fatalError("Failed to create Jiny folder becaues \(folderCreationError.localizedDescription)") }
        }
        let filePath = JinySharedAUI.shared.getFilePath(media: media)
        if fm.fileExists(atPath: filePath.path) { return }
        do { try fm.copyItem(atPath: inputLocation.path, toPath: filePath.path) }
        catch let fileCopyError { fatalError("Failed to copy file because \(fileCopyError.localizedDescription)") }
    }
    
}


// MARK: - JINY NETWORKER CLASS - HANDLES OPERATIONS QUEUE
class JinyNetWorker {
    
    static var shared = JinyNetWorker()
    lazy var downloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = Constants.Networking.downloadQ
        queue.maxConcurrentOperationCount = 4
        return queue
        
    }()
    lazy var dataQueue: OperationQueue = {
           var queue = OperationQueue()
           queue.name = Constants.Networking.dataQ
           queue.maxConcurrentOperationCount = 1
           return queue
           
    }()
}

// MARK: - NETWORKING CLASS CONSTANTS

struct Constants {
    struct Networking {
        static let isExecuting = "isExecuting"
        static let isFinished = "isFinished"
        static let downloadQ = "Jiny Download Queue"
        static let dataQ = "Jiny Data Queue"
        static let downloadsFolder = "Jiny"
        static let analyticsEndPoint = "https://dev.jiny.io/api/jiny/v1/sendAnalytics"
    }
}
