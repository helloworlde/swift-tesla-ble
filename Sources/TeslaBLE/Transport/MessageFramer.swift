import Foundation

/// Framing for Tesla BLE's TX/RX characteristics: every message carries a
/// 2-byte big-endian length header (`[lenHi, lenLo, payload...]`) and is then
/// split into MTU-sized chunks for the actual GATT writes, since CoreBluetooth
/// writes are capped by the negotiated MTU. `decode(_:)` reassembles the stream
/// on the receiving side, returning the payload once the full length has arrived.
enum MessageFramer {
    /// Encodes `payload` with a 2-byte big-endian length prefix.
    static func encode(_ payload: Data) -> Data {
        let length = UInt16(payload.count)
        var framed = Data(capacity: 2 + payload.count)
        framed.append(UInt8(length >> 8))
        framed.append(UInt8(length & 0xFF))
        framed.append(payload)
        return framed
    }

    /// Attempts to decode one message from the buffer.
    ///
    /// Return contract — the second tuple element is always the number of
    /// bytes the caller should drop from the front of its buffer:
    /// - `(message, n)` with `n > 0` — a complete frame was decoded; consume
    ///   `n` bytes and deliver `message`.
    /// - `(nil, n)` with `n > 0` — a degenerate zero-length frame was found
    ///   (`n == 2`, just the length prefix). Tesla never emits empty frames,
    ///   so this only happens on a corrupt or desynced stream. The prefix is
    ///   reported as consumable so the reader can resynchronize on the next
    ///   frame instead of stalling until the RX-timeout buffer reset; the
    ///   empty frame is never surfaced as a message upstream.
    /// - `(nil, 0)` — the buffer does not yet hold a complete frame; wait for
    ///   more bytes.
    static func decode(_ buffer: Data) throws -> (Data?, Int) {
        guard buffer.count >= 2 else { return (nil, 0) }
        let length = Int(buffer[buffer.startIndex]) << 8
            | Int(buffer[buffer.startIndex + 1])
        // Drain a zero-length frame rather than treating it as "incomplete":
        // returning (nil, 0) here would wedge the reassembly buffer forever.
        guard length > 0 else { return (nil, 2) }
        let totalNeeded = 2 + length
        guard buffer.count >= totalNeeded else { return (nil, 0) }
        let message = buffer[buffer.startIndex + 2 ..< buffer.startIndex + totalNeeded]
        return (Data(message), totalNeeded)
    }

    /// Splits `data` into chunks of at most `mtu` bytes.
    static func fragment(_ data: Data, mtu: Int) -> [Data] {
        var chunks: [Data] = []
        var offset = data.startIndex
        while offset < data.endIndex {
            let end = min(offset + mtu, data.endIndex)
            chunks.append(Data(data[offset ..< end]))
            offset = end
        }
        return chunks
    }
}
