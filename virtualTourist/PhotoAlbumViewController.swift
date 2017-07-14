//
//  PhotoAlbumViewController.swift
//  virtualTourist
//
//  Created by Drew Fleeman on 7/6/17.
//  Copyright © 2017 drew. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    
    var latitudeVal: Double?
    var longitudeVal: Double?
    
    var pin: Pin? {
        didSet {
            if pin?.photos?.count == 0 {
                getFlickrPhotos(latitude: (latitudeVal)!, longitude: (longitudeVal)!)
            } else {
                setPhotos()
            }
        }
    }
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    var placeholderCount = 0 {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    var photos = [UIImage]() {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        mapView.delegate = self as? MKMapViewDelegate
        mapView.isUserInteractionEnabled = false
        
        setMapPinLocation()
        
        setPinAttribute()
    }
    
    private func setMapPinLocation() {
        let annotation = MKPointAnnotation()
        let lat = CLLocationDegrees(latitudeVal!)
        let long = CLLocationDegrees(longitudeVal!)
        
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        annotation.coordinate = coordinate
        
        let region = MKCoordinateRegionMake(coordinate, MKCoordinateSpanMake(10, 10))
        
        DispatchQueue.main.async(execute: {
            self.mapView.addAnnotation(annotation)
            self.mapView.setRegion(region, animated: true)
            self.mapView.regionThatFits(region)
        })
    }
    
    private func setPinAttribute() {
        var pinInfo = [String:Any]()
        pinInfo["latitude"] = latitudeVal
        pinInfo["longitude"] = longitudeVal
        container?.performBackgroundTask { [weak self] context in
            let pin = try? Pin.findOrCreatePin(matching: pinInfo, in: context)
            if (try? context.save()) != nil {
                self?.pin = pin
            }
        }
    }
    
    private func setPhotos() {
        let pinPhotos = pin?.photos
        for photo in pinPhotos! {
            placeholderCount += 1
            let image = UIImage(data: (photo as! Photo).data! as Data)
            self.photos.append(image!)
        }
    }
    
    @IBAction func fetchNewCollection(_ sender: UIButton) {
        deletePinPhotos()
        getFlickrPhotos(latitude: (latitudeVal)!, longitude: (longitudeVal)!)
    }
    
    private func deletePinPhotos() {
        if let context = container?.viewContext {
            context.perform {
                let photoRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
                photoRequest.predicate = NSPredicate(format: "%K == %@", argumentArray:["pin", self.pin!])
                if let result = try? context.fetch(photoRequest) {
                    for object in result {
                        context.delete(object)
                        self.placeholderCount = 0
                        self.photos = [UIImage]()
                    }
                    try? context.save()
                }
            }
        }
    }
    
    // add get new collection button that clears db for this pin and calls getFlickrPhotos
    
    func getFlickrPhotos(latitude: Double, longitude: Double) {
        FlickrApiClient.shared.getPhotos(latitude: latitude, longitude: longitude) { data, response, error in
            //            print(NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!)
            if error != nil {
                return
            }
            
            let results: [[String: AnyObject]]
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String:Any]
                guard let photoData = json!["photos"] as? [String : AnyObject] else {
                    print("Can't find [photos] in response")
                    return
                }
                results = (photoData["photo"] as? [[String : AnyObject]])!
            } catch {
                print("JSON converting error")
                return
            }
            for result in results {
                let url = URL(string: result["url_m"] as! String)
                self.placeholderCount += 1
                DispatchQueue.global().async {
                    let data = try? Data(contentsOf: url!)
                    
                    if data != nil {
                        let image = UIImage(data: data!)
                        self.photos.append(image!)
                        var pinInfo = [String:Any]()
                        pinInfo["latitude"] = self.latitudeVal
                        pinInfo["longitude"] = self.longitudeVal
                        self.addPhotoToDatabase(image: image!, pinInfo: pinInfo)
                    }
                }
            }
        }
    }
    
    private func addPhotoToDatabase(image: UIImage, pinInfo: [String:Any]) {
        var photoInfo = [String:Any]()
        photoInfo["photo"] = UIImagePNGRepresentation(image) as NSData?
        container?.performBackgroundTask { [weak self] context in
            print("trying to create photo")
            if let pin = try? Pin.findOrCreatePin(matching: pinInfo, in: context) {
                if (try? context.save()) != nil {
                    photoInfo["pin"] = pin
                    _ = try? Photo.createPhoto(matching: photoInfo, in: context)
                    try? context.save()
                    self?.printDatabaseStatistics()
                }
            }
        }
    }
    
    private func printDatabaseStatistics() {
        if let context = container?.viewContext {
            context.perform {
                let photoRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
                if let photoCount = (try? context.fetch(photoRequest))?.count {
                    print("\(photoCount) photos in database")
                }
                let pinRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
                if let pinCount = (try? context.fetch(pinRequest))?.count {
                    print("\(pinCount) pins in database")
                }
            }
        }
    }

}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    // MARK: UICollectionViewDataSource
    /*
     * Number of sections been fetched
     */
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    /*
     * Number of photos been fetched
     */
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return placeholderCount
//        return fetchedResultsController.sections![section].numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = photos[indexPath.row]
        let photoDataToDelete = UIImagePNGRepresentation(photoToDelete)! as NSData
        if let context = container?.viewContext {
            context.perform {
                let photoRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
                photoRequest.predicate = NSPredicate(format: "%K == %@", argumentArray:["data", photoDataToDelete])
                if let result = try? context.fetch(photoRequest) {
                    for object in result {
                        context.delete(object)
                        self.placeholderCount -= 1
                        self.photos.remove(at: indexPath.row)
                        try? context.save()
                    }
                }
            }
        }
    }
    
    /*
     * Return one collection cell prepared to display
     */
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCollectionViewCell
        if indexPath.row < self.photos.count {
            cell.photo = self.photos[indexPath.row]
        }
        
        return cell
    }
}
