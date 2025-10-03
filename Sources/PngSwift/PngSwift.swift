// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
public struct PngSwift {
    public init() {}
    
    public static func getPngInformation(location url: URL) throws(PngLoadingError) -> PngInformation {
        return try PngInformation(pngPath: url)
    }
}
