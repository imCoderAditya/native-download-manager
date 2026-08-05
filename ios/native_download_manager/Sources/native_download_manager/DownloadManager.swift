import Foundation
import Flutter

class DownloadManager: NSObject, URLSessionDownloadDelegate {
    
    static let shared = DownloadManager()
    
    private var session: URLSession!
    private var tasks: [String: PigeonDownloadTask] = [:]
    private var requests: [String: PigeonDownloadRequest] = [:]
    private var resumeDataMap: [String: Data] = [:]
    private var speedTrackers: [String: SpeedTracker] = [:]
    
    var flutterApi: NativeDownloadManagerFlutterApi?
    
    private override init() {
        super.init()
        loadTasks()
        
        let config = URLSessionConfiguration.background(withIdentifier: "com.native_download_manager.background")
        config.sharedContainerIdentifier = nil // Set up if App Group is needed
        config.sessionSendsLaunchEvents = true
        
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        
        // Reconnect active tasks from background URLSession
        reconnectTasks()
    }
    
    private func getPersistenceUrl() -> URL? {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        if !fileManager.fileExists(atPath: appSupport.path) {
            try? fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true, attributes: nil)
        }
        return appSupport.appendingPathComponent("native_download_tasks.json")
    }
    
    private func loadTasks() {
        guard let url = getPersistenceUrl(),
              let data = try? Data(contentsOf: url) else {
            return
        }
        
        let decoder = JSONDecoder()
        if let dict = try? decoder.decode([String: CodableTask].self, from: data) {
            for (id, codableTask) in dict {
                self.tasks[id] = codableTask.toPigeonTask()
                self.requests[id] = codableTask.toPigeonRequest()
                if let resumeHex = codableTask.resumeDataHex,
                   let resumeData = Data(hexString: resumeHex) {
                    self.resumeDataMap[id] = resumeData
                }
            }
        }
    }
    
    private func saveTasks() {
        guard let url = getPersistenceUrl() else { return }
        
        var codableDict: [String: CodableTask] = [:]
        for (id, task) in tasks {
            let req = requests[id]
            let resumeHex = resumeDataMap[id]?.hexEncodedString()
            codableDict[id] = CodableTask(task: task, request: req, resumeDataHex: resumeHex)
        }
        
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(codableDict) {
            try? data.write(to: url)
        }
    }
    
    private func reconnectTasks() {
        session.getTasksWithCompletionHandler { [weak self] (_, _, downloadTasks) in
            guard let self = self else { return }
            for downloadTask in downloadTasks {
                if let taskId = downloadTask.taskDescription {
                    // Update task status if it was suspended or completed
                    if downloadTask.state == .running {
                        self.updateTaskStatus(taskId: taskId, status: 1) // downloading
                    }
                }
            }
        }
    }
    
    func startDownload(request: PigeonDownloadRequest) {
        let taskId = request.id
        self.requests[taskId] = request
        
        let task = PigeonDownloadTask(
            id: taskId,
            url: request.url,
            fileName: request.fileName,
            filePath: nil,
            status: 0, // enqueued
            progress: 0.0,
            downloadedBytes: 0,
            totalBytes: 0,
            speed: 0.0,
            etaSeconds: -1,
            error: nil
        )
        
        self.tasks[taskId] = task
        self.saveTasks()
        
        self.flutterApi?.onTaskStatusChanged(task: task) { _ in }
        
        // Execute download
        executeDownload(taskId: taskId)
    }
    
    private func executeDownload(taskId: String) {
        guard let request = requests[taskId],
              let url = URL(string: request.url) else {
            updateTaskStatus(taskId: taskId, status: 4, error: "Invalid URL")
            return
        }
        
        // Check networking and constraints if needed
        // Note: URLSession background configuration handles cellular and system level waiting automatically, 
        // but we can also set allowsCellularAccess and waitsForConnectivity.
        
        let downloadTask: URLSessionDownloadTask
        if let resumeData = resumeDataMap[taskId] {
            downloadTask = session.downloadTask(withResumeData: resumeData)
            resumeDataMap.removeValue(forKey: taskId)
        } else {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "GET"
            
            // Set Headers
            request.headers.forEach { (key, value) in
                if let key = key, let value = value {
                    urlRequest.setValue(value, forHTTPHeaderField: key)
                }
            }
            
            if request.wifiOnly {
                urlRequest.allowsCellularAccess = false
            }
            
            downloadTask = session.downloadTask(with: urlRequest)
        }
        
        downloadTask.taskDescription = taskId        
        // In iOS 13+, background tasks can wait for connectivity instead of failing instantly
        downloadTask.countOfBytesClientExpectsToSend = 100
        downloadTask.countOfBytesClientExpectsToReceive = 1024 * 1024 * 50 // estimate 50MB
        
        speedTrackers[taskId] = SpeedTracker()
        
        downloadTask.resume()
        updateTaskStatus(taskId: taskId, status: 1) // downloading
    }
    
    func pauseDownload(taskId: String) {
        session.getTasksWithCompletionHandler { [weak self] (_, _, downloadTasks) in
            guard let self = self else { return }
            if let downloadTask = downloadTasks.first(where: { $0.taskDescription == taskId }) {
                downloadTask.cancel(byProducingResumeData: { [weak self] (resumeData) in
                    guard let self = self else { return }
                    if let resumeData = resumeData {
                        self.resumeDataMap[taskId] = resumeData
                    }
                    self.updateTaskStatus(taskId: taskId, status: 2) // paused
                })
            } else {
                self.updateTaskStatus(taskId: taskId, status: 2) // paused
            }
        }
    }
    
    func resumeDownload(taskId: String) {
        let task = tasks[taskId]
        if task?.status == 2 || task?.status == 4 || task?.status == 5 { // paused, failed, canceled
            executeDownload(taskId: taskId)
        }
    }
    
    func cancelDownload(taskId: String) {
        session.getTasksWithCompletionHandler { [weak self] (_, _, downloadTasks) in
            guard let self = self else { return }
            if let downloadTask = downloadTasks.first(where: { $0.taskDescription == taskId }) {
                downloadTask.cancel()
            }
            self.resumeDataMap.removeValue(forKey: taskId)
            self.updateTaskStatus(taskId: taskId, status: 5) // canceled
        }
    }
    
    func retryDownload(taskId: String) {
        self.resumeDataMap.removeValue(forKey: taskId)
        executeDownload(taskId: taskId)
    }
    
    func deleteDownload(taskId: String, deleteFile: Bool) {
        cancelDownload(taskId: taskId)
        if let task = tasks[taskId] {
            if deleteFile, let filePath = task.filePath {
                let fileUrl = URL(fileURLWithPath: filePath)
                try? FileManager.default.removeItem(at: fileUrl)
            }
            tasks.removeValue(forKey: taskId)
            requests.removeValue(forKey: taskId)
            saveTasks()
        }
    }
    
    func getAllTasks() -> [PigeonDownloadTask] {
        return Array(tasks.values)
    }
    
    func getTask(taskId: String) -> PigeonDownloadTask? {
        return tasks[taskId]
    }
    
    func clearHistory() {
        tasks.removeAll()
        requests.removeAll()
        resumeDataMap.removeAll()
        saveTasks()
    }
    
    private func updateTaskStatus(taskId: String, status: Int64, filePath: String? = nil, error: String? = nil) {
        guard let task = tasks[taskId] else { return }
        
        let isCompleted = status == 3
        let totalBytes = (isCompleted && task.totalBytes <= 0) ? task.downloadedBytes : task.totalBytes
        let downloadedBytes = isCompleted ? totalBytes : task.downloadedBytes
        let progress = isCompleted ? 1.0 : task.progress

        let updatedTask = PigeonDownloadTask(
            id: taskId,
            url: task.url,
            fileName: task.fileName,
            filePath: filePath ?? task.filePath,
            status: status,
            progress: progress,
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes,
            speed: 0.0,
            etaSeconds: -1,
            error: error
        )
        
        self.tasks[taskId] = updatedTask
        self.saveTasks()
        
        DispatchQueue.main.async {
            self.flutterApi?.onTaskStatusChanged(task: updatedTask) { _ in }
        }
    }
    
    // URLSessionDownloadDelegate implementation
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let taskId = downloadTask.taskDescription,
              let task = tasks[taskId] else { return }
        
        let tracker = speedTrackers[taskId] ?? SpeedTracker()
        speedTrackers[taskId] = tracker
        tracker.update(bytesWritten: bytesWritten)
        
        let progress = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0.0
        
        // Update database task fields
        let updatedTask = PigeonDownloadTask(
            id: taskId,
            url: task.url,
            fileName: task.fileName,
            filePath: task.filePath,
            status: 1, // downloading
            progress: progress,
            downloadedBytes: totalBytesWritten,
            totalBytes: totalBytesExpectedToWrite,
            speed: tracker.speed,
            etaSeconds: Int64(tracker.getEta(totalBytesRemaining: totalBytesExpectedToWrite - totalBytesWritten)),
            error: nil
        )
        
        self.tasks[taskId] = updatedTask
        
        DispatchQueue.main.async {
            self.flutterApi?.onTaskProgressUpdated(
                taskId: taskId,
                downloadedBytes: totalBytesWritten,
                totalBytes: totalBytesExpectedToWrite,
                speed: tracker.speed,
                etaSeconds: Int64(tracker.getEta(totalBytesRemaining: totalBytesExpectedToWrite - totalBytesWritten))
            ) { _ in }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let taskId = downloadTask.taskDescription,
              let request = requests[taskId] else { return }
        
        let fileManager = FileManager.default
        let documentUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        var destinationUrl = documentUrl.appendingPathComponent(request.fileName)
        
        // Handle Overwrite Policy
        if fileManager.fileExists(atPath: destinationUrl.path) && !request.overwrite {
            self.updateTaskStatus(taskId: taskId, status: 4, error: "FileAlreadyExistsException: File already exists at destination path \(destinationUrl.path)")
            return
        } else if fileManager.fileExists(atPath: destinationUrl.path) && request.overwrite {
            try? fileManager.removeItem(at: destinationUrl)
        }
        
        // Validate Checksum if required
        if let expectedChecksum = request.checksum, let algo = request.checksumAlgorithm {
            self.updateTaskStatus(taskId: taskId, status: 1, filePath: nil, error: "Verifying checksum...")
            let verified = verifyChecksum(fileUrl: location, expected: expectedChecksum, algorithm: algo)
            if !verified {
                self.updateTaskStatus(taskId: taskId, status: 4, error: "File integrity verification failed. Checksum mismatch.")
                return
            }
        }
        
        do {
            try fileManager.moveItem(at: location, to: destinationUrl)
            let finalSize = (try? fileManager.attributesOfItem(atPath: destinationUrl.path)[.size] as? Int64) ?? 0
            DispatchQueue.main.async {
                self.flutterApi?.onTaskProgressUpdated(
                    taskId: taskId,
                    downloadedBytes: finalSize,
                    totalBytes: finalSize,
                    speed: 0.0,
                    etaSeconds: 0
                ) { _ in }
            }
            self.updateTaskStatus(taskId: taskId, status: 3, filePath: destinationUrl.path) // completed
        } catch {
            self.updateTaskStatus(taskId: taskId, status: 4, error: "Failed to move file to destination: \(error.localizedDescription)")
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let taskId = task.taskDescription else { return }
        
        if let error = error {
            let nsError = error as NSError
            if nsError.code == NSURLErrorCancelled {
                // If cancelled by producing resume data, it is handled in pauseDownload()
                if let resumeData = nsError.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                    self.resumeDataMap[taskId] = resumeData
                    self.updateTaskStatus(taskId: taskId, status: 2) // paused
                } else {
                    self.updateTaskStatus(taskId: taskId, status: 5) // canceled
                }
            } else {
                self.updateTaskStatus(taskId: taskId, status: 4, error: error.localizedDescription) // failed
            }
        }
    }
    
    private func verifyChecksum(fileUrl: URL, expected: String, algorithm: String) -> Bool {
        // Implement Swift checksum validation (MD5 / SHA-256)
        guard let fileData = try? Data(contentsOf: fileUrl, options: .mappedIfSafe) else {
            return false
        }
        let actualHash: String
        if algorithm.lowercased() == "md5" {
            actualHash = fileData.md5String()
        } else if algorithm.lowercased() == "sha256" {
            actualHash = fileData.sha256String()
        } else {
            return false
        }
        return actualHash.lowercased() == expected.lowercased()
    }
}

// Helper models and extensions
class SpeedTracker {
    private var lastBytesWritten: Int64 = 0
    private var lastUpdateTime: Date = Date()
    private var rollingSpeed: Double = 0.0
    
    var speed: Double {
        return rollingSpeed
    }
    
    func update(bytesWritten: Int64) {
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastUpdateTime)
        
        if timeInterval >= 0.5 {
            let currentSpeed = Double(bytesWritten) / timeInterval
            rollingSpeed = rollingSpeed == 0 ? currentSpeed : (rollingSpeed * 0.7 + currentSpeed * 0.3)
            lastUpdateTime = now
        }
    }
    
    func getEta(totalBytesRemaining: Int64) -> Int {
        guard rollingSpeed > 0 else { return -1 }
        return Int(Double(totalBytesRemaining) / rollingSpeed)
    }
}

struct CodableTask: Codable {
    let id: String
    let url: String
    let fileName: String
    let filePath: String?
    let status: Int64
    let progress: Double
    let downloadedBytes: Int64
    let totalBytes: Int64
    let error: String?
    
    // Request metadata
    let headers: [String: String]
    let wifiOnly: Bool
    let chargingOnly: Bool
    let requiresBatteryNotLow: Bool
    let priority: Int64
    let checksum: String?
    let checksumAlgorithm: String?
    let overwrite: Bool
    
    let resumeDataHex: String?
    
    init(task: PigeonDownloadTask, request: PigeonDownloadRequest?, resumeDataHex: String?) {
        self.id = task.id
        self.url = task.url
        self.fileName = task.fileName
        self.filePath = task.filePath
        self.status = task.status
        self.progress = task.progress
        self.downloadedBytes = task.downloadedBytes
        self.totalBytes = task.totalBytes
        self.error = task.error
        
        self.headers = (request?.headers as? [String: String]) ?? [:]
        self.wifiOnly = request?.wifiOnly ?? false
        self.chargingOnly = request?.chargingOnly ?? false
        self.requiresBatteryNotLow = request?.requiresBatteryNotLow ?? false
        self.priority = request?.priority ?? 1
        self.checksum = request?.checksum
        self.checksumAlgorithm = request?.checksumAlgorithm
        self.overwrite = request?.overwrite ?? true
        
        self.resumeDataHex = resumeDataHex
    }
    
    func toPigeonTask() -> PigeonDownloadTask {
        return PigeonDownloadTask(
            id: id,
            url: url,
            fileName: fileName,
            filePath: filePath,
            status: status,
            progress: progress,
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes,
            speed: 0.0,
            etaSeconds: -1,
            error: error
        )
    }
    
    func toPigeonRequest() -> PigeonDownloadRequest {
        return PigeonDownloadRequest(
            id: id,
            url: url,
            fileName: fileName,
            destinationDirectory: filePath,
            headers: headers.reduce(into: [String?: String?]()) { $0[$1.key] = $1.value },
            wifiOnly: wifiOnly,
            chargingOnly: chargingOnly,
            requiresBatteryNotLow: requiresBatteryNotLow,
            priority: priority,
            checksum: checksum,
            checksumAlgorithm: checksumAlgorithm,
            overwrite: overwrite
        )
    }
}

// Hex extensions
extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var i = hexString.startIndex
        for _ in 0..<len {
            let nextIndex = hexString.index(i, offsetBy: 2)
            if let b = UInt8(hexString[i..<nextIndex], radix: 16) {
                data.append(b)
            } else {
                return nil
            }
            i = nextIndex
        }
        self = data
    }
    
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

// Crypto extensions
import CommonCrypto
extension Data {
    func md5String() -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_MD5($0.baseAddress, CC_LONG(self.count), &digest)
        }
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    func sha256String() -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &digest)
        }
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}

// Conform FlutterError to Swift Error to enable Pigeon's Result implementation
extension FlutterError: Error {}
