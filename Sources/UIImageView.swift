import UIKit
import RHBFoundation

public extension UIImageView {
    func setCachedImage(url: URL, imageCache: UIImageURLCache = .shared) -> DeinitBlock? {
        return imageCache.cachedImage(url: url) { [weak self] image in
            self?.image = image
        }
    }
}
