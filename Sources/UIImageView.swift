import UIKit
import RHBFoundation

extension Result where Success == UIImage, Failure == DataTaskError {
    static let imageConverter: (DataTaskData) -> Result<UIImage, DataTaskError> = { dataTaskData in
        guard let image = UIImage(data: dataTaskData.0) else {
            return .failure(.messageWithInfo("invalid image data", DataTaskInfo(dataTaskData.0, dataTaskData.1)))
        }
        return .success(image)
    }
}

public extension UIImageView {
    static let imageCache: CacheByURL<UIImage> = {
        let urlSession: URLSession = {
            let config: URLSessionConfiguration = .default
            config.requestCachePolicy = .returnCacheDataElseLoad
            return URLSession(configuration: config)
        }()

        let taskRunner: (URL, @escaping DataTaskCompletionBlock) -> DeinitBlock = { url, completion in
            let task = urlSession.dataTask(with: url, completionHandler: completion)
            return task.runner
        }

        let completionManager = TaskCompletionManager(dataMapper: Result<UIImage, DataTaskError>.imageConverter, taskRunner: taskRunner)

        return CacheByURL(taskCompletionManager: completionManager)
    }()

    func setCachedImage(url: URL, imageCache: CacheByURL<UIImage> = imageCache, completon: ((Result<UIImage, DataTaskError>)->Void)? = nil) -> DeinitBlock? {
        return imageCache.cachedObject(url: url) { [weak self] imageresult in
            self?.image = try? imageresult.get()
            completon?(imageresult)
        }
    }
}
