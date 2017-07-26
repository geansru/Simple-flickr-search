//
//  FlickrPhotoViewController.swift
//  FlickrSearch
//
//  Created by Dmitriy Roytman on 26.07.17.
//  Copyright © 2017 Dmitriy Roytman. All rights reserved.
//

import UIKit

final class FlickrPhotoViewController: UICollectionViewController {
    // MARK: Constant
    private let sectionInsets = UIEdgeInsets(top: 50, left: 20, bottom: 50, right: 20)
    private let itemsPerRow: CGFloat = 3
    private let reuseIdentifier = "FlickrCell"
    private var searches: [FlickrSearchResults] = []
    private let flickr = Flickr()
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = sectionInsets
        collectionView?.setCollectionViewLayout(layout, animated: false)
        
        super.viewDidLoad()
    }
}
// MARK: Helper
private extension FlickrPhotoViewController {
    func photoForIndexPath(indexPath: IndexPath) -> FlickrPhoto {
        return searches[indexPath.section].searchResults[indexPath.row]
    }
}

// MARK: UITextField delegate
extension FlickrPhotoViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        textField.addSubview(activityIndicator)
        activityIndicator.frame = textField.bounds
        flickr.searchFlickrForTerm(textField.text!) { [weak self] results, error in
            activityIndicator.removeFromSuperview()
            guard error == nil else {
                print(error ?? "")
                return
            }
            guard let results = results, let sself = self else { return }
            print("Found \(results.searchResults.count) matching \(results.searchTerm)")
            sself.searches.insert(results, at: 0)
            sself.collectionView?.reloadData()
        }
        textField.text = nil
        textField.resignFirstResponder()
        return true
    }
}

// MARK: data source
extension FlickrPhotoViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return searches.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searches[section].searchResults.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FlickrPhotoCell
        cell.imageView.image = photoForIndexPath(indexPath: indexPath).thumbnail
        cell.backgroundColor = .white
        return cell
    }
}

extension FlickrPhotoViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}
