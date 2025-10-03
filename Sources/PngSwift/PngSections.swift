//
//  PngSections.swift
//  PngSwift
//
//  Created by Richard Perry on 10/2/25.
//

import Foundation

public class PngSections {
    public private(set) var ihdrChunk: PngSection?
    public private(set) var idatChunk: [PngSection]?
    public private(set) var iendChunk: PngSection?
    public private(set) var plteChunk: PngSection?
    public private(set) var chrmChunk: PngSection?
    public private(set) var gamaChunk: PngSection?
    public private(set) var iccpChunk: PngSection?
    public private(set) var sbitChunk: PngSection?
    public private(set) var srgbChunk: PngSection?
    public private(set) var bkgdChunk: PngSection?
    public private(set) var histChunk: PngSection?
    public private(set) var trnsChunk: PngSection?
    public private(set) var physChunk: PngSection?
    public private(set) var spltChunk: [PngSection]?
    public private(set) var timeChunk: PngSection?
    public private(set) var itxtChunk: [PngSection]?
    public private(set) var textChunk: [PngSection]?
    public private(set) var ztxtChunk: [PngSection]?
    public private(set) var nonstandardChunks: [String: PngSection] = [:]
    
    func createData(for sectionType: PngHeaderTypes, unknownName: String = "") -> Data? {
        switch sectionType {
            
        case .IHDR:
            return ihdrChunk?.createData()
        case .PLTE:
            return plteChunk?.createData()
        case .IDAT:
            if let idatChunk = idatChunk {
                return idatChunk.reduce(Data()) { (result, chunk) -> Data in
                    result + chunk.createData()
                }
            } else {
                return nil
            }
            
        case .IEND:
            return iendChunk?.createData()
        case .cHRM:
            return chrmChunk?.createData()
        case .gAMA:
            return gamaChunk?.createData()
        case .iCCP:
            return iccpChunk?.createData()
        case .sBIT:
            return sbitChunk?.createData()
        case .sRGB:
            return srgbChunk?.createData()
        case .bKGD:
            return bkgdChunk?.createData()
        case .hIST:
            return histChunk?.createData()
        case .tRNS:
            return trnsChunk?.createData()
        case .pHYs:
            return physChunk?.createData()
        case .sPLT:
            return spltChunk?.reduce(Data()) { (result, chunk) -> Data in
                result + chunk.createData()
            }
        case .tIME:
            return timeChunk?.createData()
        case .iTXt:
            return itxtChunk?.reduce(Data()) { (result, chunk) -> Data in
                result + chunk.createData()
            }
        case .tEXt:
            return textChunk?.reduce(Data()) { (result, chunk) -> Data in
                result + chunk.createData()
            }
        case .zTXt:
            return ztxtChunk?.reduce(Data()) { (result, chunk) -> Data in
                result + chunk.createData()
            }
        case .unknown:
            if let unknownSection = nonstandardChunks[unknownName] {
                return unknownSection.createData()
            }
            return nil
        }
    }
    
    func isPopulated(sectionType: PngHeaderTypes, unknownSection: String = "") -> Bool {
        switch sectionType {
        
        case .IHDR:
            return ihdrChunk != nil
        case .PLTE:
            return plteChunk != nil
        case .IDAT:
            return idatChunk != nil
        case .IEND:
            return iendChunk != nil
        case .cHRM:
            return chrmChunk != nil
        case .gAMA:
            return gamaChunk != nil
        case .iCCP:
            return iccpChunk != nil
        case .sBIT:
            return sbitChunk != nil
        case .sRGB:
            return srgbChunk != nil
        case .bKGD:
            return bkgdChunk != nil
        case .hIST:
            return histChunk != nil
        case .tRNS:
            return trnsChunk != nil
        case .pHYs:
            return physChunk != nil
        case .sPLT:
            return spltChunk != nil
        case .tIME:
            return timeChunk != nil
        case .iTXt:
            return itxtChunk != nil
        case .tEXt:
            return textChunk != nil
        case .zTXt:
            return ztxtChunk != nil
        case .unknown:
            if unknownSection.isEmpty {
                return false
            } else {
                return nonstandardChunks[unknownSection] != nil
            }
        }
    }
    
    func setSection(sectionType: PngHeaderTypes, nonStandardSectionName: String = "", sectionData:[PngSection]) {
        switch sectionType {
            
        case .IHDR:
            ihdrChunk = sectionData.first
        case .PLTE:
            plteChunk = sectionData.first
        case .IDAT:
            idatChunk = sectionData
        case .IEND:
            iendChunk = sectionData.first
        case .cHRM:
            chrmChunk = sectionData.first
        case .gAMA:
            gamaChunk = sectionData.first
        case .iCCP:
            iccpChunk = sectionData.first
        case .sBIT:
            sbitChunk = sectionData.first
        case .sRGB:
            srgbChunk = sectionData.first
        case .bKGD:
            bkgdChunk = sectionData.first
        case .hIST:
            histChunk = sectionData.first
        case .tRNS:
            trnsChunk = sectionData.first
        case .pHYs:
            physChunk = sectionData.first
        case .sPLT:
            spltChunk = sectionData
        case .tIME:
            timeChunk = sectionData.first
        case .iTXt:
            itxtChunk = sectionData
        case .tEXt:
            textChunk = sectionData
        case .zTXt:
            ztxtChunk = sectionData
        case .unknown:
            if !nonStandardSectionName.isEmpty {
                nonstandardChunks[nonStandardSectionName] = sectionData.first
            }
        }
    }
}
