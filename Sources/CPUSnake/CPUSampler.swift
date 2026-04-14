import Darwin
import Foundation

final class CPUSampler {
    let physicalCoreCount: Int
    private var lastTicks: [(user: UInt32, system: UInt32, idle: UInt32, nice: UInt32)] = []

    init() {
        var size = MemoryLayout<Int32>.size
        var phys: Int32 = 0
        sysctlbyname("hw.physicalcpu", &phys, &size, nil, 0)
        self.physicalCoreCount = max(1, Int(phys))
        self.lastTicks = readTicks()
    }

    /// Returns one utilization value per physical core (0...1).
    func sample() -> [Double] {
        let current = readTicks()
        defer { lastTicks = current }
        guard !current.isEmpty, current.count == lastTicks.count else {
            return Array(repeating: 0, count: physicalCoreCount)
        }
        var perLogical: [Double] = []
        perLogical.reserveCapacity(current.count)
        for i in 0..<current.count {
            let dUser = Int64(current[i].user) &- Int64(lastTicks[i].user)
            let dSys = Int64(current[i].system) &- Int64(lastTicks[i].system)
            let dNice = Int64(current[i].nice) &- Int64(lastTicks[i].nice)
            let dIdle = Int64(current[i].idle) &- Int64(lastTicks[i].idle)
            let active = max(0, dUser + dSys + dNice)
            let total = active + max(0, dIdle)
            perLogical.append(total > 0 ? Double(active) / Double(total) : 0)
        }
        let groupSize = max(1, current.count / physicalCoreCount)
        var result: [Double] = []
        result.reserveCapacity(physicalCoreCount)
        for p in 0..<physicalCoreCount {
            let start = p * groupSize
            let end = min(perLogical.count, start + groupSize)
            if start < end {
                let slice = perLogical[start..<end]
                result.append(slice.reduce(0, +) / Double(slice.count))
            } else {
                result.append(0)
            }
        }
        return result
    }

    private func readTicks() -> [(user: UInt32, system: UInt32, idle: UInt32, nice: UInt32)] {
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCpus: natural_t = 0
        let err = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCpus,
            &cpuInfo,
            &numCpuInfo
        )
        guard err == KERN_SUCCESS, let cpuInfo = cpuInfo else { return [] }
        defer {
            let bytes = vm_size_t(Int(numCpuInfo) * MemoryLayout<integer_t>.size)
            let address = vm_address_t(UInt(bitPattern: Int(bitPattern: cpuInfo)))
            vm_deallocate(mach_task_self_, address, bytes)
        }
        var result: [(UInt32, UInt32, UInt32, UInt32)] = []
        result.reserveCapacity(Int(numCpus))
        for i in 0..<Int(numCpus) {
            let base = i * Int(CPU_STATE_MAX)
            let user = UInt32(bitPattern: cpuInfo[base + Int(CPU_STATE_USER)])
            let system = UInt32(bitPattern: cpuInfo[base + Int(CPU_STATE_SYSTEM)])
            let idle = UInt32(bitPattern: cpuInfo[base + Int(CPU_STATE_IDLE)])
            let nice = UInt32(bitPattern: cpuInfo[base + Int(CPU_STATE_NICE)])
            result.append((user, system, idle, nice))
        }
        return result
    }
}
