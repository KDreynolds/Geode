//
//  GDALWrapper.swift
//  Geode
//
//  Created by Kyle Reynolds on 2/7/24.
//

import Foundation

enum GDALDatasetWrapperError: Error {
    case datasetOpenFailed(String)
    case bandReadFailed(String)
    case invalidBand(String)
    case writeFailed(String)
    case statisticsComputationFailed(String)
    case metadataOperationFailed(String)
    case gdalError(GDALErr, String)

    var localizedDescription: String {
        switch self {
        case .datasetOpenFailed(let message):
            return "Failed to open dataset: \(message)"
        case .bandReadFailed(let message):
            return "Failed to read band data: \(message)"
        case .invalidBand(let message):
            return "Invalid band specified: \(message)"
        case .writeFailed(let message):
            return "Failed to write data: \(message)"
        case .statisticsComputationFailed(let message):
            return "Failed to compute statistics: \(message)"
        case .metadataOperationFailed(let message):
            return "Metadata operation failed: \(message)"
        case .gdalError(let error, let message):
            return "GDAL error \(error): \(message)"
        }
    }
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

    func reprojectDataset(to projection: String) throws {
        guard let sourceDataset = self.dataset else {
            throw GDALDatasetWrapperError.datasetOpenFailed
        }
        
        // Fetch the original projection
        guard let sourceProjection = GDALGetProjectionRef(sourceDataset) else {
            throw GDALDatasetWrapperError.metadataOperationFailed
        }
        
        // Create a spatial reference object for the source and destination
        let sourceSRS = OSRNewSpatialReference(sourceProjection)
        let destinationSRS = OSRNewSpatialReference(nil)
        
        // Import the destination projection
        guard OGRErrNone == OSRImportFromProj4(destinationSRS, projection) else {
            OSRDestroySpatialReference(sourceSRS)
            OSRDestroySpatialReference(destinationSRS)
            throw GDALDatasetWrapperError.metadataOperationFailed
        }
        
        // Create a transformation object
        guard let transform = OCTNewCoordinateTransformation(sourceSRS, destinationSRS) else {
            OSRDestroySpatialReference(sourceSRS)
            OSRDestroySpatialReference(destinationSRS)
            throw GDALDatasetWrapperError.metadataOperationFailed
        }
        
        // Determine the destination geotransform and size
        var destinationGeoTransform = [Double](repeating: 0, count: 6)
        var destinationXSize: Int = 0
        var destinationYSize: Int = 0
        // Logic to compute destinationGeoTransform, destinationXSize, and destinationYSize goes here
        
        // Create a memory driver (for demonstration, you might want to use a file driver)
        guard let driver = GDALGetDriverByName("MEM") else {
            OCTDestroyCoordinateTransformation(transform)
            OSRDestroySpatialReference(sourceSRS)
            OSRDestroySpatialReference(destinationSRS)
            throw GDALDatasetWrapperError.metadataOperationFailed
        }
        
        // Create the destination dataset
        guard let destinationDataset = GDALCreate(driver, "", destinationXSize, destinationYSize, 0, GDT_Unknown, nil) else {
            OCTDestroyCoordinateTransformation(transform)
            OSRDestroySpatialReference(sourceSRS)
            OSRDestroySpatialReference(destinationSRS)
            throw GDALDatasetWrapperError.datasetOpenFailed
        }
        
        // Set the projection on the destination dataset
        GDALSetProjection(destinationDataset, projection)
        GDALSetGeoTransform(destinationDataset, &destinationGeoTransform)
        
        // Perform the reprojection
        let warpOptions = GDALWarpAppOptionsNew(nil, nil)
        let warpError = GDALReprojectImage(sourceDataset, sourceProjection, destinationDataset, projection, GRA_NearestNeighbour, 0, 0.1, nil, nil, warpOptions)
        GDALWarpAppOptionsFree(warpOptions)
        
        if warpError != CE_None {
            GDALClose(destinationDataset)
            OCTDestroyCoordinateTransformation(transform)
            OSRDestroySpatialReference(sourceSRS)
            OSRDestroySpatialReference(destinationSRS)
            throw GDALDatasetWrapperError.gdalError(warpError)
        }
        
        // Cleanup
        GDALClose(destinationDataset)
        OCTDestroyCoordinateTransformation(transform)
        OSRDestroySpatialReference(sourceSRS)
        OSRDestroySpatialReference(destinationSRS)
        
        // Note: This example creates a new dataset in memory. You might want to modify it to write to a file or handle the dataset differently.
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