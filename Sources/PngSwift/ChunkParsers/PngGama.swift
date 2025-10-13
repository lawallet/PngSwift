//
//  PngGama.swift
//  PngSwift
//
//  Created by Richard Perry on 10/4/25.
//

import Foundation

public class PngGama: PngSection, Populatable {
    private(set) var dataValid: Bool = false
    
    public private(set) var gamma: Double?
    
//    init(gamma: Double) {
//        self.gamma = gamma
//    }
    override init(length: UInt32, chunkType: PngHeaderTypes, rawChunkType: String, chunkData: Data, CRC: UInt32, bitDepth: UInt8? = nil, colorType: UInt8? = nil) {
        super.init(length: length, chunkType: chunkType, rawChunkType: rawChunkType, chunkData: chunkData, CRC: CRC)
        populateFields(data: chunkData)
    }
    func populateFields(data: Data) {
        var encodedGamma: UInt32 = 0
        data.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) in
            encodedGamma = rawBufferPointer.load(as: UInt32.self).bigEndian
        }
        self.gamma = Double(encodedGamma) / 100000.0
        self.dataValid = true
    }
}
