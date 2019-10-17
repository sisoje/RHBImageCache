import UIKit
import RHBFoundation

public class URLImageSharedTaskManager: SharedTaskManager<URL, Result<UIImage, Error>> {
    public init(session: URLSession = .shared) {
        super.init()
        self.createTask = { url, completion in
            let task = session.dataTask(with: url) { data, _, error in
                completion(Result {
                    try error.map { throw $0 }
                    let image = data.flatMap { UIImage(data: $0) }
                    return try image.unwrap()
                })
            }
            task.resume()
            return DeinitBlock { [weak task] in
                task?.cancel()
            }
        }
    }
}
