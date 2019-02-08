import UIKit
import RHBFoundation

public class CacheByURL<T: AnyObject>: Cache<URL, T> {
    let taskCompletionManager: TaskCompletionManager<T>
    init(taskCompletionManager: TaskCompletionManager<T>) {
        self.taskCompletionManager = taskCompletionManager
    }
}

public extension CacheByURL {
    func cachedObject(url: URL, _ block: @escaping (T?) -> Void) -> DeinitBlock? {
        if let object = self[url] {
            block(object)
            return nil
        }

        return taskCompletionManager.managedTask(url) { [weak self] object, _, _, _ in
            self.map { cache in
                // in the meanwhile we might already have object in the cache so just keep it and discard the new one
                let object = cache[url] ?? object
                cache[url] = object
                block(object)
            }
        }
    }
}
