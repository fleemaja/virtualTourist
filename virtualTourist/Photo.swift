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

    class func findOrCreatePhoto(matching photoInfo: [String:Any], in context: NSManagedObjectContext) throws -> Photo {
//        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
//        request.predicate = NSPredicate(format: "data = %@", photoInfo["photo"])
//        
//        do {
//            let matches = try context.fetch(request)
//            if matches.count > 0 {
//                return matches[0]
//            }
//        } catch {
//            throw error
//        }
        
        let photo = Photo(context: context)
        photo.data = photoInfo["photo"] as? NSData
        photo.pin = try? Pin.findOrCreatePin(matching: photoInfo, in: context)
        return photo
    }
    
}
