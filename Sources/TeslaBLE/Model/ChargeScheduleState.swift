import Foundation

/// Vehicle's scheduled-charging configuration.
///
/// Mirrors `CarServer_ChargeScheduleState` plus its repeated
/// `CarServer_ChargeSchedule` entries. Top-level fields use Swift `nil` to
/// represent "vehicle did not report", matching the upstream
/// `optional_*` proto oneofs.
public struct ChargeScheduleState: Sendable, Equatable {
    /// All saved charge schedules currently configured on the vehicle.
    public var schedules: [ChargeScheduleEntry]
    /// "Charge schedule window" entry — a single transient schedule the user
    /// is currently editing. Nil if absent.
    public var pendingScheduleWindow: ChargeScheduleEntry?
    /// Buffer (minutes) the vehicle adds before the scheduled start time.
    /// Nil if the vehicle did not report this field.
    public var chargeBufferMinutes: Int?
    /// Maximum number of charge schedules the vehicle can store. Nil if
    /// the vehicle did not report this field.
    public var maxScheduleCount: UInt32?
    /// Whether the next upcoming schedule will run. Nil if not reported.
    public var nextScheduleEnabled: Bool?
    /// Whether the vehicle should display the "schedule complete" UI state.
    /// Nil if not reported.
    public var showScheduleCompleteState: Bool?
    /// Server-assigned timestamp when this section was last updated.
    /// Seconds since the Unix epoch. Nil if not reported.
    public var timestampSecondsSinceEpoch: Int64?

    public init(
        schedules: [ChargeScheduleEntry] = [],
        pendingScheduleWindow: ChargeScheduleEntry? = nil,
        chargeBufferMinutes: Int? = nil,
        maxScheduleCount: UInt32? = nil,
        nextScheduleEnabled: Bool? = nil,
        showScheduleCompleteState: Bool? = nil,
        timestampSecondsSinceEpoch: Int64? = nil,
    ) {
        self.schedules = schedules
        self.pendingScheduleWindow = pendingScheduleWindow
        self.chargeBufferMinutes = chargeBufferMinutes
        self.maxScheduleCount = maxScheduleCount
        self.nextScheduleEnabled = nextScheduleEnabled
        self.showScheduleCompleteState = showScheduleCompleteState
        self.timestampSecondsSinceEpoch = timestampSecondsSinceEpoch
    }
}

/// A single saved charge schedule entry.
///
/// Mirrors `CarServer_ChargeSchedule`. Entry fields are proto3 scalars
/// (no `optional_*` wrapping), so they are non-optional and reflect the
/// raw vehicle-reported value (zero for fields the vehicle leaves unset).
public struct ChargeScheduleEntry: Sendable, Equatable, Identifiable {
    /// Schedule identifier — datetime in epoch time on the upstream.
    public var id: UInt64
    /// Human-readable name configured by the user.
    public var name: String
    /// Bitfield of weekdays this schedule runs on (upstream bit semantics).
    public var daysOfWeek: Int32
    /// Whether the schedule has a start time configured.
    public var startEnabled: Bool
    /// Start-of-window, in minutes since midnight.
    public var startTimeMinutes: Int32
    /// Whether the schedule has an end time configured.
    public var endEnabled: Bool
    /// End-of-window, in minutes since midnight.
    public var endTimeMinutes: Int32
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
        startEnabled: Bool = false,
        startTimeMinutes: Int32 = 0,
        endEnabled: Bool = false,
        endTimeMinutes: Int32 = 0,
        oneTime: Bool = false,
        enabled: Bool = false,
        latitude: Float = 0,
        longitude: Float = 0,
    ) {
        self.id = id
        self.name = name
        self.daysOfWeek = daysOfWeek
        self.startEnabled = startEnabled
        self.startTimeMinutes = startTimeMinutes
        self.endEnabled = endEnabled
        self.endTimeMinutes = endTimeMinutes
        self.oneTime = oneTime
        self.enabled = enabled
        self.latitude = latitude
        self.longitude = longitude
    }
}
