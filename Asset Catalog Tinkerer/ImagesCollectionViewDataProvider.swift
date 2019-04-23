//
//  ImagesCollectionViewDataProvider.swift
//  Asset Catalog Tinkerer
//
//  Created by Guilherme Rambo on 27/03/16.
//  Copyright © 2016 Guilherme Rambo. All rights reserved.
//

import Cocoa

class ImagesCollectionViewDataProvider: NSObject, NSCollectionViewDataSource, NSCollectionViewDelegate {
    
    fileprivate struct Constants {
        static let nibName = "ImageCollectionViewItem"
        static let imageItemIdentifier = NSUserInterfaceItemIdentifier("ImageItemIdentifier")
    }
    
    var collectionView: NSCollectionView! {
        didSet {
            collectionView.setDraggingSourceOperationMask(.copy, forLocal: false)
            
            collectionView.delegate = self
            collectionView.dataSource = self
            
            collectionView.collectionViewLayout = GridLayout()
            
            let nib = NSNib(nibNamed: Constants.nibName, bundle: nil)
            collectionView.register(nib, forItemWithIdentifier: Constants.imageItemIdentifier)
        }
    }
    
    var images = [[String: NSObject]]() {
        didSet {
            filteredImages = filterImagesWithCurrentSearchTerm()
            collectionView.reloadData()
        }
    }
    
    var searchTerm = "" {
        didSet {
            filteredImages = filterImagesWithCurrentSearchTerm()
            collectionView.reloadData()
        }
    }
    
    var filteredImages = [[String: NSObject]]()
    
    fileprivate func filterImagesWithCurrentSearchTerm() -> [[String: NSObject]] {
        guard !searchTerm.isEmpty else { return images }
        
        let predicate = NSPredicate(format: "name contains[cd] %@", searchTerm)
        return (images as NSArray).filtered(using: predicate) as! [[String: NSObject]]
    }
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: Constants.imageItemIdentifier, for: indexPath) as! ImageCollectionViewItem
        
        item.image = filteredImages[(indexPath as NSIndexPath).item]
        
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredImages.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, writeItemsAt indexPaths: Set<IndexPath>, to pasteboard: NSPasteboard) -> Bool {
        pasteboard.clearContents()
        
        let images: [URL?] = indexPaths.map { indexPath in
            let index = (indexPath as NSIndexPath).item

            let image = self.filteredImages[index]
            guard let filename = image["filename"] as? String else { return nil }
            guard let data = (image["png"] ?? image["pdf"]) as? Data else { return nil }
            let tempURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())\(filename)")
            
            guard (try? data.write(to: tempURL, options: [.atomic])) != nil else { return nil }
            
            return tempURL
        }
        
		let validImages: [NSURL] = images.filter { $0 != nil }.map { $0! as NSURL }

		pasteboard.writeObjects(validImages)

        return true
    }
    
}
