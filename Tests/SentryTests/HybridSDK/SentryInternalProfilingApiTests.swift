@testable import Sentry
import XCTest

#if !(os(watchOS) || os(tvOS) || os(visionOS))

class SentryInternalProfilingApiTests: XCTestCase {

    private let sut = SentryInternalProfilingApi()

    // MARK: - start

    func testStart_withoutSDK_shouldNotCrash() {
        let startTime = sut.start(for: SentryId())
        // On some platforms the profiler may start even without an SDK running,
        // so we only verify it doesn't crash (returns 0 or a valid system time).
        _ = startTime
    }

    func testStart_withDifferentTraceIds_shouldNotCrash() {
        let startTimeA = sut.start(for: SentryId())
        let startTimeB = sut.start(for: SentryId())
        _ = startTimeA
        _ = startTimeB
    }

    // MARK: - collect

    func testCollect_withoutStart_shouldReturnNil() {
        let result = sut.collect(between: 0, and: 1, for: SentryId())
        XCTAssertNil(result)
    }

    func testCollect_withZeroTimeRange_shouldReturnNil() {
        let result = sut.collect(between: 0, and: 0, for: SentryId())
        XCTAssertNil(result)
    }

    func testCollect_withArbitraryTimes_shouldReturnNil() {
        let result = sut.collect(between: 100, and: 200, for: SentryId())
        XCTAssertNil(result)
    }

    // MARK: - discard

    func testDiscard_withoutStart_shouldNotCrash() {
        sut.discard(for: SentryId())
    }

    func testDiscard_calledMultipleTimes_shouldNotCrash() {
        let traceId = SentryId()
        sut.discard(for: traceId)
        sut.discard(for: traceId)
    }
}

#endif
