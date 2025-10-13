//
//  PngText.swift
//  PngSwift
//
//  Created by Richard Perry on 6/28/24.
//

import Foundation

public class PngText: PngSection, Populatable {
    private(set) var dataValid: Bool = false
    
    public private(set) var keyword: String?
    public private(set) var textData: Data?
    
    override init(length: UInt32, chunkType: PngHeaderTypes, rawChunkType: String, chunkData: Data, CRC: UInt32, bitDepth: UInt8? = nil, colorType: UInt8? = nil) {
        super.init(length: length, chunkType: chunkType, rawChunkType: rawChunkType, chunkData: chunkData, CRC: CRC)
        populateFields(data: chunkData)
    }
    
    func populateFields(data: Data) {
        var dataLoc = 0
        var textName: [UInt8] = []
        // In tEXt data the keyword can be up to 79 characters long and is separated from the text by a null (0) byte
        for byte in data {
            if byte == 0 {
                break
            }
            if dataLoc >= 79 { return }
            dataLoc += 1
            textName.append(byte)
        }
        if dataLoc + 1 >= data.count { return }
        dataLoc += 1
        self.textData = data[dataLoc...]
        let data = Data(textName)
        guard let keyword = String(data: data, encoding: .utf8) else { return }
        self.keyword = keyword
        self.dataValid = true
    }
}
