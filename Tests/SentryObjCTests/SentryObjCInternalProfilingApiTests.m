@import SentryObjC;
@import XCTest;

#if SENTRY_OBJC_PROFILING_SUPPORTED

@interface SentryObjCInternalProfilingApiTests : XCTestCase
@end

@implementation SentryObjCInternalProfilingApiTests

- (void)setUp
{
    [super setUp];
    [SentryObjCSDK startWithConfigureOptions:^(SentryObjCOptions *options) {
        options.dsn = @"https://key@sentry.io/123";
        options.enableCrashHandler = NO;
    }];
}

- (void)tearDown
{
    [SentryObjCSDK close];
    [super tearDown];
}

#    pragma mark - start

- (void)testStart_shouldNotCrash
{
    // -- Act & Assert (no crash) --
    SentryObjCId *traceId = [[SentryObjCId alloc] init];
    (void)[SentryObjCSDK.internal.profiling startFor:traceId];
}

#    pragma mark - collect

- (void)testCollect_withoutStart_shouldReturnNil
{
    // -- Act --
    SentryObjCId *traceId = [[SentryObjCId alloc] init];
    NSDictionary<NSString *, id> *result =
        [SentryObjCSDK.internal.profiling collectBetween:0 and:1 for:traceId];

    // -- Assert --
    XCTAssertNil(result);
}

#    pragma mark - discard

- (void)testDiscard_withoutStart_shouldNotCrash
{
    // -- Act & Assert (no crash) --
    SentryObjCId *traceId = [[SentryObjCId alloc] init];
    [SentryObjCSDK.internal.profiling discardFor:traceId];
}

- (void)testDiscard_calledMultipleTimes_shouldNotCrash
{
    // -- Act & Assert (no crash) --
    SentryObjCId *traceId = [[SentryObjCId alloc] init];
    [SentryObjCSDK.internal.profiling discardFor:traceId];
    [SentryObjCSDK.internal.profiling discardFor:traceId];
}

@end

#endif
