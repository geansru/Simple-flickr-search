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
    private let flickr = Flickr()
    
    // mark: properties
    private var selectedPhotos: [FlickrPhoto] = []
    private let shareTextLabel = UILabel()
    private var searches: [FlickrSearchResults] = []
    private var largePhotoIndexPath: IndexPath? {
        didSet {
            var indexPaths: [IndexPath] = []
            if let largePhotoIndexPath = largePhotoIndexPath {
                indexPaths.append(largePhotoIndexPath)
            }
            if let oldValue = oldValue {
                indexPaths.append(oldValue)
            }
            let updates: ()->Void = { [weak collectionView] in
                collectionView?.reloadItems(at: indexPaths)
            }
            let completion: (Bool)->Void = { [weak collectionView, largePhotoIndexPath] completed in
                guard let collectioView = collectionView, let largePhotoIndexPath = largePhotoIndexPath else { return }
                collectioView.scrollToItem(at: largePhotoIndexPath, at: .centeredVertically, animated: true)
            }
            collectionView?.performBatchUpdates(updates, completion: completion)
        }
    }
    
    private var sharing = false {
        didSet {
            collectionView?.allowsMultipleSelection = sharing
            collectionView?.selectItem(at: nil, animated: true, scrollPosition: .centeredHorizontally)
            selectedPhotos.removeAll(keepingCapacity: true)
            
            guard let shareButton = navigationItem.rightBarButtonItems?.first else { return }
            guard sharing else {
                navigationItem.setRightBarButtonItems([shareButton], animated: true)
                return
            }
            if let _ = largePhotoIndexPath { largePhotoIndexPath = nil }
            
            updateSharedPhotoCount()
            
            let sharingDetailItem = UIBarButtonItem(customView: shareTextLabel)
            navigationItem.setRightBarButtonItems([shareButton, sharingDetailItem], animated: true)
            
        }
    }
    @IBAction func share(_ sender: UIBarButtonItem) {
        guard !searches.isEmpty else { return }
        guard !selectedPhotos.isEmpty else {
            sharing = !sharing
            return
        }
        guard sharing else { return }
        
        var imageArray: [UIImage] = []
        for selectedPhoto in selectedPhotos {
            if let thumbnail = selectedPhoto.thumbnail {
                imageArray.append(thumbnail)
            }
        }
        
        guard !imageArray.isEmpty else { return }
        let shareScreen = UIActivityViewController(activityItems: imageArray, applicationActivities: nil)
        shareScreen.completionWithItemsHandler = { [weak self] (_,_,_,_) in
            self?.sharing = false
        }
        if let popoverPresentationController = shareScreen.popoverPresentationController {
            popoverPresentationController.barButtonItem = sender
            popoverPresentationController.permittedArrowDirections = .any
        }
        present(shareScreen, animated: true, completion: nil)
    }
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
// MARK: Helper
private extension FlickrPhotoViewController {
    func photoForIndexPath(indexPath: IndexPath) -> FlickrPhoto {
        return searches[indexPath.section].searchResults[indexPath.row]
    }
    
    func updateSharedPhotoCount() {
        shareTextLabel.textColor = UIColor(named: "themeColor")!
        shareTextLabel.text = "\(selectedPhotos.count) photos selected"
        shareTextLabel.sizeToFit()
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
        let flickrPhoto = photoForIndexPath(indexPath: indexPath)
        cell.activityIndicator.stopAnimating() // TODO: Remove this string
        
        guard indexPath == largePhotoIndexPath else {
            cell.imageView.image = flickrPhoto.thumbnail
            return cell
        }
        guard flickrPhoto.largeImage == nil else {
            cell.imageView.image = flickrPhoto.largeImage
            return cell
        }
        
        cell.imageView.image = flickrPhoto.thumbnail
        cell.activityIndicator.isHidden = false
        cell.activityIndicator.startAnimating()
        
        flickrPhoto.loadLargeImage { (photo, error) in
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.isHidden = true
            guard error == nil,
                let largeImage = photo.largeImage,
                let cell = collectionView.cellForItem(at: indexPath) as? FlickrPhotoCell else { return }
            cell.imageView.image = largeImage
        }
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "CollectionHeader", for: indexPath) as! FlickrPhotoHeaderReusableView
        headerView.label.text = searches[indexPath.section].searchTerm
        return headerView
    }
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard !sharing else { return true }
        largePhotoIndexPath = largePhotoIndexPath == indexPath ? nil : indexPath
        return false
    }
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard sharing else { return }
        
        let photo = photoForIndexPath(indexPath: indexPath)
        selectedPhotos.append(photo)
        updateSharedPhotoCount()
    }
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard sharing else { return }
        
        let photo = photoForIndexPath(indexPath: indexPath)
        
        if let index = selectedPhotos.index(of: photo) {
            selectedPhotos.remove(at: index)
            updateSharedPhotoCount()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        var sourceResults = searches[sourceIndexPath.section].searchResults
        let flickrPhoto = sourceResults.remove(at: sourceIndexPath.row)
        
        var destinationResults = searches[destinationIndexPath.section].searchResults
        destinationResults.insert(flickrPhoto, at: destinationIndexPath.row)
    }
}

extension FlickrPhotoViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath == largePhotoIndexPath {
            let flickrPhoto = photoForIndexPath(indexPath: indexPath)
            var size = collectionView.bounds.size
            size.height -= topLayoutGuide.length
            size.height -= sectionInsets.top + sectionInsets.right
            size.width -= sectionInsets.left + sectionInsets.right
            return flickrPhoto.sizeToFillWidthOfSize(size)
        }
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
