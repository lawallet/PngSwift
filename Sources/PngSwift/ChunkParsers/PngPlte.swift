//
//  PngPlte.swift
//  PngSwift
//
//  Created by Richard Perry on 10/4/25.
//

import Foundation

public struct PngPaletteEntry {
    public private(set) var red: UInt8
    public private(set) var green: UInt8
    public private(set) var blue: UInt8
}

public class PngPlte: PngSection, Populatable {
    private(set) var dataValid: Bool = false
    
    public private(set) var entries: [PngPaletteEntry]?
    
    override init(length: UInt32, chunkType: PngHeaderTypes, rawChunkType: String, chunkData: Data, CRC: UInt32, bitDepth: UInt8? = nil, colorType: UInt8? = nil) {
        super.init(length: length, chunkType: chunkType, rawChunkType: rawChunkType, chunkData: chunkData, CRC: CRC)
        populateFields(data: chunkData)
    }
    func populateFields(data: Data) {
        guard data.count % 3 == 0 else { return }
        
        self.entries = []
        
        for i in stride(from: 0, to: data.count, by: 3) {
            let red: UInt8 = data[data.index(data.startIndex, offsetBy: i)]
            let green: UInt8 = data[data.index(data.startIndex, offsetBy: i + 1)]
            let blue: UInt8 = data[data.index(data.startIndex, offsetBy: i + 2)]
            self.entries?.append(PngPaletteEntry(red: red, green: green, blue: blue))
        }
        
        self.dataValid = true
    }
}
