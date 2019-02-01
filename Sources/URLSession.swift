import Foundation

extension URLSession {
    static let imageCache: URLSession = {
        let config: URLSessionConfiguration = .default
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()
}
