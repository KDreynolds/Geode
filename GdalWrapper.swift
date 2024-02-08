//
//  GDALWrapper.swift
//  Geode
//
//  Created by Kyle Reynolds on 2/7/24.
//

import Foundation

enum GDALDatasetWrapperError: Error {
    case datasetOpenFailed
    case bandReadFailed
    case invalidBand
    case writeFailed
    case statisticsComputationFailed
    case metadataOperationFailed
    case gdalError(GDALErr)
}

class GDALDatasetWrapper {
    private var dataset: OpaquePointer?

    init(path: String) throws {
        GDALAllRegister()
        dataset = GDALOpen(path, GA_ReadOnly)
        if dataset == nil {
            throw GDALDatasetWrapperError.datasetOpenFailed
        }
    }

    deinit {
        if dataset != nil {
            GDALClose(dataset)
        }
    }

    func readRasterData(bands: [Int]) throws -> [Int: [Float]] {
        var result: [Int: [Float]] = [:]
        for band in bands {
            guard let info = getRasterBandInfo(band: band) else {
                throw GDALDatasetWrapperError.invalidBand
            }
            var buffer = [Float](repeating: 0, count: Int(info.xSize * info.ySize))
            let readResult = GDALRasterIO(GDALGetRasterBand(dataset, Int32(band)), GF_Read, 0, 0, info.xSize, info.ySize, &buffer, info.xSize, info.ySize, GDT_Float32, 0, 0)
            if readResult == CE_None {
                result[band] = buffer
            } else {
                throw GDALDatasetWrapperError.gdalError(readResult)
            }
        }
        return result
    }

    func writeRasterData(band: Int, data: [Float], xSize: Int, ySize: Int) throws {
        guard let gdalBand = GDALGetRasterBand(dataset, Int32(band)) else {
            throw GDALDatasetWrapperError.invalidBand
        }
        let writeResult = GDALRasterIO(gdalBand, GF_Write, 0, 0, xSize, ySize, data, xSize, ySize, GDT_Float32, 0, 0)
        if writeResult != CE_None {
            throw GDALDatasetWrapperError.gdalError(writeResult)
        }
    }

    private func getRasterBandInfo(band: Int) -> (xSize: Int, ySize: Int, dataType: GDALDataType)? {
        guard let gdalBand = GDALGetRasterBand(dataset, Int32(band)) else {
            return nil
        }
        let xSize = GDALGetRasterBandXSize(gdalBand)
        let ySize = GDALGetRasterBandYSize(gdalBand)
        let dataType = GDALGetRasterDataType(gdalBand)

        return (Int(xSize), Int(ySize), dataType)
    }

    func getMetadata() -> [String: String]? {
        guard let metadataList = GDALGetMetadata(dataset, nil) else {
            return nil
        }
        var metadata = [String: String]()
        var index = 0
        while let entry = metadataList[index] {
            let string = String(cString: entry)
            let components = string.split(separator: "=").map(String.init)
            if components.count == 2 {
                metadata[components[0]] = components[1]
            }
            index += 1
        }
        return metadata
    }

    func setMetadata(_ metadata: [String: String]) throws {
        for (key, value) in metadata {
            let result = GDALSetMetadataItem(dataset, key, value, nil)
            if result != CE_None {
                throw GDALDatasetWrapperError.metadataOperationFailed
            }
        }
    }

    func getGeotransform() -> [Double]? {
        var transform = [Double](repeating: 0, count: 6)
        if GDALGetGeoTransform(dataset, &transform) == CE_None {
            return transform
        } else {
            return nil
        }
    }

    func setGeotransform(_ transform: [Double]) -> Bool {
        return GDALSetGeoTransform(dataset, transform) == CE_None
    }

    // Placeholder for spatial operations
    func reprojectDataset(to projection: String) throws {
        // Implement reprojection logic here
        // This is a conceptual placeholder
    }

    // Placeholder for computing statistics
    func computeStatistics(forBand band: Int) throws -> (min: Double, max: Double, mean: Double, stdDev: Double) {
        var min: Double = 0, max: Double = 0, mean: Double = 0, stdDev: Double = 0
        guard let gdalBand = GDALGetRasterBand(dataset, Int32(band)) else {
            throw GDALDatasetWrapperError.invalidBand
        }
        let result = GDALGetRasterStatistics(gdalBand, 0, 1, &min, &max, &mean, &stdDev)
        if result != CE_None {
            throw GDALDatasetWrapperError.gdalError(result)
        }
        return (min, max, mean, stdDev)
}
}