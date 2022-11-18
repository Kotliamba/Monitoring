//
//  MonitoringModel.swift
//  Monitoring
//
//  Created by Чаусов Николай on 18.11.2022.
//

import Foundation
import Combine

final class MonitoringModel: ObservableObject {
    
    private enum Constants {
        
        static let dot = "."
    }
    
    @Published var allStorage = ""
    @Published var freeStorage = ""
    @Published var totalRamValue = ""
    @Published var cores = ""
    @Published var activeCores = ""
    @Published var lastRestartTime = ""
    @Published var thermalState = ""
    @Published var iOSVersion = ""
    @Published var build = ""
    @Published var processId = ""
    @Published var processName = ""
    @Published var cpu = ""
    
    var throttleValue = 0.5
    private var cancellable: AnyCancellable?
    
    func getData() {
        if (cancellable != nil) {
            cancellable = nil
        } else {
            cancellable = Timer
                .publish(every: 0.5, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.updateData()
                }
        }
    }
    
    func updateData() {
        getStorage()
        getRamValue()
        getCoreInfo()
        getSystemInfo()
        getThermalInfo()
        getSystemVersion()
        getProcessInfo()
        getCPUInfo()
    }
    
    func stopUpdating() {
        cancellable?.cancel()
    }
    
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
    }
    
    func getRamValue() {
        var totalRam = Measurement(value: Double(ProcessInfo.processInfo.physicalMemory), unit: UnitInformationStorage.bytes)
        
        totalRam.convert(to: .gigabytes)
        totalRamValue = totalRam.formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(1))))
    }
    
    func getCoreInfo() {
        cores = ProcessInfo.processInfo.processorCount.formatted()
        activeCores = ProcessInfo.processInfo.activeProcessorCount.formatted()
    }
    
    func getSystemInfo() {
        let restartInterval = ProcessInfo.processInfo.systemUptime
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        
        guard let lastRestartTime = formatter.string(from: restartInterval) else {
            return
        }
        self.lastRestartTime = lastRestartTime
    }
    
    func getThermalInfo() {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal:
            thermalState = "Normal"
        case .fair:
            thermalState = "Heat"
        case .serious:
            thermalState = "Hot"
        case .critical:
            thermalState = "Critical"
        @unknown default:
            thermalState = "No info"
        }
    }
    
    func getSystemVersion() {
        let major = ProcessInfo.processInfo.operatingSystemVersion.majorVersion.description
        let minor = ProcessInfo.processInfo.operatingSystemVersion.minorVersion.description
        let path = ProcessInfo.processInfo.operatingSystemVersion.patchVersion.description
        
        iOSVersion = major + Constants.dot + minor + Constants.dot + path
        build = ProcessInfo.processInfo.operatingSystemVersionString
    }
    
    func getProcessInfo() {
        processId = ProcessInfo.processInfo.processIdentifier.description
        processName = ProcessInfo.processInfo.processName
    }
    
    func getCPUInfo() {
        cpu = cpuUsage().description
    }
    
    private func cpuUsage() -> Double {
        // Сложный код был украден отсюда
        // https://stackoverflow.com/questions/8223348/ios-get-cpu-usage-from-application
        var kr: kern_return_t
        var task_info_count: mach_msg_type_number_t

        task_info_count = mach_msg_type_number_t(TASK_INFO_MAX)
        var tinfo = [integer_t](repeating: 0, count: Int(task_info_count))

        kr = task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), &tinfo, &task_info_count)
        if kr != KERN_SUCCESS {
            return -1
        }

        var thread_list: thread_act_array_t? = UnsafeMutablePointer(mutating: [thread_act_t]())
        var thread_count: mach_msg_type_number_t = 0
        defer {
            if let thread_list = thread_list {
                vm_deallocate(mach_task_self_, vm_address_t(UnsafePointer(thread_list).pointee), vm_size_t(thread_count))
            }
        }

        kr = task_threads(mach_task_self_, &thread_list, &thread_count)

        if kr != KERN_SUCCESS {
            return -1
        }

        var tot_cpu: Double = 0

        if let thread_list = thread_list {

            for j in 0 ..< Int(thread_count) {
                var thread_info_count = mach_msg_type_number_t(THREAD_INFO_MAX)
                var thinfo = [integer_t](repeating: 0, count: Int(thread_info_count))
                kr = thread_info(thread_list[j], thread_flavor_t(THREAD_BASIC_INFO),
                                 &thinfo, &thread_info_count)
                if kr != KERN_SUCCESS {
                    return -1
                }

                let threadBasicInfo = convertThreadInfoToThreadBasicInfo(thinfo)

                if threadBasicInfo.flags != TH_FLAGS_IDLE {
                    tot_cpu += (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE)) * 100.0
                }
            } // for each thread
        }

        return tot_cpu
    }

    private func convertThreadInfoToThreadBasicInfo(_ threadInfo: [integer_t]) -> thread_basic_info {
        var result = thread_basic_info()

        result.user_time = time_value_t(seconds: threadInfo[0], microseconds: threadInfo[1])
        result.system_time = time_value_t(seconds: threadInfo[2], microseconds: threadInfo[3])
        result.cpu_usage = threadInfo[4]
        result.policy = threadInfo[5]
        result.run_state = threadInfo[6]
        result.flags = threadInfo[7]
        result.suspend_count = threadInfo[8]
        result.sleep_time = threadInfo[9]

        return result
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
