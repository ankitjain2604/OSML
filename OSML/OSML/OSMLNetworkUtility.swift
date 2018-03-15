

import Foundation
import UIKit

class OSMLNetworkUtility {
    private let operationQueue: OperationQueue = OperationQueue()
    private let secondOperationQueue: OperationQueue = OperationQueue()
    let dataController:CoreDataController
    var mediaResources:[ResourceMO]
    weak var delegate: OSMLNetworkDelegate?
    
    init?() {
        dataController = CoreDataController.shared
        mediaResources = dataController.fetchResourcesToBeUploaded()
    }
    
    func uploadResources() -> Void {
        
        let reachability = Reachability()
        var networkFlag = false
        if reachability?.connection == .wifi {
            networkFlag = true
            
        } else if reachability?.connection == .cellular {
            networkFlag = true
        } else {
            networkFlag = false
        }
        
        if networkFlag {
            var operationList = [UploadChunkOperation]()
            
            
            for resource in mediaResources {
                guard let path = Bundle.main.url(forResource: resource.path, withExtension: nil) else { return }        //path to be changed
                let chunks = splitDatainChunks(path)    //split resource data into chunks
                var chunksTobeUploaded:[ChunkMO] = dataController.fetchChunksToBeUploaded(resourceId: resource.resourceId!)//fetch in background thread
                if chunksTobeUploaded.count == 0 {  //check whether chunks has been created earlier
                    for chunkIndex in (0..<chunks.count) {
                        dataController.saveChunk(resourceId:resource.resourceId!, status: UploadStatus.Started.rawValue, chunkId: NSNumber(value: chunkIndex)) //save in backgroud thread
                    }
                    chunksTobeUploaded = dataController.fetchChunksToBeUploaded(resourceId: resource.resourceId!)//fetch in background thread
                }
                for chunk in chunksTobeUploaded
                {
                    let uploadOperation = UploadChunkOperation(withMedia: chunks[(chunk.chunkId?.intValue)!], chunkId: chunk.chunkId!, fileId: resource.resourceId!, isCompleted: "false", claimId: resource.claimId!, recordId: resource.recordId!, userId: resource.userId!, filename: resource.path!, fileType:resource.type!, totalChunkCount:String(chunks.count))
                    uploadOperation.completionBlock = {

                        print("Operation Completed...............")
                        if uploadOperation.responseData != nil {
                            do {
                                let json:NSDictionary = try JSONSerialization.jsonObject(with: uploadOperation.responseData!, options: []) as! NSDictionary
                                print("DATA::",json)
                                self.dataController.updateChunkUploadStatus(chunkId: NSNumber(value: Int(json["ChunkId"] as! String)!), resourceId: NSNumber(value: Int(json["FileId"] as! String)!), status: UploadStatus.Completed.rawValue)//update in operation's thread
                                let chunks:[ChunkMO] = self.dataController.fetchChunksToBeUploaded(resourceId: NSNumber(value: Int(json["FileId"] as! String)!)) //fetch in operation's thread
                                
                                let blobURI = json["BlobUri"] as? String
                                if blobURI != nil {
                                    self.dataController.updateResourceURL(resourceId: NSNumber(value: Int(json["FileId"] as! String)!), url: blobURI!)
                                }
                                if chunks.count == 0 {
                                    print("Completed Resource Upload")
                                    self.dataController.deleteChunks(resourceId: NSNumber(value: Int(json["FileId"] as! String)!))//delete in operation's thread
                                    self.dataController.updateResourceUploadStatus(resourceId: NSNumber(value: Int(json["FileId"] as! String)!), status: UploadStatus.Completed.rawValue)
                                    //sending message to uploader class about completion of upload
                                    self.delegate?.uploadCompletedForResource(claimId: NSNumber(value: Int(json["ClaimId"] as! String)!), recordId: NSNumber(value: Int(json["RecordId"] as! String)!), resourceId: NSNumber(value: Int(json["FileId"] as! String)!))
                                    
                                    let remainingResources = self.dataController.fetchRemainingResourcesForARecord(claimId: NSNumber(value: Int(json["ClaimId"] as! String)!), recordId: NSNumber(value: Int(json["RecordId"] as! String)!))
                                    if remainingResources.count == 0 {
                                        //All resources for a record completed upload
                                        self.delegate?.uploadCompletedForRecord(claimId: NSNumber(value: Int(json["ClaimId"] as! String)!), recordId: NSNumber(value: Int(json["RecordId"] as! String)!))
                                    }
                                }
                            } catch {
                                print("Error")
                            }
                        } else {
                            print("Response Error")
                        }
                    }
                    operationList.append(uploadOperation)
                }
            }
            operationQueue.addOperations(operationList, waitUntilFinished: true)
        }
        else {
            print("Network not reachable")
        }
    }
    
    
    func splitDatainChunks(_ resourcePath: URL) -> Array<Data> {
        var chunks:[Data] = [Data]()
        do
        {
            let data = try Data(contentsOf: resourcePath)
            let dataLen = (data as NSData).length
            let fullChunks = Int(dataLen / Constants.kChunkSize)
            let totalChunks = fullChunks + (dataLen % Constants.kChunkSize != 0 ? 1 : 0)
            for chunkCounter in 0..<totalChunks
            {
                var chunk:Data
                let chunkBase = chunkCounter * Constants.kChunkSize
                var diff = Constants.kChunkSize
                if chunkCounter == totalChunks - 1
                {
                    diff = dataLen - chunkBase
                }
                let range:Range<Data.Index> = Range<Data.Index>(chunkBase..<(chunkBase + diff))
                chunk = data.subdata(in: range)
                chunks.append(chunk)
            }
        }
        catch
        {
            print("Error in chunking..........")
        }
        return chunks;
    }
}

extension Data{
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}


