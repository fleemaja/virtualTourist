//
//  PhotoAlbumViewController.swift
//  virtualTourist
//
//  Created by Drew Fleeman on 7/6/17.
//  Copyright © 2017 drew. All rights reserved.
//

import UIKit
import CoreData

class PhotoAlbumViewController: UIViewController {

    @IBOutlet weak var latitude: UILabel?
    @IBOutlet weak var longitude: UILabel?
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    
    var latitudeVal: Double?
    var longitudeVal: Double?
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    var photoPlaceholders = [URL]() {
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
        
        // if pin already has photos:
        // getPhotos()
        // else:
//        getFlickrPhotos(latitude: (latitudeVal)!, longitude: (longitudeVal)!)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        latitude?.text = "latitude: \(latitudeVal ?? 0.0)"
        longitude?.text = "longitude: \(longitudeVal ?? 0.0)"
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
                self.photoPlaceholders.append(url!)
                DispatchQueue.global().async {
                    let data = try? Data(contentsOf: url!)
                    
                    if data != nil {
                        let image = UIImage(data: data!)
                        self.photos.append(image!)
                        var photoInfo = [String:Any]()
                        photoInfo["latitude"] = self.latitudeVal
                        photoInfo["longitude"] = self.longitudeVal
                        photoInfo["photo"] = image
                        self.updateDatabase(with: photoInfo)
                    }
                }
            }
        }
    }
    
    private func updateDatabase(with photoInfo: [String:Any]) {
        container?.performBackgroundTask { [weak self] context in
            _ = try? Photo.findOrCreatePhoto(matching: photoInfo, in: context)
            try? context.save()
            self?.printDatabaseStatistics()
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
        return self.photoPlaceholders.count
//        return fetchedResultsController.sections![section].numberOfObjects
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
