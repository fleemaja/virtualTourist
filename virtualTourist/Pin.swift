//
//  Pin.swift
//  virtualTourist
//
//  Created by Drew Fleeman on 7/10/17.
//  Copyright © 2017 drew. All rights reserved.
//

import UIKit
import CoreData

class Pin: NSManagedObject {

    class func findOrCreatePin(matching pinInfo: [String:Any], in context: NSManagedObjectContext) throws -> Pin {
        let request: NSFetchRequest<Pin> = Pin.fetchRequest()
        request.predicate = NSPredicate(format: "%K == %@ AND %K == %@", argumentArray:["latitude", pinInfo["latitude"] as! Double, "longitude", pinInfo["longitude"] as! Double])
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                return matches[0]
            }
        } catch {
            throw error
        }
        
        // no existing pin found. create new pin for this location
        let pin = Pin(context: context)
        pin.latitude = pinInfo["latitude"] as! Double
        pin.longitude = pinInfo["longitude"] as! Double
        pin.currentPage = 1
        return pin
    }
    
    class func updatePinPage(matching pinInfo: [String:Any], in context: NSManagedObjectContext) throws -> Pin {
        let pin = try findOrCreatePin(matching: pinInfo, in: context)
        pin.currentPage += 1
        return pin
    }
    
}
