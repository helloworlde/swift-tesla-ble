import Foundation

/// Current battery and charge-port status reported by the vehicle.
///
/// Mirrors `CarServer_ChargeState` from the upstream Go SDK
/// (`pkg/protocol/protobuf/vehicle.proto`). Every field is optional because
/// the vehicle reports each value via a oneof — an absent value stays `nil`
/// rather than being defaulted to `0`.
public struct ChargeState: Sendable, Equatable {
    // MARK: Battery

    /// State of charge in percent (0–100).
    public var batteryLevel: Int?
    /// Usable state of charge in percent. May be lower than `batteryLevel`
    /// when the BMS reserves a buffer (e.g. cold or degraded packs).
    public var usableBatteryLevel: Int?
    /// Rated remaining range in miles.
    public var batteryRangeMiles: Double?
    /// Estimated remaining range in miles based on recent driving energy use.
    public var estBatteryRangeMiles: Double?
    /// Ideal (EPA-equivalent) remaining range in miles.
    public var idealBatteryRangeMiles: Double?

    // MARK: Charging session

    /// High-level charging session status.
    public var chargingStatus: ChargingStatus?
    /// Charger voltage in volts.
    public var chargerVoltage: Int?
    /// Charger actual current draw in amps.
    public var chargerCurrent: Int?
    /// Pilot signal current advertised by the EVSE in amps.
    public var chargerPilotCurrent: Int?
    /// User-configured charge current request in amps.
    public var chargeCurrentRequest: Int?
    /// Maximum allowed charge current request in amps.
    public var chargeCurrentRequestMax: Int?
    /// User charging-amps setting reported by the vehicle.
    public var chargingAmps: Int?
    /// Number of phases currently used by the charger (1 or 3).
    public var chargerPhases: Int?
    /// Charger power in kilowatts.
    public var chargerPower: Int?
    /// Range added per hour of charging in miles per hour.
    public var chargeRateMph: Double?
    /// Estimated minutes remaining until charging completes.
    public var minutesToFullCharge: Int?
    /// Estimated minutes remaining until the configured limit is reached.
    public var minutesToChargeLimit: Int?
    /// Energy added during the current session, in kWh.
    public var chargeEnergyAddedKWh: Double?
    /// Rated miles added during the current session.
    public var chargeMilesAddedRated: Double?
    /// Ideal miles added during the current session.
    public var chargeMilesAddedIdeal: Double?
    /// True while the vehicle is treating the current charge as part of an
    /// active trip (Supercharger trip planner).
    public var tripCharging: Bool?
    /// True when a Supercharger session is being managed by the trip planner.
    public var superchargerSessionTripPlanner: Bool?

    // MARK: Charge limit

    /// User-configured charge limit in percent (0–100).
    public var chargeLimitPercent: Int?
    /// Standard recommended charge limit in percent.
    public var chargeLimitStandardPercent: Int?
    /// Minimum allowed charge limit in percent.
    public var chargeLimitMinPercent: Int?
    /// Maximum allowed charge limit in percent.
    public var chargeLimitMaxPercent: Int?
    /// One-time elevated SoC limit (e.g. set for an upcoming trip), in percent.
    public var oneTimeChargeLimitPercent: Int?
    /// Reason the charge has been limited (e.g. cold pack).
    public var chargeLimitReason: ChargeLimitReason?

    // MARK: Charge port

    /// Whether the charge port door is physically open.
    public var chargePortOpen: Bool?
    /// Charge-port latch state on the connector. Replaces the legacy
    /// `chargePortLatched: Bool?` projection — use `latched == .engaged`
    /// for the equivalent boolean test.
    public var chargePortLatch: ChargePortLatchState?
    /// Cold-weather mode active on the charge port.
    public var chargePortColdWeatherMode: Bool?
    /// Charge port LED color enum.
    public var chargePortColor: ChargePortColor?
    /// True if the cable has been mechanically unlatched.
    public var chargeCableUnlatched: Bool?

    // MARK: Connector

    /// Connector type currently plugged in.
    public var connectedCableType: CableType?
    /// Detected fast charger type (Supercharger / CHAdeMO / etc.).
    public var fastChargerType: FastChargerType?
    /// Detected fast charger brand.
    public var fastChargerBrand: FastChargerBrand?
    /// True when a DC fast charger is currently connected.
    public var fastChargerPresent: Bool?

    // MARK: Schedule

    /// Scheduled charging mode (off / startAt / departBy).
    public var scheduledChargingMode: ScheduledChargingMode?
    /// Whether a scheduled charge is queued.
    public var scheduledChargingPending: Bool?
    /// Scheduled charging start, seconds since the Unix epoch.
    public var scheduledChargingStartTimeSecondsSinceEpoch: UInt64?
    /// Scheduled charging start, minutes from local midnight.
    public var scheduledChargingStartTimeMinutes: UInt32?
    /// App-provided scheduled charging start, minutes from local midnight.
    public var scheduledChargingStartTimeAppMinutes: Int?
    /// Scheduled departure time, minutes from local midnight.
    public var scheduledDepartureTimeMinutes: UInt32?
    /// Off-peak hours end time, minutes from local midnight.
    public var offPeakHoursEndTimeMinutes: UInt32?
    /// Departure-time preconditioning enabled.
    public var preconditioningEnabled: Bool?

    // MARK: Charge enable / managed

    /// User has requested charging be enabled.
    public var userChargeEnableRequest: Bool?
    /// Vehicle has approved charging to start.
    public var chargeEnableRequest: Bool?
    /// Managed-charging service is currently steering charge power.
    public var managedChargingActive: Bool?
    /// User has cancelled managed charging for this session.
    public var managedChargingUserCanceled: Bool?
    /// Managed-charging session start, seconds since the Unix epoch.
    public var managedChargingStartTimeSecondsSinceEpoch: UInt64?

    // MARK: Outlet / power feed (Cybertruck)

    /// 110/120V outlet state for vehicle-to-load.
    public var outletState: OutletState?
    /// Power-feed (V2H/V2L) state.
    public var powerFeedState: OutletState?
    /// Outlet auto-stop SoC limit in percent.
    public var outletSocLimitPercent: Int?
    /// Power-feed auto-stop SoC limit in percent.
    public var powerFeedSocLimitPercent: Int?
    /// Seconds remaining before outlet auto-stop.
    public var outletTimeRemainingSeconds: Int64?
    /// Seconds remaining before power-feed auto-stop.
    public var powerFeedTimeRemainingSeconds: Int64?
    /// Maximum configurable outlet timer in minutes.
    public var outletMaxTimerMinutes: Int?

    // MARK: Powershare (vehicle-to-home/load)

    /// Aggregated Powershare sub-state. Nil if the vehicle reported no
    /// Powershare fields at all.
    public var powershare: PowershareState?

    // MARK: Saved locations

    /// Coordinates the user has saved as "home".
    public var homeLocation: Coordinate?
    /// Coordinates the user has saved as "work".
    public var workLocation: Coordinate?

    // MARK: Departure / day-pattern selection

    /// Counter the BMS increments each time the pack is charged to max range
    /// (used to schedule cell balancing). Nil if the vehicle did not report it.
    public var maxRangeChargeCounter: Int?
    /// Scheduled departure as an absolute instant, seconds since the Unix
    /// epoch. Distinct from ``scheduledDepartureTimeMinutes``, which is a
    /// minutes-from-local-midnight wall-clock value.
    public var scheduledDepartureTimeSecondsSinceEpoch: Int64?
    /// Day pattern the active preconditioning window applies to.
    public var preconditioningTimes: ChargingTimesSelection?
    /// Day pattern the active off-peak charging window applies to.
    public var offPeakChargingTimes: ChargingTimesSelection?

    // MARK: Managed charging (Charge on Solar / Tesla Electric)

    /// Managed-charging detail: Charge-on-Solar session state, gateway DIN, and
    /// Tesla Electric asset id. Nil if the vehicle reported no managed-charging
    /// sub-message.
    public var managedChargingState: ManagedChargingState?

    // MARK: - Nested enums

    /// Day pattern a scheduled charge / precondition window applies to.
    public enum ChargingTimesSelection: Sendable, Equatable {
        case allWeek
        case weekdays
    }

    /// High-level charging session state.
    public enum ChargingStatus: Sendable, Equatable {
        case disconnected
        case charging
        case complete
        case stopped
        case starting
    }

    /// Why the vehicle is capping charge below the user-set limit.
    public enum ChargeLimitReason: Sendable, Equatable {
        case unknown
        case none
        case evse
        case batteryTempLow
        case highSoc
        case cabin
    }

    /// Scheduled-charging selection mode.
    public enum ScheduledChargingMode: Sendable, Equatable {
        case off
        case startAt
        case departBy
    }

    /// Connector-side latch state.
    public enum ChargePortLatchState: Sendable, Equatable {
        case sna
        case disengaged
        case engaged
        case blocking
    }

    /// LED color shown by the charge port (mostly cosmetic).
    public enum ChargePortColor: Sendable, Equatable {
        case off
        case red
        case green
        case blue
        case white
        case flashingGreen
        case flashingAmber
        case amber
        case rave
        case debug
        case flashingBlue
    }

    /// Cable family currently plugged into the vehicle.
    public enum CableType: Sendable, Equatable {
        case sna
        case iec
        case sae
        case gbAc
        case gbDc
    }

    /// Detected DC fast-charger type.
    public enum FastChargerType: Sendable, Equatable {
        case sna
        case supercharger
        case chademo
        case gb
        case acSingleWireCan
        case combo
        case mcSingleWireCan
        case other
        case tesla
    }

    /// Detected DC fast-charger brand.
    public enum FastChargerBrand: Sendable, Equatable {
        case tesla
        case sna
    }

    /// Outlet / power-feed activation state.
    public enum OutletState: Sendable, Equatable {
        case off
        case cabinAndBed
        case cabin
    }

    public init(
        batteryLevel: Int? = nil,
        usableBatteryLevel: Int? = nil,
        batteryRangeMiles: Double? = nil,
        estBatteryRangeMiles: Double? = nil,
        idealBatteryRangeMiles: Double? = nil,
        chargingStatus: ChargingStatus? = nil,
        chargerVoltage: Int? = nil,
        chargerCurrent: Int? = nil,
        chargerPilotCurrent: Int? = nil,
        chargeCurrentRequest: Int? = nil,
        chargeCurrentRequestMax: Int? = nil,
        chargingAmps: Int? = nil,
        chargerPhases: Int? = nil,
        chargerPower: Int? = nil,
        chargeRateMph: Double? = nil,
        minutesToFullCharge: Int? = nil,
        minutesToChargeLimit: Int? = nil,
        chargeEnergyAddedKWh: Double? = nil,
        chargeMilesAddedRated: Double? = nil,
        chargeMilesAddedIdeal: Double? = nil,
        tripCharging: Bool? = nil,
        superchargerSessionTripPlanner: Bool? = nil,
        chargeLimitPercent: Int? = nil,
        chargeLimitStandardPercent: Int? = nil,
        chargeLimitMinPercent: Int? = nil,
        chargeLimitMaxPercent: Int? = nil,
        oneTimeChargeLimitPercent: Int? = nil,
        chargeLimitReason: ChargeLimitReason? = nil,
        chargePortOpen: Bool? = nil,
        chargePortLatch: ChargePortLatchState? = nil,
        chargePortColdWeatherMode: Bool? = nil,
        chargePortColor: ChargePortColor? = nil,
        chargeCableUnlatched: Bool? = nil,
        connectedCableType: CableType? = nil,
        fastChargerType: FastChargerType? = nil,
        fastChargerBrand: FastChargerBrand? = nil,
        fastChargerPresent: Bool? = nil,
        scheduledChargingMode: ScheduledChargingMode? = nil,
        scheduledChargingPending: Bool? = nil,
        scheduledChargingStartTimeSecondsSinceEpoch: UInt64? = nil,
        scheduledChargingStartTimeMinutes: UInt32? = nil,
        scheduledChargingStartTimeAppMinutes: Int? = nil,
        scheduledDepartureTimeMinutes: UInt32? = nil,
        offPeakHoursEndTimeMinutes: UInt32? = nil,
        preconditioningEnabled: Bool? = nil,
        userChargeEnableRequest: Bool? = nil,
        chargeEnableRequest: Bool? = nil,
        managedChargingActive: Bool? = nil,
        managedChargingUserCanceled: Bool? = nil,
        managedChargingStartTimeSecondsSinceEpoch: UInt64? = nil,
        outletState: OutletState? = nil,
        powerFeedState: OutletState? = nil,
        outletSocLimitPercent: Int? = nil,
        powerFeedSocLimitPercent: Int? = nil,
        outletTimeRemainingSeconds: Int64? = nil,
        powerFeedTimeRemainingSeconds: Int64? = nil,
        outletMaxTimerMinutes: Int? = nil,
        powershare: PowershareState? = nil,
        homeLocation: Coordinate? = nil,
        workLocation: Coordinate? = nil,
        maxRangeChargeCounter: Int? = nil,
        scheduledDepartureTimeSecondsSinceEpoch: Int64? = nil,
        preconditioningTimes: ChargingTimesSelection? = nil,
        offPeakChargingTimes: ChargingTimesSelection? = nil,
        managedChargingState: ManagedChargingState? = nil,
    ) {
        self.batteryLevel = batteryLevel
        self.usableBatteryLevel = usableBatteryLevel
        self.batteryRangeMiles = batteryRangeMiles
        self.estBatteryRangeMiles = estBatteryRangeMiles
        self.idealBatteryRangeMiles = idealBatteryRangeMiles
        self.chargingStatus = chargingStatus
        self.chargerVoltage = chargerVoltage
        self.chargerCurrent = chargerCurrent
        self.chargerPilotCurrent = chargerPilotCurrent
        self.chargeCurrentRequest = chargeCurrentRequest
        self.chargeCurrentRequestMax = chargeCurrentRequestMax
        self.chargingAmps = chargingAmps
        self.chargerPhases = chargerPhases
        self.chargerPower = chargerPower
        self.chargeRateMph = chargeRateMph
        self.minutesToFullCharge = minutesToFullCharge
        self.minutesToChargeLimit = minutesToChargeLimit
        self.chargeEnergyAddedKWh = chargeEnergyAddedKWh
        self.chargeMilesAddedRated = chargeMilesAddedRated
        self.chargeMilesAddedIdeal = chargeMilesAddedIdeal
        self.tripCharging = tripCharging
        self.superchargerSessionTripPlanner = superchargerSessionTripPlanner
        self.chargeLimitPercent = chargeLimitPercent
        self.chargeLimitStandardPercent = chargeLimitStandardPercent
        self.chargeLimitMinPercent = chargeLimitMinPercent
        self.chargeLimitMaxPercent = chargeLimitMaxPercent
        self.oneTimeChargeLimitPercent = oneTimeChargeLimitPercent
        self.chargeLimitReason = chargeLimitReason
        self.chargePortOpen = chargePortOpen
        self.chargePortLatch = chargePortLatch
        self.chargePortColdWeatherMode = chargePortColdWeatherMode
        self.chargePortColor = chargePortColor
        self.chargeCableUnlatched = chargeCableUnlatched
        self.connectedCableType = connectedCableType
        self.fastChargerType = fastChargerType
        self.fastChargerBrand = fastChargerBrand
        self.fastChargerPresent = fastChargerPresent
        self.scheduledChargingMode = scheduledChargingMode
        self.scheduledChargingPending = scheduledChargingPending
        self.scheduledChargingStartTimeSecondsSinceEpoch = scheduledChargingStartTimeSecondsSinceEpoch
        self.scheduledChargingStartTimeMinutes = scheduledChargingStartTimeMinutes
        self.scheduledChargingStartTimeAppMinutes = scheduledChargingStartTimeAppMinutes
        self.scheduledDepartureTimeMinutes = scheduledDepartureTimeMinutes
        self.offPeakHoursEndTimeMinutes = offPeakHoursEndTimeMinutes
        self.preconditioningEnabled = preconditioningEnabled
        self.userChargeEnableRequest = userChargeEnableRequest
        self.chargeEnableRequest = chargeEnableRequest
        self.managedChargingActive = managedChargingActive
        self.managedChargingUserCanceled = managedChargingUserCanceled
        self.managedChargingStartTimeSecondsSinceEpoch = managedChargingStartTimeSecondsSinceEpoch
        self.outletState = outletState
        self.powerFeedState = powerFeedState
        self.outletSocLimitPercent = outletSocLimitPercent
        self.powerFeedSocLimitPercent = powerFeedSocLimitPercent
        self.outletTimeRemainingSeconds = outletTimeRemainingSeconds
        self.powerFeedTimeRemainingSeconds = powerFeedTimeRemainingSeconds
        self.outletMaxTimerMinutes = outletMaxTimerMinutes
        self.powershare = powershare
        self.homeLocation = homeLocation
        self.workLocation = workLocation
        self.maxRangeChargeCounter = maxRangeChargeCounter
        self.scheduledDepartureTimeSecondsSinceEpoch = scheduledDepartureTimeSecondsSinceEpoch
        self.preconditioningTimes = preconditioningTimes
        self.offPeakChargingTimes = offPeakChargingTimes
        self.managedChargingState = managedChargingState
    }
}

/// Managed-charging (Charge on Solar / Tesla Electric) sub-state of
/// `ChargeState`.
///
/// Mirrors `CarServer_ManagedChargingState`. Every field is optional — an
/// absent value stays `nil` rather than being defaulted.
public struct ManagedChargingState: Sendable, Equatable {
    /// Charge-on-Solar session state, if the vehicle reported one.
    public var chargeOnSolarState: ChargeOnSolarState?
    /// DIN of the energy gateway steering this Charge-on-Solar session.
    public var chargeOnSolarGatewayDin: String?
    /// Tesla Electric asset id associated with managed charging.
    public var teslaElectricAssetId: String?
    /// Minutes until the managed-charging service lowers the charge limit.
    public var minutesToLowerLimit: Int?

    public init(
        chargeOnSolarState: ChargeOnSolarState? = nil,
        chargeOnSolarGatewayDin: String? = nil,
        teslaElectricAssetId: String? = nil,
        minutesToLowerLimit: Int? = nil,
    ) {
        self.chargeOnSolarState = chargeOnSolarState
        self.chargeOnSolarGatewayDin = chargeOnSolarGatewayDin
        self.teslaElectricAssetId = teslaElectricAssetId
        self.minutesToLowerLimit = minutesToLowerLimit
    }
}

/// State of the Charge-on-Solar managed-charging feature.
///
/// Mirrors the `state` oneof of `CarServer_ChargeOnSolarState`.
public enum ChargeOnSolarState: Sendable, Equatable {
    /// Conditions do not support Charge on Solar (e.g. not at a managed site).
    case notAllowed
    /// The site controller is recommending no charge, for the given reason.
    case noChargeRecommended(reason: ChargeOnSolarNoChargeReason)
    /// The vehicle is actively following the recommended excess-solar power.
    case chargingOnExcessSolar
    /// The vehicle is charging at full power on any source.
    case chargingOnAnything
    /// The user disabled the Charge-on-Solar feature.
    case userDisabled
    /// Waiting for the first response from the site controller.
    case waitingForServer
    /// The charging manager stopped following set points after repeated errors.
    case error
    /// The user pressed Stop Charging during a Charge-on-Solar session.
    case userStopped
}

/// Highest-priority reason the site controller recommends no charge.
///
/// Mirrors `ManagedCharging.ChargeOnSolarNoChargeReason`.
public enum ChargeOnSolarNoChargeReason: Sendable, Equatable {
    /// Invalid / unspecified reason.
    case invalid
    /// The Powerwall is being prioritized over the vehicle.
    case powerwallChargePriority
    /// Not enough solar for the vehicle to charge effectively.
    case insufficientSolar
    /// The site controller is prioritizing export to the grid.
    case gridExportPriority
    /// Another vehicle charging on solar at this location has priority.
    case alternateVehicleChargePriority
}

/// Powershare (V2H / V2L) sub-state of `ChargeState`.
public struct PowershareState: Sendable, Equatable {
    /// Powershare hardware/software is allowed for this VIN.
    public var featureAllowed: Bool?
    /// User has enabled the Powershare feature.
    public var featureEnabled: Bool?
    /// User has requested Powershare to start now.
    public var requestActive: Bool?
    /// What the vehicle is sharing power into.
    public var type: PowershareType?
    /// Lifecycle state of the current sharing session.
    public var status: PowershareStatus?
    /// Reason the most recent session stopped.
    public var stopReason: PowershareStopReason?
    /// Instantaneous load draw in kilowatts.
    public var instantaneousLoadKW: Double?
    /// Hours of energy left in the pack at the current load.
    public var vehicleEnergyLeftHours: Int?
    /// SoC floor below which Powershare auto-stops.
    public var socLimitPercent: Int?

    public enum PowershareType: Sendable, Equatable {
        case none
        case load
        case home
    }

    public enum PowershareStatus: Sendable, Equatable {
        case inactive
        case initializing
        case active
        case stopped
        case handshaking
        case activeReconnectingSoon
    }

    public enum PowershareStopReason: Sendable, Equatable {
        case none
        case socTooLow
        case retry
        case fault
        case user
        case reconnecting
        case authentication
    }

    public init(
        featureAllowed: Bool? = nil,
        featureEnabled: Bool? = nil,
        requestActive: Bool? = nil,
        type: PowershareType? = nil,
        status: PowershareStatus? = nil,
        stopReason: PowershareStopReason? = nil,
        instantaneousLoadKW: Double? = nil,
        vehicleEnergyLeftHours: Int? = nil,
        socLimitPercent: Int? = nil,
    ) {
        self.featureAllowed = featureAllowed
        self.featureEnabled = featureEnabled
        self.requestActive = requestActive
        self.type = type
        self.status = status
        self.stopReason = stopReason
        self.instantaneousLoadKW = instantaneousLoadKW
        self.vehicleEnergyLeftHours = vehicleEnergyLeftHours
        self.socLimitPercent = socLimitPercent
    }
}
