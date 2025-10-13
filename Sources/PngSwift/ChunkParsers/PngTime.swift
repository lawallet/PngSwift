//
//  PngTime.swift
//  PngSwift
//
//  Created by Richard Perry on 10/5/25.
//

import Foundation

public class PngTime: PngSection, Populatable {
    private(set) var dataValid: Bool = false
    
    public private(set) var year: UInt16?
    public private(set) var month: UInt8?
    public private(set) var day: UInt8?
    public private(set) var hour: UInt8?
    public private(set) var minute: UInt8?
    public private(set) var second: UInt8?
    
    override init(length: UInt32, chunkType: PngHeaderTypes, rawChunkType: String, chunkData: Data, CRC: UInt32, bitDepth: UInt8? = nil, colorType: UInt8? = nil) {
        super.init(length: length, chunkType: chunkType, rawChunkType: rawChunkType, chunkData: chunkData, CRC: CRC)
        populateFields(data: chunkData)
    }
    
    func populateFields(data: Data) {
        if data.count != 7 {
            return
        }
        let yearData = data[0..<2]
        yearData.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
            self.year = p.load(as: UInt16.self).bigEndian
        }
        let month = data[2]
        if month < 1 || month > 12 { return }
        self.month = month
        let day = data[3]
        if day < 1 || day > 31 { return }
        self.day = day
        let hour = data[4]
        if hour > 23 { return }
        self.hour = hour
        let minute = data[5]
        if minute > 59 { return }
        self.minute = minute
        let second = data[6]
        if second > 60 { return }
        self.second = second
        self.dataValid = true
    }
}
