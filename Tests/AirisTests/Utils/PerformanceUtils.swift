import XCTest

/// 并行性能测试工具类
enum PerformanceUtils {
    /// 性能统计结果
    struct Stats {
        let average: TimeInterval
        let min: TimeInterval
        let max: TimeInterval
        let stdDev: TimeInterval

        func print() {
            Swift.print("📊 性能统计 (并行 measure):")
            Swift.print("   平均: \(String(format: "%.3f", average))s")
            Swift.print("   最小: \(String(format: "%.3f", min))s")
            Swift.print("   最大: \(String(format: "%.3f", max))s")
            Swift.print("   标准差: \(String(format: "%.3f", stdDev))s")
        }
    }

    /// 并行执行多次操作并测量平均时间
    /// - Parameters:
    ///   - iterations: 迭代次数（默认 10）
    ///   - maxConcurrency: 最大并发数（默认 4，避免资源竞争）
    ///   - warmup: 是否预热（默认 true，首次调用通常更慢）
    ///   - operation: 要测量的异步操作
    /// - Returns: 性能统计结果
    static func measureParallel(
        iterations: Int = 10,
        maxConcurrency: Int = 4,
        warmup: Bool = true,
        operation: @escaping @Sendable () async throws -> Void
    ) async throws -> Stats {
        // 预热（避免首次调用的初始化开销影响统计）
        if warmup {
            _ = try? await operation()
        }

        var durations: [TimeInterval] = []

        // 分批并行执行，避免过度竞争
        let batches = (iterations + maxConcurrency - 1) / maxConcurrency

        for batch in 0 ..< batches {
            let startIdx = batch * maxConcurrency
            let endIdx = min(startIdx + maxConcurrency, iterations)
            let batchSize = endIdx - startIdx

            // 每批内并行执行
            try await withThrowingTaskGroup(of: TimeInterval.self) { group in
                for _ in 0 ..< batchSize {
                    group.addTask {
                        let start = Date()
                        try await operation()
                        return Date().timeIntervalSince(start)
                    }
                }

                for try await duration in group {
                    durations.append(duration)
                }
            }
        }

        // 计算统计数据
        let average = durations.reduce(0, +) / Double(durations.count)
        let min = durations.min() ?? 0
        let max = durations.max() ?? 0

        // 计算标准差
        let variance = durations.map { pow($0 - average, 2) }.reduce(0, +) / Double(durations.count)
        let stdDev = sqrt(variance)

        return Stats(average: average, min: min, max: max, stdDev: stdDev)
    }

    /// 串行执行多次操作并测量（用于对比）
    static func measureSerial(
        iterations: Int = 10,
        warmup: Bool = true,
        operation: @escaping @Sendable () async throws -> Void
    ) async throws -> Stats {
        if warmup {
            _ = try? await operation()
        }

        var durations: [TimeInterval] = []

        for _ in 0 ..< iterations {
            let start = Date()
            try await operation()
            durations.append(Date().timeIntervalSince(start))
        }

        let average = durations.reduce(0, +) / Double(durations.count)
        let min = durations.min() ?? 0
        let max = durations.max() ?? 0

        let variance = durations.map { pow($0 - average, 2) }.reduce(0, +) / Double(durations.count)
        let stdDev = sqrt(variance)

        return Stats(average: average, min: min, max: max, stdDev: stdDev)
    }
}
