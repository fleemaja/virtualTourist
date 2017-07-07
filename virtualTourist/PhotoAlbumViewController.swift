//
//  PhotoAlbumViewController.swift
//  virtualTourist
//
//  Created by Drew Fleeman on 7/6/17.
//  Copyright © 2017 drew. All rights reserved.
//

import UIKit

class PhotoAlbumViewController: UIViewController {

    @IBOutlet weak var latitude: UILabel?
    @IBOutlet weak var longitude: UILabel?
    
    var latitudeVal: Double?
    var longitudeVal: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        latitude?.text = "\(latitudeVal ?? 0.0)"
        longitude?.text = "\(longitudeVal ?? 0.0)"
    }

}
