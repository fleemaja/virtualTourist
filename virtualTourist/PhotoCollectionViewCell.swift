//
//  PhotoCollectionViewCell.swift
//  virtualTourist
//
//  Created by Drew Fleeman on 7/7/17.
//  Copyright © 2017 drew. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    var photo: UIImage? { didSet { updateUI() } }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var photoImageView: UIImageView!
    
    private func updateUI() {
        spinner.stopAnimating()
        photoImageView.image = photo
    }
    
}
