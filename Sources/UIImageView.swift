import UIKit
import RHBFoundation

public extension UIImageView {
    static let imageCache: CacheByURL<UIImage> = {
        let urlSession: URLSession = {
            let config: URLSessionConfiguration = .default
            config.requestCachePolicy = .returnCacheDataElseLoad
            return URLSession(configuration: config)
        }()

        let completionManager = TaskCompletionManager<UIImage>(urlSession: urlSession) { imageblock in
            return { data, response, error in
                let image: UIImage? = data.map { UIImage(data: $0) } ?? nil
                imageblock(image, data, response, error)
            }
        }

        return CacheByURL(taskCompletionManager: completionManager)
    }()

    func setCachedImage(url: URL, imageCache: CacheByURL<UIImage> = imageCache, completon: (()->Void)? = nil) -> DeinitBlock? {
        return imageCache.cachedObject(url: url) { [weak self] image in
            self?.image = image
            completon?()
        }
    }
}
