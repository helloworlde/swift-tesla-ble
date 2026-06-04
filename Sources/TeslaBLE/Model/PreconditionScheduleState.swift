import Foundation

/// Vehicle's scheduled-preconditioning configuration.
///
/// Mirrors `CarServer_PreconditioningScheduleState` plus its repeated
/// `CarServer_PreconditionSchedule` entries. Top-level fields use Swift
/// `nil` to represent "vehicle did not report", matching the upstream
/// `optional_*` proto oneofs.
public struct PreconditionScheduleState: Sendable, Equatable {
    /// All saved precondition schedules currently configured on the vehicle.
    public var schedules: [PreconditionScheduleEntry]
    /// "Precondition schedule window" entry — a single transient schedule
    /// the user is currently editing. Nil if absent.
    public var pendingScheduleWindow: PreconditionScheduleEntry?
    /// Maximum number of precondition schedules the vehicle can store.
    /// Nil if the vehicle did not report this field.
    public var maxScheduleCount: UInt32?
    /// Whether the next upcoming schedule will run. Nil if not reported.
    public var nextScheduleEnabled: Bool?
    /// Server-assigned timestamp when this section was last updated.
    /// Seconds since the Unix epoch. Nil if not reported.
    public var timestampSecondsSinceEpoch: Int64?

    public init(
        schedules: [PreconditionScheduleEntry] = [],
        pendingScheduleWindow: PreconditionScheduleEntry? = nil,
        maxScheduleCount: UInt32? = nil,
        nextScheduleEnabled: Bool? = nil,
        timestampSecondsSinceEpoch: Int64? = nil,
    ) {
        self.schedules = schedules
        self.pendingScheduleWindow = pendingScheduleWindow
        self.maxScheduleCount = maxScheduleCount
        self.nextScheduleEnabled = nextScheduleEnabled
        self.timestampSecondsSinceEpoch = timestampSecondsSinceEpoch
    }
}

/// A single saved precondition schedule entry.
///
/// Mirrors `CarServer_PreconditionSchedule`. Entry fields are proto3 scalars
/// (no `optional_*` wrapping), so they are non-optional and reflect the
/// raw vehicle-reported value (zero for fields the vehicle leaves unset).
public struct PreconditionScheduleEntry: Sendable, Equatable, Identifiable {
    /// Schedule identifier — datetime in epoch time on the upstream.
    public var id: UInt64
    /// Human-readable name configured by the user.
    public var name: String
    /// Bitfield of weekdays this schedule runs on (upstream bit semantics).
    public var daysOfWeek: Int32
    /// Time at which the cabin should be preconditioned, in minutes
    /// since midnight.
    public var preconditionTimeMinutes: Int32
    /// Whether the schedule fires once and then auto-disables.
    public var oneTime: Bool
    /// Whether the schedule is currently active.
    public var enabled: Bool
    /// Geofence latitude (decimal degrees). 0 if unset.
    public var latitude: Float
    /// Geofence longitude (decimal degrees). 0 if unset.
    public var longitude: Float

    public init(
        id: UInt64,
        name: String = "",
        daysOfWeek: Int32 = 0,
        preconditionTimeMinutes: Int32 = 0,
        oneTime: Bool = false,
        enabled: Bool = false,
        latitude: Float = 0,
        longitude: Float = 0,
    ) {
        self.id = id
        self.name = name
        self.daysOfWeek = daysOfWeek
        self.preconditionTimeMinutes = preconditionTimeMinutes
        self.oneTime = oneTime
        self.enabled = enabled
        self.latitude = latitude
        self.longitude = longitude
    }
}
