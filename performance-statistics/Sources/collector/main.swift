import IOKit
import IOKit.graphics
import Metal
import Metrics
import Prometheus
import Vapor

func getPerformanceStatistics() -> [String: Any]? {
    var iterator: io_iterator_t = 0
    let result = IOServiceGetMatchingServices(
        kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &iterator)
    if result == kIOReturnSuccess {
        var service = IOIteratorNext(iterator)
        while service != 0 {
            let unmanagedDict = IORegistryEntryCreateCFProperty(
                service, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0)
            if let dict = unmanagedDict?.takeRetainedValue() as? [String: Any] {
                IOObjectRelease(service)
                IOObjectRelease(iterator)
                return dict
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
        IOObjectRelease(iterator)
    }
    return nil
}

let registry = PrometheusCollectorRegistry()
MetricsSystem.bootstrap(PrometheusMetricsFactory(registry: registry))

let app = Application()
app.http.server.configuration.reportMetrics = false
defer { app.shutdown() }

let devices = MTLCopyAllDevices()
let dimensions = [("name", devices.first?.name ?? "unknown")]

let tilerUtilization = Gauge(label: "tiler_utilization", dimensions: dimensions)
let inUseSystemMemory = Gauge(label: "in_use_system_memory", dimensions: dimensions)
let splitSceneCount = Gauge(label: "split_scene_count", dimensions: dimensions)
let rendererUtilization = Gauge(label: "renderer_utilization", dimensions: dimensions)
let recoveryCount = Gauge(label: "recovery_count", dimensions: dimensions)
let allocatedPBSize = Gauge(label: "allocated_pb_size", dimensions: dimensions)
let allocSystemMemory = Gauge(label: "alloc_system_memory", dimensions: dimensions)
let tiledSceneBytes = Gauge(label: "tiled_scene_bytes", dimensions: dimensions)
let deviceUtilization = Gauge(label: "device_utilization", dimensions: dimensions)

app.get("metrics") { request in
    var buffer: [UInt8] = []
    buffer.reserveCapacity(1024)

    if let performanceStatistics = getPerformanceStatistics() {
        if let v = performanceStatistics["Tiler Utilization %"] as? Int {
            tilerUtilization.record(v)
        }
        if let v = performanceStatistics["In use system memory"] as? Int {
            inUseSystemMemory.record(v)
        }
        if let v = performanceStatistics["SplitSceneCount"] as? Int {
            splitSceneCount.record(v)
        }
        if let v = performanceStatistics["Renderer Utilization %"] as? Int {
            rendererUtilization.record(v)
        }
        if let v = performanceStatistics["recoveryCount"] as? Int {
            recoveryCount.record(v)
        }
        if let v = performanceStatistics["Allocated PB Size"] as? Int {
            allocatedPBSize.record(v)
        }
        if let v = performanceStatistics["Alloc system memory"] as? Int {
            allocSystemMemory.record(v)
        }
        if let v = performanceStatistics["TiledSceneBytes"] as? Int {
            tiledSceneBytes.record(v)
        }
        if let v = performanceStatistics["Device Utilization %"] as? Int {
            deviceUtilization.record(v)
        }
        registry.emit(into: &buffer)
    }

    return String(decoding: buffer, as: UTF8.self)
}

try await app.execute()
