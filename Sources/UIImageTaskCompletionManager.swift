import UIKit

class UIImageTaskCompletionManager: TaskCompletionManager<UIImageCompletionConverter> {
    static let shared = UIImageTaskCompletionManager(urlSession: .imageCache, converter: .shared)
}
