/*
 MIT License

 Copyright (c) 2017-2018 MessageKit

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import UIKit
import MapKit

open class LocationMessageCell: MessageCollectionViewCell {

    open override class func reuseIdentifier() -> String { return "messagekit.cell.location" }

    // MARK: - Properties

    open var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    open var imageView = UIImageView()
    
    private weak var snapShotter: MKMapSnapshotter?

    open override func setupSubviews() {
        super.setupSubviews()
        imageView.contentMode = .scaleAspectFill
        messageContainerView.addSubview(imageView)
        messageContainerView.addSubview(activityIndicator)
        setupConstraints()
    }

    open func setupConstraints() {
        imageView.fillSuperview()
        activityIndicator.centerInSuperview()
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        snapShotter?.cancel()
    }

    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            fatalError("MessagesDisplayDelegate is not set.")
        }
        let options = displayDelegate.snapshotOptionsForLocation(message: message, at: indexPath, in: messagesCollectionView)
        let annotationView = displayDelegate.annotationViewForLocation(message: message, at: indexPath, in: messagesCollectionView)
        let animationBlock = displayDelegate.animationBlockForLocation(message: message, at: indexPath, in: messagesCollectionView)

        guard case let .location(location) = message.data else { fatalError("") }

        activityIndicator.startAnimating()

        let snapshotOptions = MKMapSnapshotOptions()
        snapshotOptions.region = MKCoordinateRegion(center: location.coordinate, span: options.span)
        snapshotOptions.showsBuildings = options.showsBuildings
        snapshotOptions.showsPointsOfInterest = options.showsPointsOfInterest

        let snapShotter = MKMapSnapshotter(options: snapshotOptions)
        self.snapShotter = snapShotter
        snapShotter.start { (snapshot, error) in
            defer {
                self.activityIndicator.stopAnimating()
            }
            guard let snapshot = snapshot, error == nil else {
                //show an error image?
                return
            }

            guard let annotationView = annotationView else {
                self.imageView.image = snapshot.image
                return
            }

            UIGraphicsBeginImageContextWithOptions(snapshotOptions.size, true, 0)

            snapshot.image.draw(at: .zero)

            var point = snapshot.point(for: location.coordinate)
            //Move point to reflect annotation anchor
            point.x -= annotationView.bounds.size.width / 2
            point.y -= annotationView.bounds.size.height / 2
            point.x += annotationView.centerOffset.x
            point.y += annotationView.centerOffset.y

            annotationView.image?.draw(at: point)
            let composedImage = UIGraphicsGetImageFromCurrentImageContext()

            UIGraphicsEndImageContext()
            self.imageView.image = composedImage
            animationBlock?(self.imageView)
        }
        
        
    }
}