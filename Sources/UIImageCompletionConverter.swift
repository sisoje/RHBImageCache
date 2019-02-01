import UIKit

class UIImageCompletionConverter {}

extension UIImageCompletionConverter: CompletionConverterProtocol {
    func convert(_ block: @escaping (UIImage?, Data?, URLResponse?, Error?) -> Void) -> (Data?, URLResponse?, Error?) -> Void {
        return { data, response, error in
            let image: UIImage? = data.map { UIImage(data: $0) } ?? nil
            block(image, data, response, error)
        }
    }
}

extension UIImageCompletionConverter {
    static let shared = UIImageCompletionConverter()
}
