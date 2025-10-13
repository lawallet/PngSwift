//
//  PngIhdr.swift
//  PngSwift
//
//  Created by Richard Perry on 10/3/25.
//

import Foundation

public class PngIhdr: PngSection, Populatable {
    private(set) var dataValid: Bool = false
    
    public private(set) var width: UInt32?
    public private(set) var height: UInt32?
    public private(set) var bitDepth: UInt8?
    public private(set) var colorType: UInt8?
    public private(set) var compressionMethod: UInt8?
    public private(set) var filterMethod: UInt8?
    public private(set) var interlaceMethod: UInt8?
    
    private let validBitDepths: Set<UInt8> = [1, 2, 4, 8, 16]
    private let validColorTypes: Set<UInt8> = [0, 2, 3, 4, 6]
    private let allowedBitDepthsForColorType: [UInt8: Set<UInt8>] = [
        0: [1, 2, 4, 8, 16],
        2: [8, 16],
        3: [1, 2, 4, 8],
        4: [8, 16],
        6: [8, 16]
    ]
    
    override init(length: UInt32, chunkType: PngHeaderTypes, rawChunkType: String, chunkData: Data, CRC: UInt32, bitDepth: UInt8? = nil, colorType: UInt8? = nil) {
        
        super.init(length: length, chunkType: chunkType, rawChunkType: rawChunkType, chunkData: chunkData, CRC: CRC)
        populateFields(data: chunkData)
    }
    
    func populateFields(data: Data) {
        if data.count != 13 {
            return
        }
        let widthData = data.subdata(in: 0..<4)
        widthData.withUnsafeBytes {widthBytes in
            self.width = widthBytes.load(as: UInt32.self).bigEndian
        }
        let heightData = data.subdata(in: 4..<8)
        heightData.withUnsafeBytes {heightBytes in
            self.height = heightBytes.load(as: UInt32.self).bigEndian
        }
        
        self.bitDepth = data[8]
        self.colorType = data[9]
        self.compressionMethod = data[10]
        self.filterMethod = data[11]
        self.interlaceMethod = data[12]
        self.dataValid = true
    }
//    convenience init?(data: Data) {
//        if data.count != 13 {
//            return nil
//        }
//        var width: UInt32 = 0
//        let widthData = data.subdata(in: 0..<4)
//        widthData.withUnsafeBytes {widthBytes in
//            width = widthBytes.load(as: UInt32.self).bigEndian
//        }
//        var height: UInt32 = 0
//        let heightData = data.subdata(in: 4..<8)
//        heightData.withUnsafeBytes {heightBytes in
//            height = heightBytes.load(as: UInt32.self).bigEndian
//        }
//        
//        var bitDepth: UInt8 = data[8]
//        var colorType: UInt8 = data[9]
//        var compressionMethod: UInt8 = data[10]
//        var filterMethod: UInt8 = data[11]
//        var interlaceMethod: UInt8 = data[12]
//        self.init(width: width, height: height, bitDepth: bitDepth, colorType: colorType, compressionMethod: compressionMethod, filterMethod: filterMethod, interlaceMethod: interlaceMethod)
//    }
    
    func isValid() -> Bool {
        guard let bitDepth = bitDepth else { return false }
        guard let colorType = colorType else { return false }
        if !validBitDepths.contains(bitDepth) { return false }
        if !validColorTypes.contains(colorType) { return false }
        guard let allowedBitDepths = allowedBitDepthsForColorType[colorType] else { return false }
        if !allowedBitDepths.contains(bitDepth) { return false }
        return true
    }
}
