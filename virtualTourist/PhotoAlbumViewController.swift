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
        
        setupCollectionFlowLayout()
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
                        var pinInfo = [String:Any]()
                        pinInfo["latitude"] = self.latitudeVal
                        pinInfo["longitude"] = self.longitudeVal
                        self.addPhotoToDatabase(image: image!, pinInfo: pinInfo)
                    }
                }
            }
        }
    }
    
    enum DBError: Error {
        case saveError(String)
    }
    
    private func addPhotoToDatabase(image: UIImage, pinInfo: [String:Any]) {
        var photoInfo = [String:Any]()
        photoInfo["photo"] = UIImagePNGRepresentation(image) as NSData?
        container?.performBackgroundTask { context in
            if let pin = try? Pin.findOrCreatePin(matching: pinInfo, in: context) {
                if (try? context.save()) != nil {
                    do {
                        photoInfo["pin"] = pin
                        let newPhoto = try? Photo.createPhoto(matching: photoInfo, in: context)
                        guard (try? context.save()) != nil else {
                            self.placeholderCount -= 1
                            throw DBError.saveError("Could not save to DB")
                        }
                        let image = UIImage(data: (newPhoto!).data! as Data)
                        self.photos.append(image!)
                    } catch {
                        print("error: \(error)")
                    }
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
        if indexPath.row < photos.count {
            let photoData = UIImagePNGRepresentation(photos[indexPath.row])!
            self.photos.remove(at: indexPath.row)
            self.placeholderCount -= 1
            DispatchQueue.global().async {
                if let context = self.container?.viewContext {
                    context.perform {
                        let photoRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
                        photoRequest.predicate = NSPredicate(format: "%K == %@", argumentArray:["pin", self.pin!])
                        if let results = (try? context.fetch(photoRequest)) {
                            for object in results {
                                let objectData = object.data! as Data
                                if objectData == photoData {
                                    context.delete(object)
                                    try? context.save()
                                }
                            }
                        }
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

extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        setupCollectionFlowLayout()
    }
    
    func setupCollectionFlowLayout() {
        let items: CGFloat = view.frame.size.width > view.frame.size.height ? 5.0 : 3.0
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - ((items + 1) * space)) / items
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 8.0 - items
        layout.minimumInteritemSpacing = space
        layout.itemSize = CGSize(width: dimension, height: dimension)
        
        collectionView.collectionViewLayout = layout
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let items: CGFloat = view.frame.size.width > view.frame.size.height ? 5.0 : 3.0
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - ((items + 1) * space)) / items
        return CGSize(width: dimension, height: dimension)
    }
    
}
