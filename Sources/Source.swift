import Foundation
import UIKit
import RHBFoundation

extension URLSession {
    static let imageCache: URLSession = {
        let config: URLSessionConfiguration = .default
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()
}

protocol CompletionConverterProtocol {
    associatedtype C
    func convert(_ block: @escaping (C?, Data?, URLResponse?, Error?) -> Void) -> (Data?, URLResponse?, Error?) -> Void
}

class ImageCompletionConverter {}

extension ImageCompletionConverter: CompletionConverterProtocol {
    func convert(_ block: @escaping (UIImage?, Data?, URLResponse?, Error?) -> Void) -> (Data?, URLResponse?, Error?) -> Void {
        return { data, response, error in
            let image: UIImage? = data.map { UIImage(data: $0) } ?? nil
            IfBlock.debug.yes {
                print("\(#file) \(#function) \(#line) IMAGE CREATED")
            }
            block(image, data, response, error)
        }
    }
}

extension ImageCompletionConverter {
    static let shared = ImageCompletionConverter()
}

class TaskCompletion<T>: NSObject {
    let completion: (T?, Data?, URLResponse?, Error?) -> Void
    init(block: @escaping (T?, Data?, URLResponse?, Error?) -> Void) {
        self.completion = block
    }
}

class TaskCompletionCollection<T> {
    var completions = Set<TaskCompletion<T>>()
    let taskRunner: DeinitBlock
    init(taskRunner: DeinitBlock, completion: TaskCompletion<T>) {
        self.taskRunner = taskRunner
        completions.insert(completion)
    }
}

extension TaskCompletionCollection {
    func call(_ t: T?, _ data: Data?, _ response: URLResponse?, _ error: Error?) {
        completions.forEach { $0.completion(t, data, response, error) }
    }

    func add(_ item: TaskCompletion<T>) {
        completions.insert(item)
    }

    func remove(_ item: TaskCompletion<T>) {
        completions.remove(item)
    }

    var isEmpty: Bool {
        return completions.isEmpty
    }
}

class TaskCompletionManager<CONVERTER: CompletionConverterProtocol> {
    typealias OBJECT_TYPE = CONVERTER.C
    let session: URLSession
    let converter: CONVERTER
    init(urlSession: URLSession, converter: CONVERTER) {
        self.session = urlSession
        self.converter = converter
    }
    var tasks: [URL: TaskCompletionCollection<OBJECT_TYPE>] = [:]

    func completionHolder(_ url: URL, _ block: @escaping (OBJECT_TYPE?, Data?, URLResponse?, Error?) -> Void) -> DeinitBlock {
        let item = TaskCompletion(block: block)

        let result = DeinitBlock { [weak self, weak item] in
            self.map { man in
                man.tasks[url].map { col in
                    item.map { col.remove($0) }
                    if col.isEmpty {
                        man.tasks.removeValue(forKey: url)
                    }
                }
            }
        }

        if let collection = tasks[url] {
            collection.add(item)
            return result
        }


        let completionHandler = converter.convert { [weak self] object, data, response, error in
            DispatchQueue.main.async {
                self.map { man in
                    man.tasks[url].map { col in
                        col.call(object, data, response, error)
                    }
                    man.tasks.removeValue(forKey: url)
                }
            }
        }

        let task = session.dataTask(with: url, completionHandler: completionHandler)

        tasks[url] = TaskCompletionCollection(taskRunner: task.runner, completion: item)

        return result
    }
}

class ImageTaskCompletionManager: TaskCompletionManager<ImageCompletionConverter> {
    static let shared = ImageTaskCompletionManager(urlSession: .imageCache, converter: .shared)
}

public class URLImageCache: GenericCache<URL, UIImage> {
    let imageTaskCompletionManager: ImageTaskCompletionManager
    init(imageTaskCompletionManager: ImageTaskCompletionManager) {
        self.imageTaskCompletionManager = imageTaskCompletionManager
    }
}

public extension URLImageCache {
    static let shared = URLImageCache(imageTaskCompletionManager: .shared)
}

public extension URLImageCache {
    func cachedImage(url: URL, _ block: @escaping (UIImage?) -> Void) -> DeinitBlock? {
        if let image = self[url] {
            block(image)
            return nil
        }
        return imageTaskCompletionManager.completionHolder(url) { [weak self] image, _, _, _ in
            self.map { cache in
                // in the meanwhile we might already have image in the cache so just keep it and discard the new one
                let realimage = cache[url] ?? image
                IfBlock.debug.yes {
                    if let image = image, realimage != image {
                        print("\(#file) \(#function) \(#line) IMAGE DISCARDED")
                    }
                }
                cache[url] = realimage
                block(realimage)
            }
        }
    }
}

public extension UIImageView {
    func setCachedImage(url: URL, imageCache: URLImageCache = .shared) -> DeinitBlock? {
        return imageCache.cachedImage(url: url) { [weak self] image in
            self?.image = image
        }
    }
}