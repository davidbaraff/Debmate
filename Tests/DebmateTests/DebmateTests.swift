import XCTest
@testable import Debmate
@testable import DebmateC

final class DebmateTests: XCTestCase {
    func testMD5() {
        XCTAssertEqual(Util.md5Digest(""), "d41d8cd98f00b204e9800998ecf8427e")
        XCTAssertEqual(Util.md5Digest("deb"), "38db7ce1861ee11b6a231c764662b68a")

        XCTAssertEqual(Util.md5Digest(Data()), "d41d8cd98f00b204e9800998ecf8427e")
        XCTAssertEqual(Util.md5Digest("deb".data(using: .utf8)!), "38db7ce1861ee11b6a231c764662b68a")
    }

    func testExceptionCatching() {
        var setMe = ""
        XCTAssert(Debmate_CatchException( {  setMe = "xyzzy" }))
        XCTAssertEqual(setMe, "xyzzy")
    }
    
    func testStringExtensions() {
        XCTAssert(" abc ".trimmed == "abc")
        XCTAssert("a👗bc🧠".asciiSafe == "abc")
    }

    static var allTests = [
        ("testMD5", testMD5),
        ("testStringExtensions", testStringExtensions),        ("testExceptionCatching", testExceptionCatching)
    ]
}
