import Foundation

/// Cabin climate, seat heater, and defrost status reported by the vehicle.
///
/// Mirrors `CarServer_ClimateState` from the upstream Go SDK. Every field is
/// optional — an absent oneof stays `nil` rather than being defaulted to `0`.
public struct ClimateState: Sendable, Equatable {
    // MARK: Temperatures

    /// Interior cabin temperature in degrees Celsius.
    public var insideTempCelsius: Double?
    /// Exterior ambient temperature in degrees Celsius.
    public var outsideTempCelsius: Double?
    /// Driver-side climate setpoint in degrees Celsius.
    public var driverTempSettingCelsius: Double?
    /// Passenger-side climate setpoint in degrees Celsius.
    public var passengerTempSettingCelsius: Double?
    /// Minimum settable cabin temperature in degrees Celsius.
    public var minAvailTempCelsius: Double?
    /// Maximum settable cabin temperature in degrees Celsius.
    public var maxAvailTempCelsius: Double?

    // MARK: HVAC core

    /// HVAC fan level (raw vehicle scale, typically 0–7).
    public var fanStatus: Int?
    /// True if the HVAC system is currently running.
    public var isClimateOn: Bool?
    /// True if Auto HVAC has the system in automatic-control mode.
    public var isAutoConditioningOn: Bool?
    /// True if a remote / scheduled preconditioning session is active.
    public var isPreconditioning: Bool?
    /// HVAC auto-request override. Indicates whether automatic control is
    /// currently being overridden by a manual request.
    public var hvacAutoRequest: HvacAutoRequest?
    /// Climate-keeper mode (off / on / dog / party).
    public var climateKeeperMode: ClimateKeeperMode?
    /// Front windshield defroster on.
    public var isFrontDefrosterOn: Bool?
    /// Rear window defroster on.
    public var isRearDefrosterOn: Bool?
    /// Defrost-mode level (off / normal / max). Populated from `defrostMode`.
    public var defrostOn: Bool?
    /// True if remote heater control is enabled (some markets gate this).
    public var remoteHeaterControlEnabled: Bool?
    /// Bioweapon Defense Mode active.
    public var bioweaponMode: Bool?

    // MARK: Heaters

    /// Front-left seat heater level.
    public var seatHeaterFrontLeft: SeatHeaterLevel?
    /// Front-right seat heater level.
    public var seatHeaterFrontRight: SeatHeaterLevel?
    /// Rear-left seat heater level.
    public var seatHeaterRearLeft: SeatHeaterLevel?
    /// Rear-center seat heater level.
    public var seatHeaterRearCenter: SeatHeaterLevel?
    /// Rear-right seat heater level.
    public var seatHeaterRearRight: SeatHeaterLevel?
    /// Rear-left seat-back heater level.
    public var seatHeaterRearLeftBack: SeatHeaterLevel?
    /// Rear-right seat-back heater level.
    public var seatHeaterRearRightBack: SeatHeaterLevel?
    /// Third-row left seat heater level.
    public var seatHeaterThirdRowLeft: SeatHeaterLevel?
    /// Third-row right seat heater level.
    public var seatHeaterThirdRowRight: SeatHeaterLevel?
    /// Auto-seat-climate enabled on the front-left seat.
    public var autoSeatClimateLeft: Bool?
    /// Auto-seat-climate enabled on the front-right seat.
    public var autoSeatClimateRight: Bool?
    /// Front-left seat ventilation fan level.
    public var seatFanFrontLeft: Int?
    /// Front-right seat ventilation fan level.
    public var seatFanFrontRight: Int?
    /// Steering-wheel heater on (legacy boolean).
    public var steeringWheelHeater: Bool?
    /// Auto-steering-wheel-heat feature enabled.
    public var autoSteeringWheelHeat: Bool?
    /// Steering-wheel heater intensity setting.
    public var steeringWheelHeatLevel: SteeringWheelHeatLevel?
    /// Wiper-blade heater on (Cybertruck/Refresh).
    public var wiperBladeHeater: Bool?
    /// Side-mirror heaters on.
    public var sideMirrorHeaters: Bool?
    /// True if the high-voltage battery heater is active.
    public var isBatteryHeaterOn: Bool?
    /// True if the battery heater is unable to draw power right now.
    public var isBatteryHeaterNoPower: Bool?

    // MARK: Cabin Overheat Protection (COP)

    /// User has enabled the COP feature in settings.
    public var allowCabinOverheatProtection: Bool?
    /// Vehicle hardware supports the fan-only COP variant.
    public var supportsFanOnlyCabinOverheatProtection: Bool?
    /// Current COP mode (off / on / fan-only).
    public var cabinOverheatProtection: CabinOverheatProtectionMode?
    /// True while COP is actively cooling the cabin.
    public var cabinOverheatProtectionActivelyCooling: Bool?
    /// Cabin temperature threshold at which COP activates.
    public var copActivationTemperature: CopActivationTemperature?
    /// Reason the COP system is not currently running.
    public var copNotRunningReason: CopNotRunningReason?

    // MARK: - Nested enums

    /// Seat heater intensity level. Raw values match the proto enum:
    /// 0 = off, 1 = low, 2 = medium, 3 = high.
    public enum SeatHeaterLevel: Int, Sendable, Equatable {
        case off = 0
        case low = 1
        case medium = 2
        case high = 3
    }

    /// Steering-wheel heater intensity setting.
    public enum SteeringWheelHeatLevel: Sendable, Equatable {
        case unknown
        case off
        case low
        case high
    }

    /// HVAC auto-request override.
    public enum HvacAutoRequest: Sendable, Equatable {
        case on
        case override
    }

    /// Climate-keeper mode.
    public enum ClimateKeeperMode: Sendable, Equatable {
        case unknown
        case off
        case on
        case dog
        case party
    }

    /// Cabin Overheat Protection (COP) state.
    public enum CabinOverheatProtectionMode: Sendable, Equatable {
        case off
        case on
        case fanOnly
    }

    /// COP activation temperature threshold (`unspecified` if the vehicle
    /// did not report a value).
    public enum CopActivationTemperature: Sendable, Equatable {
        case unspecified
        case low
        case medium
        case high
    }

    /// Why COP is currently not running.
    public enum CopNotRunningReason: Sendable, Equatable {
        case noReason
        case userInteraction
        case energyConsumptionReached
        case timeout
        case lowSolarLoad
        case fault
        case cabinBelowThreshold
    }

    public init(
        insideTempCelsius: Double? = nil,
        outsideTempCelsius: Double? = nil,
        driverTempSettingCelsius: Double? = nil,
        passengerTempSettingCelsius: Double? = nil,
        minAvailTempCelsius: Double? = nil,
        maxAvailTempCelsius: Double? = nil,
        fanStatus: Int? = nil,
        isClimateOn: Bool? = nil,
        isAutoConditioningOn: Bool? = nil,
        isPreconditioning: Bool? = nil,
        hvacAutoRequest: HvacAutoRequest? = nil,
        climateKeeperMode: ClimateKeeperMode? = nil,
        isFrontDefrosterOn: Bool? = nil,
        isRearDefrosterOn: Bool? = nil,
        defrostOn: Bool? = nil,
        remoteHeaterControlEnabled: Bool? = nil,
        bioweaponMode: Bool? = nil,
        seatHeaterFrontLeft: SeatHeaterLevel? = nil,
        seatHeaterFrontRight: SeatHeaterLevel? = nil,
        seatHeaterRearLeft: SeatHeaterLevel? = nil,
        seatHeaterRearCenter: SeatHeaterLevel? = nil,
        seatHeaterRearRight: SeatHeaterLevel? = nil,
        seatHeaterRearLeftBack: SeatHeaterLevel? = nil,
        seatHeaterRearRightBack: SeatHeaterLevel? = nil,
        seatHeaterThirdRowLeft: SeatHeaterLevel? = nil,
        seatHeaterThirdRowRight: SeatHeaterLevel? = nil,
        autoSeatClimateLeft: Bool? = nil,
        autoSeatClimateRight: Bool? = nil,
        seatFanFrontLeft: Int? = nil,
        seatFanFrontRight: Int? = nil,
        steeringWheelHeater: Bool? = nil,
        autoSteeringWheelHeat: Bool? = nil,
        steeringWheelHeatLevel: SteeringWheelHeatLevel? = nil,
        wiperBladeHeater: Bool? = nil,
        sideMirrorHeaters: Bool? = nil,
        isBatteryHeaterOn: Bool? = nil,
        isBatteryHeaterNoPower: Bool? = nil,
        allowCabinOverheatProtection: Bool? = nil,
        supportsFanOnlyCabinOverheatProtection: Bool? = nil,
        cabinOverheatProtection: CabinOverheatProtectionMode? = nil,
        cabinOverheatProtectionActivelyCooling: Bool? = nil,
        copActivationTemperature: CopActivationTemperature? = nil,
        copNotRunningReason: CopNotRunningReason? = nil,
    ) {
        self.insideTempCelsius = insideTempCelsius
        self.outsideTempCelsius = outsideTempCelsius
        self.driverTempSettingCelsius = driverTempSettingCelsius
        self.passengerTempSettingCelsius = passengerTempSettingCelsius
        self.minAvailTempCelsius = minAvailTempCelsius
        self.maxAvailTempCelsius = maxAvailTempCelsius
        self.fanStatus = fanStatus
        self.isClimateOn = isClimateOn
        self.isAutoConditioningOn = isAutoConditioningOn
        self.isPreconditioning = isPreconditioning
        self.hvacAutoRequest = hvacAutoRequest
        self.climateKeeperMode = climateKeeperMode
        self.isFrontDefrosterOn = isFrontDefrosterOn
        self.isRearDefrosterOn = isRearDefrosterOn
        self.defrostOn = defrostOn
        self.remoteHeaterControlEnabled = remoteHeaterControlEnabled
        self.bioweaponMode = bioweaponMode
        self.seatHeaterFrontLeft = seatHeaterFrontLeft
        self.seatHeaterFrontRight = seatHeaterFrontRight
        self.seatHeaterRearLeft = seatHeaterRearLeft
        self.seatHeaterRearCenter = seatHeaterRearCenter
        self.seatHeaterRearRight = seatHeaterRearRight
        self.seatHeaterRearLeftBack = seatHeaterRearLeftBack
        self.seatHeaterRearRightBack = seatHeaterRearRightBack
        self.seatHeaterThirdRowLeft = seatHeaterThirdRowLeft
        self.seatHeaterThirdRowRight = seatHeaterThirdRowRight
        self.autoSeatClimateLeft = autoSeatClimateLeft
        self.autoSeatClimateRight = autoSeatClimateRight
        self.seatFanFrontLeft = seatFanFrontLeft
        self.seatFanFrontRight = seatFanFrontRight
        self.steeringWheelHeater = steeringWheelHeater
        self.autoSteeringWheelHeat = autoSteeringWheelHeat
        self.steeringWheelHeatLevel = steeringWheelHeatLevel
        self.wiperBladeHeater = wiperBladeHeater
        self.sideMirrorHeaters = sideMirrorHeaters
        self.isBatteryHeaterOn = isBatteryHeaterOn
        self.isBatteryHeaterNoPower = isBatteryHeaterNoPower
        self.allowCabinOverheatProtection = allowCabinOverheatProtection
        self.supportsFanOnlyCabinOverheatProtection = supportsFanOnlyCabinOverheatProtection
        self.cabinOverheatProtection = cabinOverheatProtection
        self.cabinOverheatProtectionActivelyCooling = cabinOverheatProtectionActivelyCooling
        self.copActivationTemperature = copActivationTemperature
        self.copNotRunningReason = copNotRunningReason
    }
}
