//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Lupti on 4/8/16.
//  Copyright © 2016 lupti. All rights reserved.
//

import CoreData
import MapKit

class Pin: NSManagedObject, MKAnnotation{
    
    struct Keys {
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let pictures = "pictures"
    }
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: [Photo]
    
    // Core Location Data Type
    var myCoordinate: CLLocationCoordinate2D? = nil
    
    var coordinate: CLLocationCoordinate2D {
        return myCoordinate!
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        myCoordinate = CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    // Custom init for Pin object
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        // Reference to Pin Entity of the core data model
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        // Set Dictionary
        latitude = dictionary[Keys.latitude] as! Double
        longitude = dictionary[Keys.longitude] as! Double
        
        myCoordinate = CLLocationCoordinate2DMake(latitude, longitude)
    }
    
}