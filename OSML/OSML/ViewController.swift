

import UIKit

class ViewController: UIViewController,OSMLDelegate {

    override func viewDidLoad() {
        prepareAndStartUpload()
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func prepareAndStartUpload() {
        let mediaResource :[Dictionary<String,String>] = [["filePath":"img1.jpg","fileType":"image"],["filePath":"img2.jpg","fileType":"image"],["filePath":"img3.jpg","fileType":"image"]]
        let resources:NSDictionary = ["ClaimId":60101, "UserId":"abc@gmail.com", "RecordId":70101,"MediaResource":mediaResource]
        
        let resuploader = ResourceUploader()
        resuploader.delegate = self
        resuploader.prepareAndStartUpload(resources: resources)
    }
    
    //Delegate methods
    
    func uploadCompletedForRecord(claimId: NSNumber, recordId: NSNumber) {
        //perform any action after completed upload for a claim record
        print("Notified about completion of resources corresponding to a record", claimId, recordId)
    }
    func uploadCompletedForResource(claimId: NSNumber, recordId: NSNumber, resourceUrl: String) {
        print("Notified about completion of a resource", claimId, recordId, resourceUrl)
    }
    
    func assessmentCompletedForRecord(claimId: NSNumber, recordId: NSNumber) {
        print("Notified about completion of assessment", claimId, recordId)
    }
}
