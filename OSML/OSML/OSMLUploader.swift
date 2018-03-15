

import Foundation
import UIKit

class ResourceUploader: OSMLNetworkDelegate {
    
    weak var delegate: OSMLDelegate?
    
    func prepareAndStartUpload(resources: NSDictionary) {
        let dataController: CoreDataController = CoreDataController.shared
        let mediaResources:[NSDictionary] = resources.value(forKey: "MediaResource") as! [NSDictionary]
        //fetch resource corresponding to the claimid and recordid
        let resourcesMO = dataController.fetchResourcesForARecord(claimId: resources.value(forKey: "ClaimId") as! NSNumber, recordId: resources.value(forKey: "RecordId") as! NSNumber)
        if resourcesMO.count == 0 {         //no records exist
            for resource in mediaResources {
                dataController.saveResource(path: resource.value(forKey: "filePath") as! String, status: UploadStatus.Started.rawValue, claimId: resources.value(forKey: "ClaimId") as! NSNumber, recordId: resources.value(forKey: "RecordId") as! NSNumber, type: resource.value(forKey: "fileType") as! String, userId: resources.value(forKey: "UserId") as! String, url: "")
            }
            //Starting upload on background thread
            DispatchQueue.global(qos: .background).async {
                let osmlNetwork = OSMLNetworkUtility()
                osmlNetwork?.delegate = self
                osmlNetwork?.uploadResources()
            }
            
        }
        else {
            //resources already exist for this record
        }
    }
    
    
    func uploadCompletedForRecord(claimId: NSNumber, recordId: NSNumber) {
        self.delegate?.uploadCompletedForRecord(claimId: claimId, recordId: recordId)
    }
    func uploadCompletedForResource(claimId: NSNumber, recordId: NSNumber, resourceId: NSNumber) {
        let dataController: CoreDataController = CoreDataController.shared
//        let resourceObj:ResourceMO = dataController.fetchResourceDetail(resourceId: resourceId)
        let x = dataController.fetchResourceUploadStatus(resourceId: resourceId)
//        self.delegate?.uploadCompletedForResource(claimId: claimId, recordId: recordId, resourceUrl: resourceObj.url!)
        self.delegate?.uploadCompletedForResource(claimId: claimId, recordId: recordId, resourceUrl: x)
    }
    func assessmentCompletedForRecord(claimId: NSNumber, recordId: NSNumber) {
        self.delegate?.assessmentCompletedForRecord(claimId: claimId, recordId: recordId)
    }
    
}
