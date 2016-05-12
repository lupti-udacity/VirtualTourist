//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Lupti on 4/8/16.
//  Copyright © 2016 lupti. All rights reserved.
//

import CoreData
import UIKit

class Photo: NSManagedObject{
    // Define Keys for its dictionary convenience
    struct Keys {
        static let imageUrl = "url_m"  // Request Flickr image url parameter 
    }
    
    @NSManaged var imageFilename: String? // Local Core Data Image File Path and File Name
    @NSManaged var imageUrl: String       // Flickr HTTPS full path URL to the image file.
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // Define custom init for Photo instantiation, pass in Pin object
    init(dictionary: [String : AnyObject], pin: Pin, context: NSManagedObjectContext) {
        // Core Data in Photo data model
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        // Dictionary: only one item imageUrl.
        self.imageUrl = dictionary[Keys.imageUrl] as! String
        self.pin = pin
        
    }

    // Boilerplat of getting image. Import UIKit for UIImage
    var image: UIImage? {
        if let imageFilename = imageFilename {
            let filePathURL = NSURL.fileURLWithPath(imageFilename)
            let lastPathComponent = filePathURL.lastPathComponent!
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
            let pathArray = [dirPath, lastPathComponent]
            let fileUrl = NSURL.fileURLWithPathComponents(pathArray)!
            return UIImage(contentsOfFile: fileUrl.path!)
        }
        return nil
    }

    // Delete the associated image file when the photo managed object is deleted on the PhotoAlbumViewController
    // Invoke by CoreData framework NSManagedObject when receiver is about to be deleted.
    override func prepareForDeletion() {
        if let imageFilePath = imageFilename, fileName = NSURL.fileURLWithPath(imageFilePath).lastPathComponent {
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
            let pathArray = [dirPath, fileName]
            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
            
            do {
                try NSFileManager.defaultManager().removeItemAtURL(fileURL)
            } catch _ {
            }
        }
        
    }
}
