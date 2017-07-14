//
//  Photo.swift
//  virtualTourist
//
//  Created by Drew Fleeman on 7/10/17.
//  Copyright © 2017 drew. All rights reserved.
//

import UIKit
import CoreData

class Photo: NSManagedObject {
    
    class func createPhoto(matching photoInfo: [String:Any], in context: NSManagedObjectContext) throws -> Photo {
        let photo = Photo(context: context)
        photo.data = photoInfo["photo"] as? NSData
        photo.pin = photoInfo["pin"] as? Pin
        return photo
    }
    
}
