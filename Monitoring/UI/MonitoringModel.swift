//
//  MonitoringModel.swift
//  Monitoring
//
//  Created by Чаусов Николай on 18.11.2022.
//

import Foundation

final class MonitoringModel: ObservableObject {
    @Published var allStorage = ""
    @Published var freeStorage = ""
    @Published var totalRamValue = ""
    @Published var cores = ""
    @Published var activeCores = ""
    @Published var lastRestartTime = ""
    @Published var thermalState = ""
 
    func getStorage() {
        guard
            let totalSpaceInBytes = FileManagerUility.getFileSize(for: .systemSize),
            let freeSpaceInBytes = FileManagerUility.getFileSize(for: .systemFreeSize)
        else {
            return
        }
        let totalSpace = Measurement(value: totalSpaceInBytes, unit: UnitInformationStorage.bytes)
        let freeSpace = Measurement(value: freeSpaceInBytes, unit: UnitInformationStorage.bytes)
        
        allStorage = totalSpace.converted(to: .gigabytes).formatted()
        freeStorage = freeSpace.converted(to: .gigabytes).formatted()
        
        getRamValue()
        getCoreInfo()
        getSystemInfo()
        getThermalInfo()
    }
    
    func getRamValue() {
        totalRamValue = ProcessInfo.processInfo.physicalMemory.formatted()
    }
    
    func getCoreInfo() {
        cores = ProcessInfo.processInfo.processorCount.formatted()
        activeCores = ProcessInfo.processInfo.activeProcessorCount.formatted()
    }
    
    func getSystemInfo() {
        lastRestartTime = ProcessInfo.processInfo.systemUptime.formatted()
    }
    
    func getThermalInfo() {
        thermalState = ProcessInfo.processInfo.thermalState.rawValue.formatted()
    }
}

struct FileManagerUility {
    
    static func getFileSize(for key: FileAttributeKey) -> Double? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)

        guard
            let lastPath = paths.last,
            let attributeDictionary = try? FileManager.default.attributesOfFileSystem(forPath: lastPath)
        else {
            return nil
        }

        if let size = attributeDictionary[key] as? NSNumber {
            return size.doubleValue
        } else {
            return nil
        }
    }
}
