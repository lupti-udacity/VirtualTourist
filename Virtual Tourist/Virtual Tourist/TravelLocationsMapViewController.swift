//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Lupti on 5/5/16.
//  Copyright © 2016 lupti. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tapPinsLabel: UILabel!
    
    // Set archived file path component for saved map region
    struct Keys {
        static let ArchivedMapRegion = "archived_map_region"
    }
    
    var editModeState: Bool = false  // default to false at the start of the view
    
    var droppedPin: Pin!             // Log press tap pin location
    
    
    // MARK: - Bind with Core Data
    
    // set Core Data sharedContext for this controller
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    var filePath: String {
        let fileManager = NSFileManager.defaultManager()
        let url = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent(Keys.ArchivedMapRegion).path!
    }
    
    lazy var fetchedResutsController: NSFetchedResultsController = {
       
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
        
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: #selector(TravelLocationsMapViewController.editAction))
        
        // Restore the map's previously stored state from the defined filePath.
        restoreMapRegion(filePath, animated: false)
        
        // Instantiate a long press gesture reognizer instance
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationsMapViewController.longTap(_:)))
        
        // Add this longPressGestureRecognizer to this mapView
        mapView.addGestureRecognizer(longPressGestureRecognizer)
        
        // Set mapView delegate to this controller
        self.mapView.delegate = self
        
        // Add NSFetchedResultsController delegate
        do {
            try fetchedResutsController.performFetch()
        } catch _ {}
        
        fetchedResutsController.delegate = self
        
        // Add annotations from Core Data
        createAnnotations()
    }

    
    func editAction() {
        // Set the navigation bar button to either Edit or Done depending on its edit state.
        // Expand or collapse the bottom Tap Pin Label frame
        // Finally negate the current edit state after the settings had been done.
        if (editModeState) {
            
            self.navigationItem.rightBarButtonItem?.title = "Edit"
            UIView.animateWithDuration(0.2, animations: {
                self.mapView.frame.origin.y += self.tapPinsLabel.frame.height
            })
        } else {
            self.navigationItem.rightBarButtonItem?.title = "Done"
            UIView.animateWithDuration(0.2, animations: {
                self.mapView.frame.origin.y -= self.tapPinsLabel.frame.height
            })
        }
        self.editModeState = !self.editModeState
    }
    
    func restoreMapRegion(filePath: String, animated: Bool) {
        
        // To restore the map state to its previous region using previously archived map file
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latiude = regionDictionary["latiude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latiude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(savedRegion, animated: animated)
        }
        
    }
    
    // MARK: - Long Tap function
    func longTap(gestureRecognizer: UIGestureRecognizer) {
        
        // if edit state is false, can tap to drop pin
        if !self.editModeState {
            // Set the coordinates of the drop point on the map
            let touchPoint = gestureRecognizer.locationInView(self.mapView)
            let newlySetCoordinate: CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
            
            switch gestureRecognizer.state {
            case .Began:
                // Create a pin
                var locationDictionary = [String : AnyObject]()
                // Add current pin coordinate to the locationDictionary.
                locationDictionary[Pin.Keys.latitude] = newlySetCoordinate.latitude
                locationDictionary[Pin.Keys.longitude] = newlySetCoordinate.longitude
                // Instantiate droppedPin Pin object
                droppedPin = Pin(dictionary: locationDictionary, context: sharedContext)
                
                // Add pin to the map using the closure addAnnotation
                dispatch_async(dispatch_get_main_queue(), {
                    self.mapView.addAnnotation(self.droppedPin)
                    })
                
            case .Changed:
                // Part of Key-Value Observing Programming (KVO) 
                // Inform the receiver that the value of a givenproperty is about to change.
                // CoreData NSManagedObject Class
                // Use Pin's declared variable coordinate in Pin class.
                droppedPin.willChangeValueForKey("coordinate")
                droppedPin.myCoordinate = newlySetCoordinate
                droppedPin.didChangeValueForKey("coordinate")
                
            case .Ended:
                // Fetch the location images by calling 
                FlickrDB.sharedInstance().taskForSearchFlickrPhotos(self.droppedPin){(result, error) in
                    guard error == nil else {
                        // Error, e.g. the pin has no images or the internet connection is offline
                        print("Error: \(error?.localizedDescription)")
                        self.showAlert(error?.localizedDescription)
                        return
                    }
                    
                    // Positive return with data from Flickr Search Photos
                    // Parse the array of photos dictionaries
                    dispatch_async(dispatch_get_main_queue()) {
                        _ = result?.map() {(dictionary: [String : AnyObject]) -> Photo in
                            let photo = Photo(dictionary: dictionary, pin: self.droppedPin, context: self.sharedContext)
                            // Given the photo.iageUrl, grab the Flickr photo image for storing in the user's CoreData DB.
                            FlickrDB.sharedInstance().taskForUpdatePhotoImageFileName(photo) { success, error in
                                guard error == nil else {
                                    print("Error: \(error?.localizedDescription)")
                                    return
                                }
                                dispatch_async(dispatch_get_main_queue()) {
                                    // Save the content to Core Data Photo database.
                                    CoreDataStackManager.sharedInstance().saveContext()
                                }
                            }
                            return photo
                        }
                    }
                }
            default:
                return
            }
        }
    }
    

    
    // Populate the fetched pin results from the sharedContext to the annotations array of Pin
    func createAnnotations() {
        var annotations = [Pin]()
        
        if let locations = fetchedResutsController.fetchedObjects {
            for location in locations {
                annotations.append(location as! Pin)
            }
        }
        self.mapView.addAnnotations(annotations)

    }
    
        // A generic Alert prompt.
    func showAlert(errorMessage: String?) {
        let alertController = UIAlertController(title: nil, message: errorMessage!, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Dismiss", style: .Cancel) { action -> Void in
            // No additional action.
        }
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true) { () -> Void in
            // no action
        }
    }
        
}
