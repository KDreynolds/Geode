//
//  GDALWrapper.swift
//  Geode
//
//  Created by Kyle Reynolds on 3/26/24.
//

import Foundation

#if BUILD_WRAPPER

enum GDALDatasetWrapperError: Error {
    case datasetOpenFailed
    case bandReadFailed
    case invalidBand
    case gdalError(CPLErr)
}

class GDALDatasetWrapper {
    private var dataset: GDALDatasetH?

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

    func readRasterData(band: Int) throws -> [Float] {
        guard let gdalBand = GDALGetRasterBand(dataset, Int32(band)) else {
            throw GDALDatasetWrapperError.invalidBand
        }
        
        let xSize = GDALGetRasterBandXSize(gdalBand)
        let ySize = GDALGetRasterBandYSize(gdalBand)
        
        var buffer = [Float](repeating: 0, count: Int(xSize * ySize))
        let readResult = GDALRasterIO(gdalBand, GF_Read, 0, 0, xSize, ySize, &buffer, xSize, ySize, GDT_Float32, 0, 0)
        
        if readResult == CE_None {
            return buffer
        } else {
            throw GDALDatasetWrapperError.gdalError(readResult)
        }
    }
}

#endif
