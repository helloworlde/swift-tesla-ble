import Foundation

/// Installed firmware version and in-progress software update status.
public struct SoftwareUpdateState: Sendable, Equatable {
    /// Current installed firmware version string. Nil if the vehicle did not report this field.
    public var version: String?
    /// Lifecycle state of the most recent OTA update.
    public var status: Status?
    /// Download progress of a pending update in percent (0–100). Nil if the vehicle did not report this field.
    public var downloadPercent: Int?
    /// Install progress of a pending update in percent (0–100). Nil if the vehicle did not report this field.
    public var installPercent: Int?
    /// Expected total install duration in seconds. Nil if the vehicle did not report this field.
    public var expectedDurationSeconds: Int?
    /// Scheduled install time, in milliseconds since the Unix epoch.
    public var scheduledTimeMs: UInt64?
    /// Time remaining (in ms) before the user is auto-prompted to start the
    /// install (typically a "starting in N minutes" countdown).
    public var warningTimeRemainingMs: UInt64?

    /// Lifecycle stage of an OTA update. Mirrors
    /// `CarServer_SoftwareUpdateState.SoftwareUpdateStatus`.
    public enum Status: Sendable, Equatable {
        case unknown
        case installing
        case scheduled
        case available
        case downloadingWifiWait
        case downloading
    }

    public init(
        version: String? = nil,
        status: Status? = nil,
        downloadPercent: Int? = nil,
        installPercent: Int? = nil,
        expectedDurationSeconds: Int? = nil,
        scheduledTimeMs: UInt64? = nil,
        warningTimeRemainingMs: UInt64? = nil,
    ) {
        self.version = version
        self.status = status
        self.downloadPercent = downloadPercent
        self.installPercent = installPercent
        self.expectedDurationSeconds = expectedDurationSeconds
        self.scheduledTimeMs = scheduledTimeMs
        self.warningTimeRemainingMs = warningTimeRemainingMs
    }
}
