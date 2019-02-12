import UIKit
import RHBFoundation

public extension UIImageView {
    static let imageCache: CacheByURL<UIImage> = {
        let urlSession: URLSession = {
            let config: URLSessionConfiguration = .default
            config.requestCachePolicy = .returnCacheDataElseLoad
            return URLSession(configuration: config)
        }()

        let imageConverter: (DataTaskData) -> Result<UIImage, Error> = { dataTaskData in
            return dataTaskData.first
                .flatMap { UIImage(data: $0) }
                .map { .success($0) }
                ?? .failure(ErrorWithInfo("can not convert data to image", dataTaskData))
        }

        let taskRunner: (URL, @escaping DataTaskCompletionBlock) -> DeinitBlock = { url, completion in
            let task = urlSession.dataTask(with: url, completionHandler: completion)
            return task.runner
        }

        let completionManager = TaskCompletionManager(dataMapper: imageConverter, taskRunner: taskRunner)

        return CacheByURL(taskCompletionManager: completionManager)
    }()

    func setCachedImage(url: URL, imageCache: CacheByURL<UIImage> = imageCache, completon: ((Result<UIImage, Error>)->Void)? = nil) -> DeinitBlock? {
        return imageCache.cachedObject(url: url) { [weak self] imageresult in
            self?.image = try? imageresult.get()
            completon?(imageresult)
        }
    }
}
