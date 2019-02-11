import Foundation
import RHBFoundation

public enum ErrorWithInfo<INFO>: Error {
    case errorWithInfo(Error, INFO)
    case messageWithInfo(String, INFO)
}

public typealias DataTaskCompletionBlock = (Data?, URLResponse?, Error?) -> Void
public typealias DataTaskData = (Data, URLResponse)
public typealias DataTaskInfo = (Data?, URLResponse?)
public typealias DataTaskError = ErrorWithInfo<DataTaskInfo>
public typealias DataTaskResult = Result<DataTaskData, DataTaskError>

public extension DataTaskResult {
    init(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
        if let error = error {
            self = .failure(.errorWithInfo(error, DataTaskInfo(data, response)))
            return
        }
        if let data = data, let response = response {
            self = .success(DataTaskData(data, response))
            return
        }
        self = .failure(.messageWithInfo("no data or no response", DataTaskInfo(data, response)))
    }

    static func dataTaskCompletionBlock(_ block: @escaping (DataTaskResult)->Void) -> DataTaskCompletionBlock {
        return { data, response, error in
            block(DataTaskResult(data, response, error))
        }
    }
}

public class TaskCompletion<RESULT>: NSObject {
    let completion: (RESULT) -> Void
    init(block: @escaping (RESULT) -> Void) {
        self.completion = block
    }
}

public extension TaskCompletion {
    func finish(_ result: RESULT) {
        completion(result)
    }
}

class TaskCompletionCollection<RESULT> {
    var completions = Set<TaskCompletion<RESULT>>()
    let taskRunner: DeinitBlock
    init(taskRunner: DeinitBlock, completion: TaskCompletion<RESULT>) {
        self.taskRunner = taskRunner
        completions.insert(completion)
    }
}

extension TaskCompletionCollection {
    func finish(_ result: RESULT) {
        completions.forEach { $0.finish(result) }
    }

    func add(_ item: TaskCompletion<RESULT>) {
        completions.insert(item)
    }

    func remove(_ item: TaskCompletion<RESULT>) {
        completions.remove(item)
    }

    var isEmpty: Bool {
        return completions.isEmpty
    }
}

open class TaskCompletionManager<K: Hashable, T> {
    public typealias RESULT = Result<T, DataTaskError>
    let taskRunner: (K, @escaping DataTaskCompletionBlock) -> DeinitBlock
    let dataMapper: (DataTaskData) -> RESULT
    public init(dataMapper: @escaping (DataTaskData) -> RESULT, taskRunner: @escaping (K, @escaping DataTaskCompletionBlock) -> DeinitBlock) {
        self.taskRunner = taskRunner
        self.dataMapper = dataMapper
    }
    var taskCollections: [K: TaskCompletionCollection<RESULT>] = [:]
}

public extension TaskCompletionManager {
    func removeTask(_ key: K, _ task: TaskCompletion<RESULT>) {
        taskCollections[key].map {
            $0.remove(task)
            if $0.isEmpty {
               taskCollections.removeValue(forKey: key)
            }
        }
    }

    func finishTasks(_ key: K, _ result: RESULT) {
        taskCollections[key]?.finish(result)
        taskCollections.removeValue(forKey: key)
    }
}

public extension TaskCompletionManager {
    func managedTask(_ key: K, _ block: @escaping (RESULT) -> Void) -> DeinitBlock {
        let item = TaskCompletion(block: block)
        let result = DeinitBlock { [weak self] in
            self?.removeTask(key, item)
        }

        if let collection = taskCollections[key] {
            collection.add(item)
            return result
        }

        let completionHandler = DataTaskResult.dataTaskCompletionBlock { [weak self] dataTaskResult in
            let result = self.map { dataTaskResult.flatMap($0.dataMapper) }
            result.map { result in
                DispatchQueue.main.async {
                    self?.finishTasks(key, result)
                }
            }
        }

        taskCollections[key] = TaskCompletionCollection(taskRunner: taskRunner(key, completionHandler), completion: item)

        return result
    }
}
