//
//  PngZtxt.swift
//  PngSwift
//
//  Created by Richard Perry on 10/4/25.
//

import Foundation

public class PngZtxt: PngSection, Populatable {
    private(set) var dataValid: Bool = false
    
    public private(set) var profileName: String?
    public private(set) var compressionMethod: UInt8?
    public private(set) var compressedText: Data?
    
    override init(length: UInt32, chunkType: PngHeaderTypes, rawChunkType: String, chunkData: Data, CRC: UInt32, bitDepth: UInt8? = nil, colorType: UInt8? = nil) {
        super.init(length: length, chunkType: chunkType, rawChunkType: rawChunkType, chunkData: chunkData, CRC: CRC)
        populateFields(data: chunkData)
    }
    
    func populateFields(data: Data) {
        
        var nameEnd = 0
        var nameArray: [UInt8] = []
        for byte in data {
            // Is character in latin set
            if byte == 0 {
                break
            }
            if (byte >= 33 && byte <= 126) || (byte >= 161 && byte <= 255) || byte == 32 {
                if nameEnd == 79 {
                    return
                }
                
                if nameEnd == 0 && byte == 32 {
                    // No leading spaces allowed
                    return
                } else {
                    nameArray.append(byte)
                }
                nameEnd += 1
            }
        }
        if nameArray.count == 0 {
            return
        }
        guard let profileName = String(bytes: nameArray, encoding: .isoLatin1) else { return }
        self.profileName = profileName
        if nameEnd == data.count {
            return
        }
        let compressionMethodData = data[nameEnd+1..<nameEnd+2]
        compressionMethodData.withUnsafeBytes { pointer in
            self.compressionMethod = pointer.load(as: UInt8.self)
        }
        let restOfData = nameEnd + 2
        if (restOfData > data.count) { return }
        self.compressedText = data[restOfData...]
        self.dataValid = true
    }
}
