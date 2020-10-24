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
    
    let audio:JinySound
    
    init(_ sound: JinySound, _ success: @escaping ((Bool, Bool, Bool, URL?) -> Void)) {
        audio = sound
        let request = URLRequest(url: audio.url!)
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
        if audio.url == nil {
            self.executing(false)
            self.finished(true)
            self.statusUpdate(false, false, false, nil)
            return
        }
        let request = URLRequest(url: audio.url!)
        let dlTask = session.downloadTask(with: request) { (fileUrl, urlResponse, error) in
            self.executing(false)
            self.finished(true)
            guard let tempLocation = fileUrl else {
                self.statusUpdate(false, true, false, nil)
                return
            }
            self.copyFileToJinyFolder(tempLocation)
            self.statusUpdate(false, true, true, tempLocation)
        }
        dlTask.resume()
    }
    
    func copyFileToJinyFolder(_ inputLocation: URL) {
        let documentPath = self.fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let jinyFolderPath = documentPath.appendingPathComponent(Constants.Networking.downloadsFolder).appendingPathComponent(audio.langCode)
        if !checkIfJinyFolderExists() {
            do {
                try fm.createDirectory(at: jinyFolderPath.absoluteURL, withIntermediateDirectories: true, attributes: [:])
            } catch let err {
                print(err.localizedDescription)
                return
            }
        }
        do {
            try fm.copyItem(at: inputLocation, to: jinyFolderPath.appendingPathComponent(audio.name + "_" + String(audio.version) + ".mp3"))
        } catch let err {
            print(err.localizedDescription)
            return
        }
    }
    
    func checkIfJinyFolderExists() -> Bool {
        let documentPath = self.fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let jinyFolderPath = documentPath.appendingPathComponent(Constants.Networking.downloadsFolder)
        var isDirectory = ObjCBool(true)
        if !fm.fileExists(atPath: jinyFolderPath.absoluteString, isDirectory: &isDirectory) {return false}
        if !(isDirectory.boolValue) {return false}
        return true
    }
    
}

// MARK: - JINY DATA OPERATION CLASS - SUBCLASS OF JINY OPERATION

class JinyDataOperation: JinyOperation {
    override func main() {
        super.main()
        fetchAPI()
    }

    func fetchAPI() {
        let dataTask = session.dataTask(with: request) { (data, urlResponse, error) in
            self.executing(false)
            self.finished(true)
        }
        dataTask.resume()
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

extension Constants {
    struct Networking {
        static let isExecuting = "isExecuting"
        static let isFinished = "isFinished"
        static let downloadQ = "Jiny Download Queue"
        static let dataQ = "Jiny Data Queue"
        static let downloadsFolder = "Jiny"
        static let analyticsEndPoint = "https://dev.jiny.io/api/jiny/v2/sendAnalytics"
    }
}
