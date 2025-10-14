import XCTest
@testable import PngSwift

final class PngSwiftTests: XCTestCase {
    let filename = "Coding_Sensei"
    
    func testLoad() throws {
        let pngFile = Bundle.module.url(forResource: filename, withExtension: "png")
        XCTAssertNotNil(pngFile)
        let pngInfo = try? PngInformation(pngPath: pngFile!)
        XCTAssertNotNil(pngInfo)
    }
    
    func testPopulateAllSections() throws {
        let pngFile = Bundle.module.url(forResource: filename, withExtension: "png")
        XCTAssertNotNil(pngFile)
        let pngInfo = try? PngInformation(pngPath: pngFile!)
        XCTAssertNotNil(pngInfo)
        try? pngInfo?.populateAllSections()
        XCTAssertNotNil(pngInfo?.sections?.ihdrChunk)
    }
    
    func testCreatePngDataPopulated() throws {
        let pngFile = Bundle.module.url(forResource: filename, withExtension: "png")
        XCTAssertNotNil(pngFile)
        let pngInfo = try? PngInformation(pngPath: pngFile!)
        XCTAssertNotNil(pngInfo)
        try? pngInfo?.populateAllSections()
        XCTAssertNotNil(pngInfo?.sections?.ihdrChunk)
        let pngData = try? pngInfo?.createPngData()
        XCTAssertNotNil(pngData)
    }
    
    func testCreatePngDataNotPopulated() throws {
        let pngFile = Bundle.module.url(forResource: filename, withExtension: "png")
        XCTAssertNotNil(pngFile)
        let pngInfo = try? PngInformation(pngPath: pngFile!)
        XCTAssertNotNil(pngInfo)
        let pngData = try? pngInfo?.createPngData()
        XCTAssertNotNil(pngData)
    }
}
