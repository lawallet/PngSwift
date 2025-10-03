import XCTest
@testable import PngSwift

final class PngSwiftTests: XCTestCase {
    func testLoad() throws {
        let pngFile = Bundle.module.url(forResource: "Coding_Sensei", withExtension: "png")
        XCTAssertNotNil(pngFile)
        let pngInfo = try? PngInformation(pngPath: pngFile!)
        XCTAssertNotNil(pngInfo)
//        try? pngInfo?.populateAllSections()
//        XCTAssertNotNil(pngInfo?.sections?.ihdrChunk)
        let pngData = try? pngInfo?.createPngData()
        XCTAssertNotNil(pngData)
    }
    
    func testPopulateAllSections() throws {
        let pngFile = Bundle.module.url(forResource: "Coding_Sensei", withExtension: "png")
        XCTAssertNotNil(pngFile)
        let pngInfo = try? PngInformation(pngPath: pngFile!)
        XCTAssertNotNil(pngInfo)
        try? pngInfo?.populateAllSections()
        XCTAssertNotNil(pngInfo?.sections?.ihdrChunk)
    }
    
    func testCreatePngDataPopulated() throws {
        let pngFile = Bundle.module.url(forResource: "Coding_Sensei", withExtension: "png")
        XCTAssertNotNil(pngFile)
        let pngInfo = try? PngInformation(pngPath: pngFile!)
        XCTAssertNotNil(pngInfo)
        try? pngInfo?.populateAllSections()
        XCTAssertNotNil(pngInfo?.sections?.ihdrChunk)
        let pngData = try? pngInfo?.createPngData()
        XCTAssertNotNil(pngData)
    }
    
    func testCreatePngDataNotPopulated() throws {
        let pngFile = Bundle.module.url(forResource: "Coding_Sensei", withExtension: "png")
        XCTAssertNotNil(pngFile)
        let pngInfo = try? PngInformation(pngPath: pngFile!)
        XCTAssertNotNil(pngInfo)
        let pngData = try? pngInfo?.createPngData()
        XCTAssertNotNil(pngData)
    }
}
