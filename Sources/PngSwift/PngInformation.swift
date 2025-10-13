//
//  PngInformation.swift
//  PngSwift
//
//  Created by Richard Perry on 10/2/25.
//

import Foundation

public struct PngSectionOffsetInfo {
    public internal(set) var offset: UInt64 = 0
    public internal(set) var type: String = ""
    public internal(set) var SectionLength: UInt32 = 0
}
public class PngInformation {
    public private(set) var sections: PngSections?
    public private(set) var sectionOffsets: PngSectionOffsets
    
    private var pngLocation: URL
    
    // IHDR chunk must be first
    // cHRM, gAMA, iCCP, sBIT, sRGB chunks must come before PLTE and IDAT chunks
    // bKGD, hIST, tRNS chunks must come after PLTE and before IDAT chunks
    // pHYs and sPLT chunks must come before IDAT chunks
    // tim and txt chunks can come after idat
    // IEND chunk must be last
    private let pngOrder: [Int: [PngHeaderTypes]] = [0: [.IHDR],
                                                     1: [.cHRM, .gAMA, .iCCP, .sBIT, .sRGB],
                                                     2: [.PLTE],
                                                     3: [.bKGD, .hIST, .tRNS],
                                                     4: [.pHYs, .sPLT],
                                                     5: [.IDAT],
                                                     6: [.tIME, .tEXt, .zTXt, .iTXt, .unknown],
                                                     7: [.IEND]]
    
    private let multipleAllowed: Set<PngHeaderTypes> = [.IDAT, .sPLT, .tEXt, .zTXt, .iTXt]
    private let needColorType: Set<PngHeaderTypes> = [.sBIT, .bKGD, .tRNS]
    
    init(pngPath: URL) throws(PngLoadingError) {
        sectionOffsets = try PngSectionOffsets(pngPath: pngPath)
        pngLocation = pngPath
    }
    
    public func populateAllSections() throws {
        if (sections == nil) {
            sections = PngSections()
        }
        let offsetMirror = Mirror(reflecting: sectionOffsets)
        for child in offsetMirror.children {
            if let unknownSections = child.value as? [String: PngSectionOffsetInfo] {
                for unknownName in unknownSections.keys {
                    let sectionArr = try sectionOffsets.populateDataForSection(type: .unknown, nonStandardChunkName: unknownName)
                    sections?.setSection(sectionType: sectionArr.first!.chunkType, nonStandardSectionName: unknownName, sectionData: sectionArr)
                }
            } else if let offsetInfo = child.value as? PngSectionOffsetInfo {
                try populateSection(for: offsetInfo)
            } else if let multiOffsetInfo = child.value as? [PngSectionOffsetInfo] {
                try populateMultipleSection(for: multiOffsetInfo)
            }
        }
    }
    
    public func populate(sectionType: PngHeaderTypes, unknownSectionName:String = "") throws {
        if (sections == nil) {
            sections = PngSections()
        }
        copyHeaderSectionIfNeeded(for: sectionType)
        let sectionInfo = try sectionOffsets.populateDataForSection(type: sectionType, nonStandardChunkName: unknownSectionName)
        if sectionType == .IHDR {
            sectionOffsets.headerSection = sectionInfo.first as? PngIhdr
        }
        sections?.setSection(sectionType: sectionType, nonStandardSectionName: unknownSectionName, sectionData: sectionInfo)
    }
    
    private func populateSection(for offset: PngSectionOffsetInfo, unknownSectionName:String = "") throws {
        
        let type = PngHeaderTypes(rawValue: offset.type) ?? .unknown
        copyHeaderSectionIfNeeded(for: type)
        let sectionArr = try sectionOffsets.populateDataForSection(type: type)
        sections?.setSection(sectionType: type, nonStandardSectionName: unknownSectionName, sectionData: sectionArr)
    }
    
    private func populateMultipleSection(for offsets: [PngSectionOffsetInfo]) throws {
        let firstOffsetInfo = offsets.first!
        let sectionType = PngHeaderTypes(rawValue: firstOffsetInfo.type) ?? .unknown
        let sectionArr = try sectionOffsets.populateDataForSection(type: sectionType)
        sections?.setSection(sectionType: sectionType, sectionData: sectionArr)
    }
    
    private func copyHeaderSectionIfNeeded(for type: PngHeaderTypes) {
        if needColorType.contains(type) {
            if sections?.isPopulated(sectionType: .IHDR) ?? false  == false{
                if let sectionInfo = try? sectionOffsets.populateDataForSection(type: .IHDR) {
                    sections?.setSection(sectionType: type, sectionData: sectionInfo)
                    sectionOffsets.headerSection = sectionInfo.first as? PngIhdr
                }
            } else if sectionOffsets.headerSection == nil {
                sectionOffsets.headerSection = sections?.ihdrChunk as? PngIhdr
            }
            
        }
    }
    func writePngToDisk(location: URL) throws(PngSavingError) {
        if sectionOffsets.nonstandardChunks.count > 0 {
            throw PngSavingError.containsUnknownChunks
        }
        let pngData = try createPngData()
        
        let writePath: String
        if #available(iOS 16.0, *) {
            writePath = location.path(percentEncoded: false)
        } else {
            writePath = location.path
        }
        
        let created = FileManager.default.createFile(atPath: writePath, contents: pngData)
        if !created {
            throw PngSavingError.failed
        }
    }
    
    func createPngData() throws(PngSavingError) -> Data {
        let pngHeader:[UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
        // Write PNG header first
        
        var pngData = Data(bytes: pngHeader, count: pngHeader.count)
        let priorityLevels = pngOrder.count
        for priorityLevel in 0..<priorityLevels {
            // Should always exist, but to avoid forced unwrapping
            guard let typesForLevel = pngOrder[priorityLevel] else { continue }
            for type in typesForLevel {
                guard let sectionData = try createSectionData(for: type) else { continue }
                pngData.append(contentsOf: sectionData)
            }
        }
        return pngData
    }
    
    private func createSectionData(for sectionType: PngHeaderTypes) throws(PngSavingError) -> Data? {
        if !sectionOffsets.haveOffset(for: sectionType) {
            return nil
        }
        if sections?.isPopulated(sectionType: sectionType) ?? false {
            return sections?.createData(for: sectionType)
        }
        return try createSection(from: sectionType)
    }
    
    private func createSection(from sectionType: PngHeaderTypes) throws(PngSavingError) -> Data? {
        
        do {
            let sectionArr = try sectionOffsets.populateDataForSection(type: sectionType)
            var sectionData = Data()
            for section in sectionArr {
                sectionData.append(contentsOf: section.createData())
            }
            return sectionData
        } catch PngPopulatingError.dataDoesNotMatchOriginalData {
            // Can't pull data throw
            throw PngSavingError.dataDifferent
        } catch {
            return nil
        }
    }
    
}
