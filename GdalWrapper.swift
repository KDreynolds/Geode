//
//  GDALWrapper.swift
//  Geode
//
//  Created by Kyle Reynolds on 2/7/24.
//

import Foundation

class GDALDatasetWrapper {
    private var dataset: OpaquePointer?

    init?(path: String) {
        GDALAllRegister()
        dataset = GDALOpen(path, GA_ReadOnly)
        if dataset == nil {
            return nil
        }
    }

    deinit {
        if dataset != nil {
            GDALClose(dataset)
        }
    }

    func readRasterData(band: Int) -> [Float]? {
        guard let info = getRasterBandInfo(band: band) else {
            return nil
        }
        var buffer = [Float](repeating: 0, count: Int(info.xSize * info.ySize))
        if GDALRasterIO(GDALGetRasterBand(dataset, Int32(band)), GF_Read, 0, 0, info.xSize, info.ySize, &buffer, info.xSize, info.ySize, GDT_Float32, 0, 0) == CE_None {
            return buffer
        } else {
            return nil
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
}
