import UIKit
import RHBFoundation

public class URLImageSharedTaskManager: SharedTaskManager<URL, Result<UIImage, Error>> {
    public init(session: URLSession = .returnCacheDataElseLoadSession) {
        super.init()
        self.createTask = { url, completion in
            let task = session.dataTask(with: url) {
                let result = Result($0, $2).railMap {
                    UIImage(data: $0)
                }
                completion(result)
            }
            return task.runner
        }
    }
}
