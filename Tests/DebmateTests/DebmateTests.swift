import XCTest
@testable import Debmate

final class DebmateTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Debmate().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
