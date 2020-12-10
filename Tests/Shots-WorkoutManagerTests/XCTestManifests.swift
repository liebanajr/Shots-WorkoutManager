import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(Shots_WorkoutManagerTests.allTests),
    ]
}
#endif
