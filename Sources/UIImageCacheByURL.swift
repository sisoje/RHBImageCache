import UIKit
import RHBFoundation

public class UIImageCacheByURL: GenericCacheByURL<UIImage> {
    let imageTaskCompletionManager: UIImageTaskCompletionManager
    init(imageTaskCompletionManager: UIImageTaskCompletionManager) {
        self.imageTaskCompletionManager = imageTaskCompletionManager
    }
}

public extension UIImageCacheByURL {
    static let shared = UIImageCacheByURL(imageTaskCompletionManager: .shared)
}

public extension UIImageCacheByURL {
    func cachedImage(url: URL, _ block: @escaping (UIImage?) -> Void) -> DeinitBlock? {
        if let image = self[url] {
            block(image)
            return nil
        }
        return imageTaskCompletionManager.completionHolder(url) { [weak self] image, _, _, _ in
            self.map { cache in
                // in the meanwhile we might already have image in the cache so just keep it and discard the new one
                let realimage = cache[url] ?? image
                cache[url] = realimage
                block(realimage)
            }
        }
    }
}
