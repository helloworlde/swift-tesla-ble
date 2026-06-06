@testable import TeslaBLE
import XCTest

final class MessageFramerTests: XCTestCase {
    func testEncodePrefixesLengthBigEndian() {
        let payload = Data([0xAA, 0xBB, 0xCC])
        let framed = MessageFramer.encode(payload)
        XCTAssertEqual(framed, Data([0x00, 0x03, 0xAA, 0xBB, 0xCC]))
    }

    func testEncodeEmptyPayload() {
        let framed = MessageFramer.encode(Data())
        XCTAssertEqual(framed, Data([0x00, 0x00]))
    }

    func testDecodeCompleteMessage() throws {
        let buffer = Data([0x00, 0x03, 0xAA, 0xBB, 0xCC])
        let (message, consumed) = try MessageFramer.decode(buffer)
        XCTAssertEqual(message, Data([0xAA, 0xBB, 0xCC]))
        XCTAssertEqual(consumed, 5)
    }

    func testDecodeIncompleteBufferReturnsNil() throws {
        let buffer = Data([0x00, 0x05, 0xAA])
        let (message, consumed) = try MessageFramer.decode(buffer)
        XCTAssertNil(message)
        XCTAssertEqual(consumed, 0)
    }

    func testDecodeEmptyBufferReturnsNil() throws {
        let (message, consumed) = try MessageFramer.decode(Data())
        XCTAssertNil(message)
        XCTAssertEqual(consumed, 0)
    }

    func testDecodeZeroLengthFrameIsDrained() throws {
        // A zero-length frame carries no payload and is never emitted by
        // Tesla. decode reports its 2-byte prefix as consumable (so the reader
        // can resynchronize) but surfaces no message.
        let buffer = Data([0x00, 0x00])
        let (message, consumed) = try MessageFramer.decode(buffer)
        XCTAssertNil(message)
        XCTAssertEqual(consumed, 2)
    }

    func testDecodeZeroLengthFrameThenRealMessage() throws {
        // An empty prefix followed by a real 3-byte frame: the first decode
        // drains the empty prefix, the second yields the message. This is the
        // resynchronization path that keeps a stray zero-length frame from
        // wedging the reassembly buffer.
        var buffer = Data([0x00, 0x00, 0x00, 0x03, 0xAA, 0xBB, 0xCC])
        let (m1, c1) = try MessageFramer.decode(buffer)
        XCTAssertNil(m1)
        XCTAssertEqual(c1, 2)
        buffer.removeFirst(c1)
        let (m2, c2) = try MessageFramer.decode(buffer)
        XCTAssertEqual(m2, Data([0xAA, 0xBB, 0xCC]))
        XCTAssertEqual(c2, 5)
    }

    func testFragmentSplitsAtMTU() {
        let data = Data(repeating: 0x42, count: 50)
        let chunks = MessageFramer.fragment(data, mtu: 20)
        XCTAssertEqual(chunks.count, 3)
        XCTAssertEqual(chunks[0].count, 20)
        XCTAssertEqual(chunks[1].count, 20)
        XCTAssertEqual(chunks[2].count, 10)
        XCTAssertEqual(Data(chunks.joined()), data)
    }

    func testFragmentExactMultiple() {
        let data = Data(repeating: 0x55, count: 40)
        let chunks = MessageFramer.fragment(data, mtu: 20)
        XCTAssertEqual(chunks.count, 2)
        XCTAssertEqual(chunks[0].count, 20)
        XCTAssertEqual(chunks[1].count, 20)
    }

    func testFragmentSmallerThanMTU() {
        let data = Data([0x01, 0x02, 0x03])
        let chunks = MessageFramer.fragment(data, mtu: 20)
        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks[0], data)
    }
}
