import Foundation

/// Summary of every key currently registered in the vehicle's whitelist.
///
/// Swift-native projection of `VCSEC_WhitelistInfo` returned by
/// ``VehicleQuery/keySummary``. Use ``slotMask`` together with
/// ``VehicleQuery/keyInfo(slot:)`` to fetch detailed metadata for a
/// single slot.
public struct KeyWhitelistInfo: Sendable, Equatable {
    /// Total number of registered keys.
    public var numberOfEntries: UInt32
    /// One identifier per registered key, in vehicle-reported order.
    /// Each entry's ``KeyIdentifier/publicKeySha1`` is the SHA-1 hash
    /// of the key's uncompressed P-256 public key.
    public var entries: [KeyIdentifier]
    /// Bitmask of occupied whitelist slots; bit `i` set means slot `i`
    /// is in use.
    public var slotMask: UInt32

    public init(
        numberOfEntries: UInt32 = 0,
        entries: [KeyIdentifier] = [],
        slotMask: UInt32 = 0,
    ) {
        self.numberOfEntries = numberOfEntries
        self.entries = entries
        self.slotMask = slotMask
    }

    /// SHA-1 hash of an enrolled key's public key.
    public struct KeyIdentifier: Sendable, Equatable, Hashable {
        public var publicKeySha1: Data
        public init(publicKeySha1: Data = Data()) {
            self.publicKeySha1 = publicKeySha1
        }
    }
}

/// Detailed metadata for a single whitelist entry.
///
/// Swift-native projection of `VCSEC_WhitelistEntryInfo` returned by
/// ``VehicleQuery/keyInfo(slot:)``.
public struct KeyWhitelistEntry: Sendable, Equatable {
    /// SHA-1 of the enrolled public key. Nil if the vehicle did not
    /// report this field.
    public var keyIdentifier: KeyWhitelistInfo.KeyIdentifier?
    /// Raw public-key bytes (65-byte uncompressed SEC1 encoding,
    /// `0x04 || X || Y`). Nil if the vehicle did not report this field.
    public var publicKey: Data?
    /// Reported form factor (NFC card, iOS device, …). Nil if the
    /// vehicle did not report this field.
    public var formFactor: KeyFormFactor?
    /// Whitelist slot index this entry occupies.
    public var slot: UInt32
    /// Role assigned to this key.
    public var role: KeyRole

    public init(
        keyIdentifier: KeyWhitelistInfo.KeyIdentifier? = nil,
        publicKey: Data? = nil,
        formFactor: KeyFormFactor? = nil,
        slot: UInt32 = 0,
        role: KeyRole = .none,
    ) {
        self.keyIdentifier = keyIdentifier
        self.publicKey = publicKey
        self.formFactor = formFactor
        self.slot = slot
        self.role = role
    }
}
