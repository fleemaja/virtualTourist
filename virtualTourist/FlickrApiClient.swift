//
//  FlickrApiClient.swift
//  virtualTourist
//
//  Created by Drew Fleeman on 7/7/17.
//  Copyright © 2017 drew. All rights reserved.
//

import Foundation

class FlickrApiClient {
    
    public func getPhotos(latitude: Double, longitude: Double, page: Int16, handler: @escaping (_ data: Data?, _ response: AnyObject?, _ error: String?) -> Void) {
        let url = constructURLString(latitude: latitude, longitude: longitude, page: page)
        let request = NSMutableURLRequest(url: URL(string: url)!)
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) { data, response, error in
            handler(data, response, error as? String)
        }
        task.resume()
    }
    
    func constructURLString(latitude: Double, longitude: Double, page: Int16) -> String {
        let apiUrl = "https://api.flickr.com/services/rest/"
        let apiKey = "566809a378d6f02efb1e43163fd55bc5"
        
        let params = [
            "method": "flickr.photos.search",
            "api_key": apiKey,
            "bbox": createBoundingBoxString(latitude: latitude, longitude: longitude),
            "safe_search": "1",
            "extras": "url_m",
            "format": "json",
            "nojsoncallback": "1",
            "per_page": "30",
            "page": page,
            ] as [String : Any]
        
        let request = prepareRequest(baseUrl: "\(apiUrl)", params: params)
        return request
    }
    
    func createBoundingBoxString(latitude: Double, longitude: Double) -> String {
        let boxSideLength = 2.0
        let halfBoxSideLength = boxSideLength / 2
        let minLat = -90.0
        let maxLat = 90.0
        let minLon = -180.0
        let maxLon = 180.0
        
        let bottomLeftLon = max(longitude - halfBoxSideLength, minLon)
        let bottomLeftLat = max(latitude - halfBoxSideLength, minLat)
        let topRightLon = min(longitude + halfBoxSideLength, maxLon)
        let topRightLat = min(latitude + halfBoxSideLength, maxLat)
        
        return "\(bottomLeftLon),\(bottomLeftLat),\(topRightLon),\(topRightLat)"
    }
    
    func prepareRequest(baseUrl: String, params: [String : Any]) -> String {
        let url = baseUrl + "?" + encodeParameters(params: params as [String : AnyObject])
        return url
    }
    
    func encodeParameters(params: [String: AnyObject]) -> String {
        let components = NSURLComponents()
        components.queryItems = params.map { (NSURLQueryItem(name: $0, value: String(describing: $1)) as URLQueryItem) }
        
        return components.percentEncodedQuery ?? ""
    }
    
    /*
     * Return the singleton instance of Model
     */
    class var shared: FlickrApiClient {
        struct Static {
            static let instance: FlickrApiClient = FlickrApiClient()
        }
        return Static.instance
    }
}
