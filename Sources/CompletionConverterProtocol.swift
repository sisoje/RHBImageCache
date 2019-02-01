import Foundation

protocol CompletionConverterProtocol {
    associatedtype C
    func convert(_ block: @escaping (C?, Data?, URLResponse?, Error?) -> Void) -> (Data?, URLResponse?, Error?) -> Void
}
