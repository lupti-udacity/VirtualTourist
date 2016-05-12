//
//  FlickrDB.swift
//  Virtual Tourist
//
//  Created by Lupti on 4/12/16.
//  Copyright © 2016 lupti. All rights reserved.
//

/* Reference to TheMovieDB  */
import Foundation

class FlickrDB: NSObject {
    
    typealias CompletionHandler = (result: [[String : AnyObject]]?, error: NSError?) -> Void
    
    // Shared URL session
    var session: NSURLSession
    let photosSearchParameters: [String : AnyObject] = {
        return [
        FlickrDB.Keys.Method: FlickrDB.Constants.Method,
        FlickrDB.Keys.APIKey: FlickrDB.Constants.APIKey,
        FlickrDB.Keys.SafeSearch: FlickrDB.Constants.SafeSearch,
        FlickrDB.Keys.Extra: FlickrDB.Constants.Extras,
        FlickrDB.Keys.Format: FlickrDB.Constants.Format,
        FlickrDB.Keys.NoJsonCallback: FlickrDB.Constants.NoJsonCallback,
        FlickrDB.Keys.PerPage: FlickrDB.Constants.PerPage,
        ]}()

    // Set Flickr photo search parameters as specified in Flickr search API
     
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
  
    
    
    // MARK: - All purpose task method for 3rd party database like Flikr
    // Use pin location to retrieve photos taken at the location
    // The parameters are Flickr Search Photos required parameters in the API specifications.
    
    
    // Given a Pin location, grab photos from Flickr for the PhotoAlbumViewCollection
    // Reference taskForResource in TheMovieDB of FavoriteActors
    func taskForSearchFlickrPhotos(pin: Pin!, pageNumber: Int = 1, completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        
        var mutableParameters = photosSearchParameters
        // Set the page number
        mutableParameters[Keys.PageNumber] = pageNumber
        // Add pin in the parameters
        mutableParameters[Keys.Lon] = pin.coordinate.longitude
        mutableParameters[Keys.Lat] = pin.coordinate.latitude
        
        let urlString = Constants.BaseSecureUrl + FlickrDB.escapedParameters(mutableParameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        print(url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                let newError = FlickrDB.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: newError)
            } else {
                // No error, data returns from request is good.
                print("Step 3 - taskForResource's completionHandler is invoked")
                FlickrDB.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }
        task.resume()
        return task
    }
    
    // Task to update photo.imageFileName in Photo object using the Photo's previously populated URL: imageUrl
    // The actual image is stored in the user's Documents directory for retrievals.
    func taskForUpdatePhotoImageFileName(photo: Photo, completionHandler: (success: Bool, error: NSError?) -> Void){
        // First check if the photo imageFileName is already populated.
        guard (photo.imageFilename == nil) else {
            print("The photo imageFileName is already existed. Skip")
            return
        }
        
        // Retreive Flickr URL from photo.imageURL
        let urlString = photo.imageUrl
        // Wrap around it with NSURL
        let url = NSURL(string: urlString)!
        
        // Configure the request
        let request = NSMutableURLRequest(URL: url)
        
        // Make a remote request to Flickr
        let task = session.dataTaskWithRequest(request) { data, response, error in
            guard (error == nil) else {
                completionHandler(success: false, error: error)
                return
            }
        
            guard let data = data else {
                // data is empty
                completionHandler(success: true, error: nil)
                return
            }
            
            // Data is not empty
            // Set up local fileURL for NSFileManager to store fileURL path to photo.imageFileName in Core Data Store.
            // This is a boilerplate codes to create a NSURL fileURLWithPathCmponents.
            let fileName = NSURL.fileURLWithPath(urlString).lastPathComponent!
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
            let pathArray = [dirPath, fileName]
            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
            
            // Save the data to the user's directory.
            NSFileManager.defaultManager().createFileAtPath(fileURL.path!, contents: data, attributes: nil)
            
            // Update Core Data Photo object using main queue
            dispatch_async(dispatch_get_main_queue()) {
                photo.imageFilename = fileURL.path
                
            }
            completionHandler(success: true, error: nil)
            
        }
            // Start the request task
        task.resume()
    }
    
    
    // MARK: - Helpers
    
    // Error messages provided by Flickr
    // class func is like static func in other language
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if data == nil {
            return error
        }
        
        do {
            let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                // First declare parsedResult as dictionary [String: AnyObject] then parse for the specfic Status key.
                if let parsedResult = parsedResult as? [String: AnyObject], errorMessage = parsedResult[Keys.Status] as? String {
                    let userInfo = [NSLocalizedDescriptionKey: errorMessage]
                    if let errorCode = parsedResult[Keys.Code] as? Int {
                        return NSError(domain: "Flickr Error", code: errorCode, userInfo: userInfo)
                    }
                    return NSError(domain: "Flickr Error", code: 1, userInfo: userInfo)
                }
        } catch _ {}
        return error
    }
    // Parsing the JSON
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHandler) {
        var parsingError: NSError? = nil
        // The nature of this Flickr data is an dictionary with various useful keys. Consult Flickr Spec.
        let parsedResult: NSDictionary
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! NSDictionary
            
        } catch let error as NSError {
            parsingError = error
            parsedResult = [:]
        }
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            /* See Flickr API Photos JSON Scheme and Example
             Returns from Flickr in XML Example
             <photos page="2" pages="89" perpage="10" total="881">
                <photo id="2636" owner="47058503995@N01" secret="a123456" server="2" title="test_04" ispublic="1" isfriend="0" isfamily="0" />
                <photo id="2635" owner="47058503995@N01" secret="b123456" server="2" title="test_03" ispublic="0" isfriend="1" isfamily="1" />
             </photos>
            */
            print("Step 4 - parseJSONWithCompletionHandler is invoked")
            /* Retrieve a single record of Photos */
            if let photosDictionary = parsedResult.valueForKey(FlickrDB.Keys.Photos) as? [String : AnyObject] {
                // First check for the count of photos returned.
                var totalPhotoCount = 0
                if let totalPhotos = photosDictionary[FlickrDB.Keys.Total] as? String {
                    totalPhotoCount = (totalPhotos as NSString).integerValue
                }
                if totalPhotoCount > 0 {
                    /* Retrieve multiple Photo records and store them in Array */
                    let photoArray = photosDictionary[FlickrDB.Keys.Photo] as? [[String : AnyObject]]
                    completionHandler(result: photoArray, error: nil)
                } else {
                    completionHandler(result: nil, error: NSError(domain: "Flickr DB Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "The Pin Location Has No Photos To Share"]))
                }
            }
        }
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }

    // MARK: - Shared Instance
    
    class func sharedInstance() -> FlickrDB {
        struct Singleton {
            static var sharedInstance = FlickrDB()
        }
        return Singleton.sharedInstance
    }
    
    // MARK: - Shared Date Formatter
    class var sharedDateFormatter: NSDateFormatter {
        struct Singleton {
            static let dateFormatter = Singleton.generateDateFormatter()
            
            static func generateDateFormatter() -> NSDateFormatter {
                let formatter = NSDateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }
        }
        return Singleton.dateFormatter
    }
}