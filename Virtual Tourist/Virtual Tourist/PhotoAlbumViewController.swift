//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Lupti on 5/10/16.
//  Copyright © 2016 lupti. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    @IBOutlet weak var emptyImageLabel: UILabel!
    
    @IBAction func bottomButtonClicked () {
        if selectedIndexes.count == 0 {
            updateBottomButton()
            getNewPhotoCollection()
        } else {
            deleteSelectedPhotos()
            updateBottomButton()
            dispatch_async(dispatch_get_main_queue()) {
                CoreDataStackManager.sharedInstance().saveContext()
            }
            
        }
    }
    
    var selectedPin: Pin!
    var page: Int = 1
    
    // Store selected photo index in an index array.
    var selectedIndexes = [NSIndexPath]()
    // Tracking insert, delect, and updated of Photo indexes
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("PhotoAlbumView ViewDidLoad ans Pin is \(selectedPin)")
        setMapRegion(true)
        
        mapView.addAnnotation(selectedPin)
        mapView.zoomEnabled = false
        mapView.scrollEnabled = false
        mapView.userInteractionEnabled = false
        
        fetchedResultsController.delegate = self
        //var error: NSError?
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
            showAlertView("The current Pin is invalid, Try a new Pin.")
        }
        
        // Enable Bottom Button to Get new photos
        if fetchedResultsController.fetchedObjects?.count == 0 {
            emptyImageLabel.hidden = false
            bottomButton.enabled = true
        }
        
        print("End Photo Album Vide Did Load")
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationItem.leftBarButtonItem?.title = "OK"
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Configure the collection view cell width and no space in between
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        
        let width = floor((collectionView.frame.size.width - 20)/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    // MARK: = Map Related Settings
    func setMapRegion(animated: Bool) {
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        let savedRegion = MKCoordinateRegion(center: selectedPin.coordinate, span: span)
        mapView.setRegion(savedRegion, animated: animated)
    }
    
    // MARK: - Configure Photo Cell
    
    func configureCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
        
        if let _ = selectedIndexes.indexOf(indexPath) {
            cell.imageView.alpha = 0.5
        } else {
            cell.imageView.alpha = 1.0
        }
    }
    
    // MARK: - CoreData Convenience variables. 
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchedRequest = NSFetchRequest(entityName: "Photo")
        fetchedRequest.sortDescriptors = []
        //fetchedRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        // Instantiate a predicate with the NSPredicate. Ticky: The Xcode might not guide you to use this default init function.
        fetchedRequest.predicate = NSPredicate(format: "pin == %@", self.selectedPin)

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchedRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
        
    }()
    
    // MARK: = Implement 4 NSFetchedResultsController delegates. Updating Collection View upon the fetched results.
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // Instantiate the index paths for insert, delete, and update
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            
        case .Delete:
            deletedIndexPaths.append(indexPath!)
        
        case .Update:
            updatedIndexPaths.append(indexPath!)
        
        default:
            break
        }
        
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        // Set the image label and bottom button if the fetched object has positive count.
        if controller.fetchedObjects?.count > 0 {
            emptyImageLabel.hidden = true
            bottomButton.enabled = true
        }
        
        // Update to the collection view in batch.
        collectionView.performBatchUpdates( {() -> Void in
            
        for indexPath in self.insertedIndexPaths {
            self.collectionView.insertItemsAtIndexPaths([indexPath])
        }
        
        for indexPath in self.deletedIndexPaths {
            self.collectionView.deleteItemsAtIndexPaths([indexPath])
        }
        
        for indexPath in self.updatedIndexPaths {
            self.collectionView.reloadItemsAtIndexPaths([indexPath])
        }
        }, completion: nil)
    }
    
    
    // MARK: - Collection View
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        cell.imageView.image = nil
        
        cell.activityView.startAnimating()
        
        // Set up the photo image rendering attributes in the cell
        if photo.image != nil {
            
            cell.activityView.stopAnimating()
            cell.imageView.alpha = 0.0
            cell.imageView.image = photo.image
            
            UIView.animateWithDuration(0.2, animations: {cell.imageView.alpha = 1.0})
            
        }
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
        
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // Use shortcut to return whichever is positive first screening from left to right. 
        // If the fetchedResults count is nil, it will return the right hand side 0.
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        
        // Disallow selection if the cell in CollectionView is still waiting for its image to appear
        if cell.activityView.isAnimating() {
            return false
        } else {
            return true
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        
        // Handle toggle event on the selectedIndex item in this CollectionView
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Reconfigure the cell.
        configureCell(cell, atIndexPath: indexPath)
        
        // Update the bottom button state
        updateBottomButton()
        
    }
    
    
    // MARK: - Helper functions
    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            bottomButton.title = "Remove Selected Pictures"
        } else {
            bottomButton.title = "New Collection"
        }
    }
    
    func getNewPhotoCollection() {
        
        // Turn off the bottom button
        bottomButton.enabled = false
        
        page += 1
        
        // delete exiting photos
        
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            // Delete this photo. Be careful not using the deletedObjects method for a Set of objects.
            sharedContext.deleteObject(photo)
        }
        
        // Save the change in the shared context above.
        dispatch_async(dispatch_get_main_queue()) {
            CoreDataStackManager.sharedInstance().saveContext()
        }
        
        FlickrDB.sharedInstance().taskForSearchFlickrPhotos(selectedPin, pageNumber: page ) { result, error in
            guard error == nil else {
                print("Get New Photo Collection Error: \(error?.localizedDescription)")
                self.showAlertView(error?.localizedDescription)
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                
                // Loop through the result to get the photo imageFileName updated in the Photo Shared Context.
                _ = result?.map() { (dictionary: [String : AnyObject]) -> Photo in
                    
                    let photo = Photo(dictionary: dictionary, pin: self.selectedPin, context: self.sharedContext)
                    
                    FlickrDB.sharedInstance().taskForUpdatePhotoImageFileName(photo) { success, error in
                        guard error == nil else {
                            print("Update Image File Error: \(error?.localizedDescription)")
                            self.bottomButton.enabled = true
                            return
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            CoreDataStackManager.sharedInstance().saveContext()
                            self.bottomButton.enabled = true
                        })
                    }
                    return photo
                }
            }
        }
        // Save the changes on the Photo shared context.
        dispatch_async(dispatch_get_main_queue()) {
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    func showAlertView(error: String?) {
        
        let alertController = UIAlertController(title: nil, message: error!, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil)
        
        alertController.addAction(cancelAction)
        presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    func deleteSelectedPhotos() {
        
        var photosToBeDeleted = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToBeDeleted.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in photosToBeDeleted {
            sharedContext.deleteObject(photo)
        }
        
        // Nullify the selectedIndexes
        selectedIndexes.removeAll()
    
    }
}
