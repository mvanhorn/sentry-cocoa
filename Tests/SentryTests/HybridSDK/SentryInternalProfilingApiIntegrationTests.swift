@_spi(Private) @testable import Sentry
@_spi(Private) import SentryTestUtils
import XCTest

#if !(os(watchOS) || os(tvOS) || os(visionOS))

class SentryInternalProfilingApiIntegrationTests: XCTestCase {

    private static let dsnAsString = TestConstants.dsnForTestCase(type: SentryInternalProfilingApiIntegrationTests.self)

    override func tearDown() {
        clearTestState()
        super.tearDown()
    }

    // MARK: - Helpers

    private func startSDK() {
        SentrySDK.start { options in
            options.dsn = Self.dsnAsString
            options.removeAllIntegrations()
        }
    }

    // MARK: - Accessor

    func testProfiling_shouldBeAccessible() {
        startSDK()

        // -- Act --
        let profiling = SentrySDK.internal.profiling

        // -- Assert --
        XCTAssertNotNil(profiling)
    }

    // MARK: - start

    func testStart_withSDKRunning_shouldReturnNonZeroTime() throws {
        try skipIfThreadSanitizer()
        startSDK()

        // -- Act --
        let startTime = SentrySDK.internal.profiling.start(for: SentryId())

        // -- Assert --
        XCTAssertGreaterThan(startTime, 0)
    }

    func testStart_multipleTimes_shouldReturnDifferentStartTimes() throws {
        try skipIfThreadSanitizer()
        startSDK()

        // -- Act --
        let traceA = SentryId()
        let traceB = SentryId()
        let startTimeA = SentrySDK.internal.profiling.start(for: traceA)
        let startTimeB = SentrySDK.internal.profiling.start(for: traceB)

        // -- Assert --
        XCTAssertGreaterThan(startTimeA, 0)
        XCTAssertGreaterThan(startTimeB, 0)
    }

    // MARK: - collect

    func testCollect_afterStart_shouldReturnPayload() throws {
        try skipIfThreadSanitizer()
        startSDK()

        let traceId = SentryId()

        // -- Arrange --
        let startTime = SentrySDK.internal.profiling.start(for: traceId)
        XCTAssertGreaterThan(startTime, 0)
        Thread.sleep(forTimeInterval: 0.2)

        // -- Act --
        let payload = SentrySDK.internal.profiling.collect(
            between: startTime,
            and: startTime + 200_000_000,
            for: traceId
        )

        // -- Assert --
        XCTAssertNotNil(payload)
    }

    func testCollect_payloadContainsPlatform() throws {
        try skipIfThreadSanitizer()
        startSDK()

        let traceId = SentryId()
        let startTime = SentrySDK.internal.profiling.start(for: traceId)
        Thread.sleep(forTimeInterval: 0.2)

        // -- Act --
        let payload = SentrySDK.internal.profiling.collect(
            between: startTime,
            and: startTime + 200_000_000,
            for: traceId
        )

        // -- Assert --
        XCTAssertEqual(payload?["platform"] as? String, "cocoa")
    }

    func testCollect_payloadContainsDebugMeta() throws {
        try skipIfThreadSanitizer()

        let image = DebugMeta()
        image.imageAddress = "0x0000000105705000"
        image.imageVmAddress = "0x0000000105705000"
        image.codeFile = "codeFile"
        image.debugID = "debugID"
        image.imageSize = 100
        image.type = "macho"

        let debugImageProvider = TestDebugImageProvider()
        debugImageProvider.debugImages = [image]
        SentryDependencyContainer.sharedInstance().debugImageProvider = debugImageProvider

        startSDK()

        let traceId = SentryId()
        let startTime = SentrySDK.internal.profiling.start(for: traceId)
        Thread.sleep(forTimeInterval: 0.2)

        // -- Act --
        let payload = SentrySDK.internal.profiling.collect(
            between: startTime,
            and: startTime + 200_000_000,
            for: traceId
        )

        // -- Assert --
        XCTAssertEqual(1, debugImageProvider.getDebugImagesFromCacheInvocations.count)

        let debugMeta = try XCTUnwrap(payload?["debug_meta"] as? [String: Any])
        let images = try XCTUnwrap(debugMeta["images"] as? [[String: Any]])
        let debugImage = try XCTUnwrap(images.first)
        XCTAssertEqual(debugImage["image_addr"] as? String, image.imageAddress)
        XCTAssertEqual(debugImage["image_vmaddr"] as? String, image.imageVmAddress)
        XCTAssertEqual(debugImage["code_file"] as? String, image.codeFile)
        XCTAssertEqual(debugImage["debug_id"] as? String, image.debugID)
        XCTAssertEqual(debugImage["image_size"] as? NSNumber, image.imageSize)
        XCTAssertEqual(debugImage["type"] as? String, image.type)
    }

    func testCollect_payloadContainsDeviceInfo() throws {
        try skipIfThreadSanitizer()
        startSDK()

        let traceId = SentryId()
        let startTime = SentrySDK.internal.profiling.start(for: traceId)
        Thread.sleep(forTimeInterval: 0.2)

        // -- Act --
        let payload = SentrySDK.internal.profiling.collect(
            between: startTime,
            and: startTime + 200_000_000,
            for: traceId
        )

        // -- Assert --
        XCTAssertNotNil(payload?["device"])
    }

    func testCollect_payloadContainsProfileId() throws {
        try skipIfThreadSanitizer()
        startSDK()

        let traceId = SentryId()
        let startTime = SentrySDK.internal.profiling.start(for: traceId)
        Thread.sleep(forTimeInterval: 0.2)

        // -- Act --
        let payload = SentrySDK.internal.profiling.collect(
            between: startTime,
            and: startTime + 200_000_000,
            for: traceId
        )

        // -- Assert --
        XCTAssertNotNil(payload?["profile_id"])
    }

    func testCollect_payloadContainsProfileData() throws {
        try skipIfThreadSanitizer()
        startSDK()

        let traceId = SentryId()
        let startTime = SentrySDK.internal.profiling.start(for: traceId)
        Thread.sleep(forTimeInterval: 0.2)

        // -- Act --
        let payload = SentrySDK.internal.profiling.collect(
            between: startTime,
            and: startTime + 200_000_000,
            for: traceId
        )

        // -- Assert --
        let profile = payload?["profile"] as? NSDictionary
        XCTAssertNotNil(profile?["thread_metadata"])
        XCTAssertNotNil(profile?["samples"])
        XCTAssertNotNil(profile?["stacks"])
        XCTAssertNotNil(profile?["frames"])
    }

    func testCollect_payloadContainsTransactionInfo() throws {
        try skipIfThreadSanitizer()
        startSDK()

        let traceId = SentryId()
        let startTime = SentrySDK.internal.profiling.start(for: traceId)
        Thread.sleep(forTimeInterval: 0.2)

        // -- Act --
        let payload = SentrySDK.internal.profiling.collect(
            between: startTime,
            and: startTime + 200_000_000,
            for: traceId
        )

        // -- Assert --
        let transactionInfo = try XCTUnwrap(payload?["transaction"] as? NSDictionary)
        XCTAssertGreaterThan(try XCTUnwrap(transactionInfo["active_thread_id"] as? Int64), 0)
    }

    func testCollect_withoutStart_shouldReturnNil() {
        startSDK()

        // -- Act --
        let result = SentrySDK.internal.profiling.collect(between: 0, and: 1, for: SentryId())

        // -- Assert --
        XCTAssertNil(result)
    }

    // MARK: - discard

    func testDiscard_afterStart_shouldNotCrash() throws {
        try skipIfThreadSanitizer()
        startSDK()

        let traceId = SentryId()
        let startTime = SentrySDK.internal.profiling.start(for: traceId)
        XCTAssertGreaterThan(startTime, 0)
        Thread.sleep(forTimeInterval: 0.2)

        // -- Act & Assert (no crash) --
        SentrySDK.internal.profiling.discard(for: traceId)
    }

    func testDiscard_withoutStart_shouldNotCrash() {
        startSDK()

        // -- Act & Assert (no crash) --
        SentrySDK.internal.profiling.discard(for: SentryId())
    }

    // MARK: - Helpers

    private func skipIfThreadSanitizer() throws {
        if sentry_threadSanitizerIsPresent() {
            throw XCTSkip("Profiler does not run if thread sanitizer is attached.")
        }
    }
}

#endif
