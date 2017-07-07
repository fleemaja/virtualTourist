//
//  TravelLocationsMapViewController.swift
//  virtualTourist
//
//  Created by Drew Fleeman on 7/6/17.
//  Copyright © 2017 drew. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsMapViewController: UIViewController {
    
    var coordinate: CLLocationCoordinate2D?

    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            let pressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addPinToMap))
            pressRecognizer.minimumPressDuration = 2.0
            mapView.addGestureRecognizer(pressRecognizer)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
    }
    
    func addPinToMap(gestureRecognizer:UIGestureRecognizer) {
        // only add one annotation where the press was. No dragging.
        if (gestureRecognizer.state == UIGestureRecognizerState.began) {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
//            annotation.title = "TITLE"
//            annotation.subtitle = "SUBTITLE"
            coordinate = newCoordinates
            mapView.addAnnotation(annotation)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "photoView") {
            let photoView = (segue.destination as! PhotoAlbumViewController)
            photoView.latitudeVal = coordinate?.latitude
            photoView.longitudeVal = coordinate?.longitude
            getFlickrPhotos(latitude: (coordinate?.latitude)!, longitude: (coordinate?.longitude)!)
        }
        
    }
    
    func getFlickrPhotos(latitude: Double, longitude: Double) {
        FlickrApiClient.shared.getPhotos(latitude: latitude, longitude: longitude) { data, response, error in
            print(NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!)
        }
    }

}

extension TravelLocationsMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        coordinate = view.annotation!.coordinate
        performSegue(withIdentifier: "photoView", sender: nil)
        mapView.deselectAnnotation(view.annotation!, animated: false)
    }
}

