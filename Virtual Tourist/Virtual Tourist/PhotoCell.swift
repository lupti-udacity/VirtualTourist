//
//  PhotoCell.swift
//  Virtual Tourist
//
//  Created by Lupti on 5/5/16.
//  Copyright © 2016 lupti. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        if imageView.image == nil {
            activityView.startAnimating()
        }
    }

    
}
