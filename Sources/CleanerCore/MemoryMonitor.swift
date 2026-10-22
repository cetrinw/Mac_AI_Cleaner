import Foundation
import Darwin
import AppKit

private struct ProcessTaskInfo {
    var virtualSize: UInt64 = 0; var residentSize: UInt64 = 0; var totalUser: UInt64 = 0; var totalSystem: UInt64 = 0
    var threadsUser: UInt64 = 0; var threadsSystem: UInt64 = 0; var policy: Int32 = 0; var faults: Int32 = 0; var pageins: Int32 = 0; var cowFaults: Int32 = 0; var messagesSent: Int32 = 0; var messagesReceived: Int32 = 0; var syscallsMach: Int32 = 0; var syscallsUnix: Int32 = 0; var csw: Int32 = 0; var threadnum: Int32 = 0; var numrunning: Int32 = 0; var priority: Int32 = 0
}
@_silgen_name("proc_pidinfo") private func macProcPidInfo(_ pid: Int32, _ flavor: Int32, _ arg: UInt64, _ buffer: UnsafeMutableRawPointer?, _ buffersize: Int32) -> Int32

public struct MemorySnapshot: Codable, Sendable {
    public let date: Date
    public let totalBytes: UInt64
    public let activeBytes: UInt64
    public let wiredBytes: UInt64
    public let compressedBytes: UInt64
    public let availableBytes: UInt64
    public let processes: [ProcessMemory]
    public var pressure: String { usedRatio > 0.9 ? "高" : usedRatio > 0.75 ? "中" : "正常" }
    public var usedBytes: UInt64 { totalBytes > availableBytes ? totalBytes - availableBytes : 0 }
    public var usedRatio: Double { totalBytes == 0 ? 0 : Double(usedBytes) / Double(totalBytes) }
}
public struct ProcessMemory: Identifiable, Codable, Sendable { public let id: Int32; public let name: String; public let bytes: UInt64; public let virtualBytes: UInt64; public let threads: Int32 }

public enum MemoryMonitor {
    public static func snapshot(limit: Int = 500) -> MemorySnapshot {
        var stats = vm_statistics64(); var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride); let host = mach_host_self()
        withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { raw in _ = host_statistics64(host, HOST_VM_INFO64, raw, &count) }
        }
        let page = UInt64(vm_kernel_page_size); let active = UInt64(stats.active_count) * page; let wired = UInt64(stats.wire_count) * page; let compressed = UInt64(stats.compressor_page_count) * page; let free = UInt64(stats.free_count) * page
        let total = ProcessInfo.processInfo.physicalMemory
        let processes = NSWorkspace.shared.runningApplications.compactMap { app -> ProcessMemory? in
            guard app.processIdentifier > 0 else { return nil }
            var info = ProcessTaskInfo()
            let result = withUnsafeMutableBytes(of: &info) { raw in macProcPidInfo(app.processIdentifier, 4, 0, raw.baseAddress, Int32(MemoryLayout<ProcessTaskInfo>.size)) }
            guard result == MemoryLayout<ProcessTaskInfo>.size else { return nil }
            return ProcessMemory(id: app.processIdentifier, name: app.localizedName ?? "Unknown", bytes: info.residentSize, virtualBytes: info.virtualSize, threads: info.threadnum)
        }.sorted { $0.bytes > $1.bytes }.prefix(limit).map { $0 }
        return MemorySnapshot(date: Date(), totalBytes: total, activeBytes: active, wiredBytes: wired, compressedBytes: compressed, availableBytes: free, processes: Array(processes))
    }
}
