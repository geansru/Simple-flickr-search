//
//  FlickrPhotoCell.swift
//  FlickrSearch
//
//  Created by Dmitriy Roytman on 26.07.17.
//  Copyright © 2017 Dmitriy Roytman. All rights reserved.
//

import UIKit

final class FlickrPhotoCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override var isSelected: Bool {
        didSet {
            imageView.layer.borderWidth = isSelected ? 10 : 0
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.layer.borderColor = UIColor(named: "themeColor")!.cgColor
        isSelected = false
        activityIndicator.isHidden = true
        backgroundColor = .white
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        isSelected = false
        imageView.image = nil
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
        layer.borderWidth = 0
    }
}
