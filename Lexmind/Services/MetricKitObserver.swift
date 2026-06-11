//
//  MetricKitObserver.swift
//  Lexmind
//
//  Subscribes to MetricKit's daily metric and crash diagnostic
//  callbacks and forwards compact summaries to `Log.metrics`. Real
//  payloads land in Console.app's metric subsystem; the logged summary
//  is just enough to triage from the device console without needing
//  the raw plist.
//

import Foundation
import MetricKit

final class MetricKitObserver: NSObject, MXMetricManagerSubscriber {

    func start() {
        MXMetricManager.shared.add(self)
    }

    // MARK: - MXMetricManagerSubscriber

    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            let launches = payload.applicationLaunchMetrics?.histogrammedTimeToFirstDraw.totalBucketCount ?? 0
            let hangs = payload.applicationResponsivenessMetrics?.histogrammedApplicationHangTime.totalBucketCount ?? 0
            let memoryPeak = payload.memoryMetrics?.peakMemoryUsage.value ?? 0
            let cpuTime = payload.cpuMetrics?.cumulativeCPUTime.value ?? 0
            Log.metrics.info(
                "MXMetricPayload received — launches: \(launches), hangs: \(hangs), peakMemMB: \(memoryPeak / 1_000_000), cpuSeconds: \(cpuTime)"
            )
        }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            let crashCount = payload.crashDiagnostics?.count ?? 0
            let hangCount = payload.hangDiagnostics?.count ?? 0
            let cpuExceptionCount = payload.cpuExceptionDiagnostics?.count ?? 0
            let diskWriteCount = payload.diskWriteExceptionDiagnostics?.count ?? 0
            if crashCount + hangCount + cpuExceptionCount + diskWriteCount > 0 {
                Log.metrics.fault(
                    "MXDiagnosticPayload — crashes: \(crashCount), hangs: \(hangCount), cpuExceptions: \(cpuExceptionCount), diskWrites: \(diskWriteCount)"
                )
            }
        }
    }
}
