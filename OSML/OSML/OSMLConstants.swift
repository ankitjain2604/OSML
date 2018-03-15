

typealias Parameters  = [String: String]

enum UploadStatus: String {
    case Started = "started"
    case InProgress = "in progress"
    case Completed = "completed"
}

struct Constants {
    static let kChunkSize = 204800
    static let kchunkUploadURL = "https://abc.com/upload" //dummy url
    
}

