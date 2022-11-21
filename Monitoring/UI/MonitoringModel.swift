//
//  MonitoringModel.swift
//  Monitoring
//
//  Created by Чаусов Николай on 18.11.2022.
//

import Combine
import UIKit

final class MonitoringModel: ObservableObject {
    
    private enum Constants {
        
        static let dot = "."
        static let percent = " %"
        static let publishDelay = 0.5
    }
    
    @Published var allStorage = ""
    @Published var freeStorage = ""
    @Published var totalRamValue = ""
    @Published var usedRamValue = ""
    @Published var cores = ""
    @Published var activeCores = ""
    @Published var lastRestartTime = ""
    @Published var thermalState = ""
    @Published var iOSVersion = ""
    @Published var userName = ""
    @Published var modelName = ""
    @Published var brightness = ""
    @Published var build = ""
    @Published var processId = ""
    @Published var processName = ""
    @Published var cpu = ""
    @Published var batteryLevel = ""
    @Published var batteryState = ""
    @Published var isLowPowerEnabled = ""
    
    private var cancellable: AnyCancellable?
    private var formatter = MeasurementFormatter()
    
    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        setupFormatter()
        updateData()
    }
    
    func enablePublishing() {
        setupPublisher()
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
        getBatteryInfo()
        getScreenBrightness()
    }
    
    func stopUpdating() {
        cancellable?.cancel()
    }
    
    private func getStorage() {
        guard
            let totalSpaceInBytes = FileManagerUility.getFileSize(for: .systemSize),
            let freeSpaceInBytes = FileManagerUility.getFileSize(for: .systemFreeSize)
        else {
            return
        }
        let totalSpace = Measurement(value: totalSpaceInBytes, unit: UnitInformationStorage.bytes).converted(to: .gigabytes)
        let freeSpace = Measurement(value: freeSpaceInBytes, unit: UnitInformationStorage.bytes).converted(to: .gigabytes)

        allStorage = formatter.string(from: totalSpace)
        freeStorage = formatter.string(from: freeSpace)
    }
    
    private func getRamValue() {
        let totalRam = Measurement(
            value: Double(ProcessInfo.processInfo.physicalMemory),
            unit: UnitInformationStorage.bytes
        ).converted(to: .gigabytes)
        
        totalRamValue = formatter.string(from: totalRam)
        
        getUsedRam()
    }
    
    private func getUsedRam() {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let used = Measurement(value: Double(taskInfo.phys_footprint), unit: UnitInformationStorage.bytes).converted(to: .megabytes)
            usedRamValue = formatter.string(from: used)
        }
    }
    
    private func getCoreInfo() {
        cores = ProcessInfo.processInfo.processorCount.formatted()
        activeCores = ProcessInfo.processInfo.activeProcessorCount.formatted()
    }
    
    private func getSystemInfo() {
        let restartInterval = ProcessInfo.processInfo.systemUptime
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        
        guard let lastRestartTime = formatter.string(from: restartInterval) else {
            return
        }
        self.lastRestartTime = lastRestartTime
        
        userName = ProcessInfo.processInfo.hostName
        modelName = UIDevice().type.rawValue
    }
    
    private func getThermalInfo() {
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
    
    private func getSystemVersion() {
        let major = ProcessInfo.processInfo.operatingSystemVersion.majorVersion.description
        let minor = ProcessInfo.processInfo.operatingSystemVersion.minorVersion.description
        let path = ProcessInfo.processInfo.operatingSystemVersion.patchVersion.description
        
        iOSVersion = major + Constants.dot + minor + Constants.dot + path
        build = ProcessInfo.processInfo.operatingSystemVersionString
    }
    
    private func getProcessInfo() {
        processId = ProcessInfo.processInfo.processIdentifier.description
        processName = ProcessInfo.processInfo.processName
    }
    
    private func getCPUInfo() {
        cpu = String(format: "%.1f",cpuUsage()) + Constants.percent
    }
    
    func cpuUsage() -> Double {
        var totalUsageOfCPU: Double = 0.0
        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)
        let threadsResult = withUnsafeMutablePointer(to: &threadsList) {
            return $0.withMemoryRebound(to: thread_act_array_t?.self, capacity: 1) {
                task_threads(mach_task_self_, $0, &threadsCount)
            }
        }
        
        if threadsResult == KERN_SUCCESS, let threadsList = threadsList {
            for index in 0..<threadsCount {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadsList[Int(index)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                    }
                }
                
                guard infoResult == KERN_SUCCESS else {
                    break
                }
                
                let threadBasicInfo = threadInfo as thread_basic_info
                if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                    totalUsageOfCPU = (totalUsageOfCPU + (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0))
                }
            }
        }
        
        vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threadsList)), vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride))
        
        return totalUsageOfCPU
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
    
    private func setupFormatter() {
        formatter.numberFormatter.maximumFractionDigits = 1
        formatter.numberFormatter.roundingMode = .up
    }
    
    private func setupPublisher() {
        if (cancellable != nil) {
            cancellable = nil
        } else {
            cancellable = Timer
                .publish(every: Constants.publishDelay, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.updateData()
                }
        }
    }
    
    private func getBatteryInfo() {
        batteryLevel = (UIDevice.current.batteryLevel * 100).formatted() + Constants.percent
        
        switch UIDevice.current.batteryState {
        case .unknown:
            batteryState = "Неизвестно"
        case .unplugged:
            batteryState = "Питание от батареи"
        case .charging:
            batteryState = "Заряжается"
        case .full:
            batteryState = "Полностью заряжен"
        @unknown default:
            batteryState = "Неизвестно"
        }
        
        isLowPowerEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled ? "Вкл" : "Выкл"
    }
    
    private func getModelName() -> String {
        let name: String
        var mib  = [CTL_HW, HW_MODEL]

        // Max model name size not defined by sysctl. Instead we use io_name_t
        // via I/O Kit which can also get the model name
        var size = MemoryLayout<io_name_t>.size

        let ptr    = UnsafeMutablePointer<io_name_t>.allocate(capacity: 1)
        let result = sysctl(&mib, u_int(mib.count), ptr, &size, nil, 0)


        if result == 0 { name = String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self)) }
        else           { name = String() }


        ptr.deallocate()

        #if DEBUG
            if result != 0 {
                print("ERROR - \(#file):\(#function) - errno = "
                        + "\(result)")
            }
        #endif

        return name
    }
    
    private func getScreenBrightness() {
        brightness = String(format: "%.0f", UIScreen.main.brightness * 100) + Constants.percent
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
