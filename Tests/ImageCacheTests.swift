import RHBFoundation
import RHBImageCache
import XCTest
import RHBFoundationTestUtilities

extension URL {
    static let testImageUrl = URL.temporary.appendingPathComponent("0.png")
}

final class ImageCacheTests: XCTestCase {
    static override func setUp() {
        let rend = UIGraphicsImageRenderer(bounds: CGRect(origin: .zero, size: CGSize(width: 1, height: 1)), format: UIGraphicsImageRendererFormat() ~ { $0.scale = 1 })
        let image = rend.image(actions: {_ in})
        let data = image.pngData()!
        try! data.write(to: .testImageUrl)
    }

    func testLoad() {
        let imageManager = CachedTaskManager(taskManager: URLImageSharedTaskManager(session: .returnCacheDataElseLoadSession))
        var tasks: [Any?] =
            (0..<3).map { index in
                let ex = expectation(description: "\(index)\(#function)")
                return imageManager.cached(.testImageUrl) { result in
                    let image = try! result.get()
                    XCTAssert(image.size == CGSize(width: 1, height: 1))
                    ex.fulfill()
                }
        }
        waitForExpectations(timeout: 1, handler: nil)
        tasks.removeAll()
    }
}
