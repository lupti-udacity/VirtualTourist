//
//  FlickrDB-Constants.swift
//  Virtual Tourist
//
//  Created by Lupti on 4/12/16.
//  Copyright © 2016 lupti. All rights reserved.
//

extension FlickrDB {
    
    struct Constants {
        static let BaseSecureUrl: String = "https://api.flickr.com/services/rest/"
        static let APIKey = "8477c4183d4d580bfc16b0891289dfa0"
        static let Method = "flickr.photos.search"
        static let BoundingBoxHalfWidth = 1.0
        static let BoundingBoxHalfHeight = 1.0
        static let LatitudeMin = -90.0
        static let LatitudeMax = 90.0
        static let LongitudeMin = -180.0
        static let LongitudeMax = 180.0
        static let SafeSearch = "1"
        static let Extras = "url_m"
        static let Format = "json"
        static let NoJsonCallback = "1"
        static let PerPage = "21"
        static let PageNumber = 1
    }
    
    struct Keys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let BoundingBox = "bbox"
        static let SafeSearch = "safe_search"
        static let Extra = "extra"
        static let Format = "format"
        static let NoJsonCallback = "nojsoncallback"
        static let PerPage = "per_page"
        static let PageNumber = "page"
        static let Lat = "lat"
        static let Lon = "lon"

        // JSONResponseKeys
        static let Photos = "photos"
        static let Pages = "pages"
        static let Title = "title"
        static let Photo = "photo"
        static let Total = "total"
        static let PhotoUrl = "url_m"
        
        // Errors by Flickr
        static let Status = "stat"
        static let Code = "code"
        static let Message = "message"
    }
    
}
