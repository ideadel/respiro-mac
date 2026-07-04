import Darwin
import Foundation

/// Live disk, memory and CPU readings — honest snapshots, no smoothing theatrics.
enum SystemMetricsService {
    struct MemoryStats {
        let availableBytes: Int64
        let totalBytes: Int64
        let wiredBytes: Int64
        let compressedBytes: Int64
    }

    struct Snapshot {
        let diskFree: Int64?
        let diskTotal: Int64?
        let memory: MemoryStats?
        /// Approximate system CPU use (0…100) from 1-minute load average.
        let cpuLoadPercent: Double?
    }

    static func snapshot() -> Snapshot {
        let disk = DiskUsageService.volumeStats()
        return Snapshot(
            diskFree: disk?.free,
            diskTotal: disk?.total,
            memory: memoryStats(),
            cpuLoadPercent: cpuLoadPercent()
        )
    }

    static func memoryStats() -> MemoryStats? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size
        )
        let result: kern_return_t = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, rebound, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        let page = Int64(vm_kernel_page_size)
        let available = Int64(stats.free_count + stats.inactive_count) * page
        let wired = Int64(stats.wire_count) * page
        let compressed = Int64(stats.compressor_page_count) * page
        let total = Int64(ProcessInfo.processInfo.physicalMemory)
        return MemoryStats(
            availableBytes: available,
            totalBytes: total,
            wiredBytes: wired,
            compressedBytes: compressed
        )
    }

    static func cpuLoadPercent() -> Double? {
        var load = [Double](repeating: 0, count: 3)
        guard getloadavg(&load, 3) != -1 else { return nil }
        let cores = max(1, ProcessInfo.processInfo.processorCount)
        return min(100, (load[0] / Double(cores)) * 100)
    }
}
