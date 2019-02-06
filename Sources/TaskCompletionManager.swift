import Foundation
import RHBFoundation

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

open class TaskCompletionManager<T> {
    typealias ConvertBlockType = (@escaping (T?, Data?, URLResponse?, Error?) -> Void) -> ((Data?, URLResponse?, Error?) -> Void)
    let session: URLSession
    let convertBlock: ConvertBlockType
    init(urlSession: URLSession, convertBlock: @escaping ConvertBlockType) {
        self.session = urlSession
        self.convertBlock = convertBlock
    }
    var tasks: [URL: TaskCompletionCollection<T>] = [:]
}

public extension TaskCompletionManager {
    func managedTask(_ url: URL, _ block: @escaping (T?, Data?, URLResponse?, Error?) -> Void) -> DeinitBlock {
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


        let completionHandler = convertBlock { [weak self] object, data, response, error in
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
