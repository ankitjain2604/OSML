

import Foundation
class UploadChunkOperation: OSMLOperation {
    
    var chunk: Data?
    var chunkId: NSNumber
    var fileId: NSNumber
    var isCompleted: String
    var claimId: NSNumber
    var recordId: NSNumber
    var userId: String
    var filename: String
    var fileType:String
    var totalChunkCount: String
    var responseData: Data?
    
    init(withMedia dataChunk: Data?, chunkId:NSNumber, fileId:NSNumber, isCompleted:String, claimId: NSNumber, recordId:NSNumber, userId:String, filename:String, fileType:String, totalChunkCount:String) {
        
        self.chunk = dataChunk
        self.chunkId = chunkId
        self.fileId = fileId
        self.isCompleted = isCompleted
        self.claimId = claimId
        self.recordId = recordId
        self.userId = userId
        self.filename = filename
        self.fileType = fileType
        self.totalChunkCount = totalChunkCount
    }
    
    override func main() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        executing(true)
        uploadMediaChunk()
    }
    
    
    func uploadMediaChunk() {
        
        let parameters = ["resourceName":self.filename, "fileType": self.fileType]
        guard let url = URL(string: Constants.kchunkUploadURL) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120000
        let boundary = generateBoundary()
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        request.addValue(self.filename, forHTTPHeaderField:"FileName")
        request.addValue(self.userId, forHTTPHeaderField:"UserId")
        request.addValue(String(describing:self.recordId), forHTTPHeaderField:"RecordId")
        request.addValue(String(describing:self.claimId), forHTTPHeaderField: "ClaimId")
        request.addValue(String(describing:self.fileId), forHTTPHeaderField: "FileId")
        request.addValue(String(describing:self.chunkId), forHTTPHeaderField:"ChunkId")
        request.addValue(self.isCompleted, forHTTPHeaderField:"IsCompleted")
        request.addValue(self.totalChunkCount, forHTTPHeaderField: "TotalChunkCount")
        
        let dataBody = createDataBody(withParameters: parameters, media: self.chunk, boundary: boundary)
        request.httpBody = dataBody
        let session = URLSession(configuration: .default)
        print("request:---------------", request)
        session.dataTask(with: request) {(data, resopnse, error) in
            if error == nil {
                print("Error is Not nil")
                if data != nil {
                    self.responseData = data
                }
                else {
                    print("Data")
                    self.responseData = nil
                }
            }
            else {
                print("Error:", error as Any)
                self.responseData = nil
            }
            self.executing(false)
            self.finish(true)
            
        }.resume()
    }
    
    func createDataBody(withParameters params: Parameters?, media: Data?, boundary: String) -> Data {
        let lineBreak = "\r\n"
        var body = Data()
        body.append("--\(boundary + lineBreak)")
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\(self.filename)\(lineBreak)")
        body.append("Content-Type:image/jpeg\(lineBreak + lineBreak)")
        if let chunkData = media {
            body.append(chunkData)
            body.append(lineBreak)
            body.append("--\(boundary)--\(lineBreak)")
        }
        else {
            body.append("")
            body.append(lineBreak)
            body.append("--\(boundary)--\(lineBreak)")
        }
        return body
    }
    
    func generateBoundary() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
}
