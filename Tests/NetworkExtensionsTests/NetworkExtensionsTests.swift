@testable import NetworkExtensions
import XCTest

final class NetworkExtensionsTests: XCTestCase {
    func testIPv6WithInterface() {
        // given
        let input = "fe80::521e:2dff:fe3d:1d38%en0"

        // when
        guard let sut = IP(input),
              case let .ipv6(v6addr) = sut else {
            XCTFail("Expected sut to be a v6 address!")
            return
        }

        // then
        XCTAssertTrue(sut.isIPv6)
        XCTAssertEqual(v6addr.interface?.name, "en0")
        XCTAssertEqual(sut.ipString, "fe80::521e:2dff:fe3d:1d38%en0")
    }

    func testIpv4UrlString() {
        // given
        let input = "127.0.0.1"

        // when
        guard let sut = IP(input) else {
            XCTFail("Expected sut to be a valid")
            return
        }

        // then
        XCTAssertTrue(sut.isIPv4)
        XCTAssertEqual(sut.ipUrlString, "127.0.0.1")
    }

    func testIpv6UrlString() {
        // given
        let input = "fe80::521e:2dff:fe3d:1d38%en0"

        // when
        guard let sut = IP(input),
              case .ipv6 = sut else {
            XCTFail("Expected sut to be a v6 address!")
            return
        }

        // then
        XCTAssertTrue(sut.isIPv6)
        XCTAssertEqual(sut.ipUrlString, "[fe80::521e:2dff:fe3d:1d38%en0]")
    }

    func testPreferredAddress() {
        // given
        let addresses = ["127.0.0.1", "fe80::521e:2dff:fe3d:1d38%en0", "2003:e1:d716:4d00:54f9:61b5:2507:11bd", "1.1.1.1"]
            .compactMap { IP($0) }

        // then
        XCTAssertEqual(addresses.preferredAddress?.ipString, "fe80::521e:2dff:fe3d:1d38%en0")
    }
}
