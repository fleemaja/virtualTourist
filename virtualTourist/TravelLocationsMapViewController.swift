//
//  TravelLocationsMapViewController.swift
//  virtualTourist
//
//  Created by Drew Fleeman on 7/6/17.
//  Copyright © 2017 drew. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {
    
    var coordinate: CLLocationCoordinate2D?
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer

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
        // load all persisted pins
        addAnnotations()
    }
    
    func addPinToMap(gestureRecognizer:UIGestureRecognizer) {
        // only add one annotation where the press was. No dragging.
        if (gestureRecognizer.state == UIGestureRecognizerState.began) {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            coordinate = newCoordinates
            mapView.addAnnotation(annotation)
            // add pin to db
            var pinInfo = [String:Any]()
            pinInfo["latitude"] = coordinate?.latitude
            pinInfo["longitude"] = coordinate?.longitude
            updateDatabase(with: pinInfo)
        }
    }
    
    private func updateDatabase(with pinInfo: [String:Any]) {
        container?.performBackgroundTask { context in
            _ = try? Pin.findOrCreatePin(matching: pinInfo, in: context)
            try? context.save()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "photoView") {
            let photoView = (segue.destination as! PhotoAlbumViewController)
            photoView.latitudeVal = coordinate?.latitude
            photoView.longitudeVal = coordinate?.longitude
            // pass along pin info from db
        }
    }
    
    private func addAnnotations() {
        var annotations = [MKPointAnnotation]()
        
        if let context = container?.viewContext {
            context.perform {
                let pinRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
                if let pins = (try? context.fetch(pinRequest)) {
                    for pin in pins {
                        let annotation = MKPointAnnotation()
                        let lat = CLLocationDegrees(pin.latitude)
                        let long = CLLocationDegrees(pin.longitude)
                        
                        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                        annotation.coordinate = coordinate
                        
                        annotations.append(annotation)
                    }
                    self.mapView.addAnnotations(annotations)
                }
            }
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

