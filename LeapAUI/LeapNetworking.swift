//
//  LeapNetworking.swift
//  LeapAUI
//
//  Created by Aravind GS on 17/03/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import Foundation

// MARK: - LEAP OPERATIONS CLASS

class LeapOperation:Operation {
    
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

// MARK: - LEAP DOWNLOAD OPERATION CLASS - SUBCLASS OF LEAP OPERATION

class LeapDownloadOperation: LeapOperation {
    
    let media:LeapMedia
    
    init(_ file: LeapMedia, _ success: @escaping ((Bool, Bool, Bool, URL?) -> Void)) {
        media = file
        let request = URLRequest(url: media.url!)
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
        let filePath = LeapSharedAUI.shared.getFilePath(media: media)
        guard !fm.fileExists(atPath: filePath.path) else {
            self.executing(false)
            self.finished(true)
            self.statusUpdate(false,true,true,filePath)
            return
        }
        guard let url = media.url else { return }
        let request = URLRequest(url: url)
        let dlTask = session.downloadTask(with: request) { (fileUrl, urlResponse, error) in
            self.executing(false)
            self.finished(true)
            guard let tempLocation = fileUrl else {
                self.statusUpdate(false, true, false, nil)
                return
            }
            self.copyFileToLeapFolder(tempLocation)
            self.statusUpdate(false, true, true, filePath)
            guard filePath.pathExtension == "gz",
                  let gzipData = try? Data(contentsOf: filePath),
                  let unzippedData = try? gzipData.gunzipped() else {
                print("[Leap]File downloaded = \(filePath.path)")
                return
            }
            let newFilePath = filePath.deletingPathExtension().appendingPathExtension("html")
            try! unzippedData.write(to: newFilePath, options: .atomic)
            print("[Leap]File download = \(newFilePath.path)")
        }
        dlTask.resume()
    }
    
    func copyFileToLeapFolder(_ inputLocation: URL) {
        guard let folderPath = LeapSharedAUI.shared.getFolderPath(media: media) else { return }
        if !LeapSharedAUI.shared.checkIfFolderExists(folder: folderPath) {
            do { try fm.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: [:]) }
            catch let folderCreationError { fatalError("Failed to create Leap folder becaues \(folderCreationError.localizedDescription)") }
        }
        let filePath = LeapSharedAUI.shared.getFilePath(media: media)
        if fm.fileExists(atPath: filePath.path) { return }
        do { try fm.copyItem(atPath: inputLocation.path, toPath: filePath.path) }
        catch let fileCopyError { fatalError("Failed to copy file because \(fileCopyError.localizedDescription)") }
    }
    
}


// MARK: - LEAP NETWORKER CLASS - HANDLES OPERATIONS QUEUE
class LeapNetWorker {
    
    static var shared = LeapNetWorker()
    lazy var downloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = Constants.Networking.downloadQ
        queue.maxConcurrentOperationCount = 4
        return queue
        
    }()
}

// MARK: - NETWORKING CLASS CONSTANTS

struct Constants {
    struct Networking {
        static let isExecuting = "isExecuting"
        static let isFinished = "isFinished"
        static let downloadQ = "Leap Download Queue"
        static let downloadsFolder = "Leap"
    }
}
