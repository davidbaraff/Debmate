import XCTest
@testable import Debmate
#if !os(Linux)
@testable import DebmateC
#endif

final class DebmateTests: XCTestCase {
    #if !os(Linux)
    func testMD5() {
        XCTAssertEqual(Util.md5Digest(""), "d41d8cd98f00b204e9800998ecf8427e")
        XCTAssertEqual(Util.md5Digest("deb"), "38db7ce1861ee11b6a231c764662b68a")

        XCTAssertEqual(Util.md5Digest(Data()), "d41d8cd98f00b204e9800998ecf8427e")
        XCTAssertEqual(Util.md5Digest("deb".data(using: .utf8)!), "38db7ce1861ee11b6a231c764662b68a")
    }
    #endif

    #if !os(Linux)
    func testExceptionCatching() {
        var setMe = ""
        XCTAssert(Debmate_CatchException( {  setMe = "xyzzy" }))
        XCTAssertEqual(setMe, "xyzzy")
    }
    #endif
    
    func testStringExtensions() {
        XCTAssert(" abc ".trimmed == "abc")
        XCTAssert("a👗bc🧠".asciiSafe == "abc")
    }
   
    func testDictionaryOverwriting() {
        let d1 = Dictionary(overwriting: [("alpha", 1), ("beta", 2), ("alpha", 3)])
        let d2 = ["alpha" : 3, "beta" : 2]
        XCTAssertEqual(d1, d2)
    }

    func testLnotices() {
        let noticeObj1 = Lnotice<Int>()

        var v1 = 0
        var v2 = 0

        do {
            let noticeKey1 = noticeObj1.listen { v1 = $0 }
            let noticeKey2 = noticeObj1.listen { v2 = $0 }
            
            
            noticeObj1.broadcast(13)
            XCTAssertEqual(v1, 13)
            XCTAssertEqual(v2, 13)
            noticeKey1.cancel()
            noticeObj1.broadcast(14)
            XCTAssertEqual(v1, 13)
            XCTAssertEqual(v2, 14)
            
            noticeKey1.callNow(15)
            XCTAssertEqual(v1, 15)
            XCTAssertEqual(v2, 14)
            
            noticeKey2.callNow(18)
        }
        
        noticeObj1.broadcast(16)
        XCTAssertEqual(v2, 18)
    }
    
    #if !os(Linux)
    func testModelData() {
        let m1 = ModelData(UUID().uuidString, defaultValue: 13)
        XCTAssert(m1.value == 13)
        
        var nvalue = 0
        let key = m1.listen {
            nvalue = $0
        }

        m1.value = 17
        XCTAssert(nvalue == 17)
        
        key.cancel()
        m1.value = 18
        XCTAssert(nvalue == 17)
        
        var nvalue2 = Set<Int>()
        let m2 = ModelData(UUID().uuidString, defaultValue: Set([1,2,3]))
        XCTAssert(m2.value == Set([1,2,3]))
        let key2 = m2.listen {
            nvalue2 = $0
        }
        XCTAssert(nvalue2 != m2.value)
        m2.value = Set([1,3,9])
        XCTAssert(nvalue2 == m2.value)
        key2.cancel()
        m2.value = Set([7,8])
        XCTAssert(nvalue2 != m2.value)
    }
    
    func testPureModelData() {
        let m1 = PureModelData(UUID().uuidString, defaultValue: 13)
        XCTAssert(m1.value == 13)
        
        var nvalue = 0
        var ncalls = 0

        let key = m1.listen {
            print("Called with ", $0)
            nvalue = $0
            ncalls += 1
        }
        
        m1.value = 17
        XCTAssert(nvalue == 17)
        XCTAssert(ncalls == 1)

        m1.batchUpdate {
            m1.value = 19
            m1.value = 20
            m1.value = 21
        }
        
        XCTAssert(nvalue == 21)
        XCTAssert(ncalls == 2)
        
        key.cancel()
        m1.value = 22
        XCTAssert(nvalue == 21)
    }
    #endif

    static var allTests = [
        ("testLnotices", testLnotices),
        //("testMD5", testMD5),
        //("testStringExtensions", testStringExtensions),
        //("testExceptionCatching", testExceptionCatching)
    ]
    
}
