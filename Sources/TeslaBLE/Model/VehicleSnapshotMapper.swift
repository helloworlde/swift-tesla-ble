import Foundation
import SwiftProtobuf

// MARK: - VehicleSnapshotMapper

/// Internal bridge from `CarServer_*` protobuf types to the public Swift-native
/// model types in this module.
///
/// This is the only file inside `Sources/` that references `CarServer_*`
/// protobuf types; every other layer works exclusively with the Swift-native
/// models so the protobuf surface never leaks into public API.
enum VehicleSnapshotMapper {
    // MARK: - Public API

    static func map(_ data: CarServer_VehicleData) -> TeslaVehicleSnapshot {
        TeslaVehicleSnapshot(
            charge: data.hasChargeState ? mapCharge(data.chargeState) : nil,
            climate: data.hasClimateState ? mapClimate(data.climateState) : nil,
            drive: data.hasDriveState ? mapDrive(data.driveState) : nil,
            location: data.hasLocationState ? mapLocation(data.locationState) : nil,
            closures: data.hasClosuresState ? mapClosures(data.closuresState) : nil,
            tirePressure: data.hasTirePressureState ? mapTirePressure(data.tirePressureState) : nil,
            media: data.hasMediaState ? mapMedia(data.mediaState) : nil,
            mediaDetail: data.hasMediaDetailState ? mapMediaDetail(data.mediaDetailState) : nil,
            softwareUpdate: data.hasSoftwareUpdateState ? mapSoftwareUpdate(data.softwareUpdateState) : nil,
            chargeSchedule: data.hasChargeScheduleState ? mapChargeSchedule(data.chargeScheduleState) : nil,
            preconditionSchedule: data.hasPreconditioningScheduleState
                ? mapPreconditionSchedule(data.preconditioningScheduleState) : nil,
            parentalControls: data.hasParentalControlsState ? mapParentalControls(data.parentalControlsState) : nil,
        )
    }

    /// Fast path used by high-frequency drive-state polls: extracts only the
    /// drive sub-section from a full `CarServer_VehicleData` payload and
    /// returns an empty `DriveState` if none is present.
    static func mapDrive(_ data: CarServer_VehicleData) -> DriveState {
        guard data.hasDriveState else { return DriveState() }
        return mapDrive(data.driveState)
    }

    // MARK: - Sub-state mappers

    private static func mapCharge(_ pb: CarServer_ChargeState) -> ChargeState {
        // `chargeRateMphFloat` is preferred over the legacy integer
        // `chargeRateMph` when present.
        let chargeRate: Double? = {
            if pb.optionalChargeRateMphFloat != nil { return Double(pb.chargeRateMphFloat) }
            if pb.optionalChargeRateMph != nil { return Double(pb.chargeRateMph) }
            return nil
        }()

        let powershare = mapPowershare(pb)

        return ChargeState(
            batteryLevel: pb.optionalBatteryLevel != nil ? Int(pb.batteryLevel) : nil,
            usableBatteryLevel: pb.optionalUsableBatteryLevel != nil ? Int(pb.usableBatteryLevel) : nil,
            batteryRangeMiles: pb.optionalBatteryRange != nil ? Double(pb.batteryRange) : nil,
            estBatteryRangeMiles: pb.optionalEstBatteryRange != nil ? Double(pb.estBatteryRange) : nil,
            idealBatteryRangeMiles: pb.optionalIdealBatteryRange != nil ? Double(pb.idealBatteryRange) : nil,
            chargingStatus: pb.hasChargingState ? mapChargingStatus(pb.chargingState) : nil,
            chargerVoltage: pb.optionalChargerVoltage != nil ? Int(pb.chargerVoltage) : nil,
            chargerCurrent: pb.optionalChargerActualCurrent != nil ? Int(pb.chargerActualCurrent) : nil,
            chargerPilotCurrent: pb.optionalChargerPilotCurrent != nil ? Int(pb.chargerPilotCurrent) : nil,
            chargeCurrentRequest: pb.optionalChargeCurrentRequest != nil ? Int(pb.chargeCurrentRequest) : nil,
            chargeCurrentRequestMax: pb.optionalChargeCurrentRequestMax != nil ? Int(pb.chargeCurrentRequestMax) : nil,
            chargingAmps: pb.optionalChargingAmps != nil ? Int(pb.chargingAmps) : nil,
            chargerPhases: pb.optionalChargerPhases != nil ? Int(pb.chargerPhases) : nil,
            chargerPower: pb.optionalChargerPower != nil ? Int(pb.chargerPower) : nil,
            chargeRateMph: chargeRate,
            minutesToFullCharge: pb.optionalMinutesToFullCharge != nil ? Int(pb.minutesToFullCharge) : nil,
            minutesToChargeLimit: pb.optionalMinutesToChargeLimit != nil ? Int(pb.minutesToChargeLimit) : nil,
            chargeEnergyAddedKWh: pb.optionalChargeEnergyAdded != nil ? Double(pb.chargeEnergyAdded) : nil,
            chargeMilesAddedRated: pb.optionalChargeMilesAddedRated != nil ? Double(pb.chargeMilesAddedRated) : nil,
            chargeMilesAddedIdeal: pb.optionalChargeMilesAddedIdeal != nil ? Double(pb.chargeMilesAddedIdeal) : nil,
            tripCharging: pb.optionalTripCharging != nil ? pb.tripCharging : nil,
            superchargerSessionTripPlanner: pb.optionalSuperchargerSessionTripPlanner != nil
                ? pb.superchargerSessionTripPlanner : nil,
            chargeLimitPercent: pb.optionalChargeLimitSoc != nil ? Int(pb.chargeLimitSoc) : nil,
            chargeLimitStandardPercent: pb.optionalChargeLimitSocStd != nil ? Int(pb.chargeLimitSocStd) : nil,
            chargeLimitMinPercent: pb.optionalChargeLimitSocMin != nil ? Int(pb.chargeLimitSocMin) : nil,
            chargeLimitMaxPercent: pb.optionalChargeLimitSocMax != nil ? Int(pb.chargeLimitSocMax) : nil,
            oneTimeChargeLimitPercent: pb.optionalOneTimeSocLimit != nil ? Int(pb.oneTimeSocLimit) : nil,
            chargeLimitReason: pb.optionalChargeLimitReason != nil
                ? mapChargeLimitReason(pb.chargeLimitReason) : nil,
            chargePortOpen: pb.optionalChargePortDoorOpen != nil ? pb.chargePortDoorOpen : nil,
            chargePortLatch: pb.hasChargePortLatch ? mapChargePortLatch(pb.chargePortLatch) : nil,
            chargePortColdWeatherMode: pb.optionalChargePortColdWeatherMode != nil
                ? pb.chargePortColdWeatherMode : nil,
            chargePortColor: pb.optionalChargePortColor != nil ? mapChargePortColor(pb.chargePortColor) : nil,
            chargeCableUnlatched: pb.optionalChargeCableUnlatched != nil ? pb.chargeCableUnlatched : nil,
            connectedCableType: pb.hasConnChargeCable ? mapCableType(pb.connChargeCable) : nil,
            fastChargerType: pb.hasFastChargerType ? mapFastChargerType(pb.fastChargerType) : nil,
            fastChargerBrand: pb.hasFastChargerBrand ? mapFastChargerBrand(pb.fastChargerBrand) : nil,
            fastChargerPresent: pb.optionalFastChargerPresent != nil ? pb.fastChargerPresent : nil,
            scheduledChargingMode: pb.optionalScheduledChargingMode != nil
                ? mapScheduledChargingMode(pb.scheduledChargingMode) : nil,
            scheduledChargingPending: pb.optionalScheduledChargingPending != nil
                ? pb.scheduledChargingPending : nil,
            scheduledChargingStartTimeSecondsSinceEpoch: pb.optionalScheduledChargingStartTime != nil
                ? pb.scheduledChargingStartTime : nil,
            scheduledChargingStartTimeMinutes: pb.optionalScheduledChargingStartTimeMinutes != nil
                ? pb.scheduledChargingStartTimeMinutes : nil,
            scheduledChargingStartTimeAppMinutes: pb.optionalScheduledChargingStartTimeApp != nil
                ? Int(pb.scheduledChargingStartTimeApp) : nil,
            scheduledDepartureTimeMinutes: pb.optionalScheduledDepartureTimeMinutes != nil
                ? pb.scheduledDepartureTimeMinutes : nil,
            offPeakHoursEndTimeMinutes: pb.optionalOffPeakHoursEndTime != nil
                ? pb.offPeakHoursEndTime : nil,
            preconditioningEnabled: pb.optionalPreconditioningEnabled != nil
                ? pb.preconditioningEnabled : nil,
            userChargeEnableRequest: pb.optionalUserChargeEnableRequest != nil
                ? pb.userChargeEnableRequest : nil,
            chargeEnableRequest: pb.optionalChargeEnableRequest != nil
                ? pb.chargeEnableRequest : nil,
            managedChargingActive: pb.optionalManagedChargingActive != nil
                ? pb.managedChargingActive : nil,
            managedChargingUserCanceled: pb.optionalManagedChargingUserCanceled != nil
                ? pb.managedChargingUserCanceled : nil,
            managedChargingStartTimeSecondsSinceEpoch: pb.optionalManagedChargingStartTime != nil
                ? pb.managedChargingStartTime : nil,
            outletState: pb.optionalOutletState != nil ? mapOutletState(pb.outletState) : nil,
            powerFeedState: pb.optionalPowerFeedState != nil ? mapPowerFeedState(pb.powerFeedState) : nil,
            outletSocLimitPercent: pb.optionOutletSocLimit != nil ? Int(pb.outletSocLimit) : nil,
            powerFeedSocLimitPercent: pb.optionPowerFeedSocLimit != nil ? Int(pb.powerFeedSocLimit) : nil,
            outletTimeRemainingSeconds: pb.optionOutletTimeRemaining != nil ? pb.outletTimeRemaining : nil,
            powerFeedTimeRemainingSeconds: pb.optionPowerFeedTimeRemaining != nil
                ? pb.powerFeedTimeRemaining : nil,
            outletMaxTimerMinutes: pb.optionalOutletMaxTimerMinutes != nil
                ? Int(pb.outletMaxTimerMinutes) : nil,
            powershare: powershare,
            homeLocation: pb.optionalHomeLocation != nil ? mapLatLong(pb.homeLocation) : nil,
            workLocation: pb.optionalWorkLocation != nil ? mapLatLong(pb.workLocation) : nil,
        )
    }

    private static func mapPowershare(_ pb: CarServer_ChargeState) -> PowershareState? {
        let anyField = pb.optionalPowershareFeatureAllowed != nil
            || pb.optionalPowershareFeatureEnabled != nil
            || pb.optionalPowershareRequest != nil
            || pb.optionalPowershareType != nil
            || pb.optionalPowershareStatus != nil
            || pb.optionalPowershareStopReason != nil
            || pb.optionalPowershareInstantaneousLoadKw != nil
            || pb.optionalPowershareVehicleEnergyLeftHr != nil
            || pb.optionalPowershareSocLimit != nil
        guard anyField else { return nil }
        return PowershareState(
            featureAllowed: pb.optionalPowershareFeatureAllowed != nil ? pb.powershareFeatureAllowed : nil,
            featureEnabled: pb.optionalPowershareFeatureEnabled != nil ? pb.powershareFeatureEnabled : nil,
            requestActive: pb.optionalPowershareRequest != nil ? pb.powershareRequest : nil,
            type: pb.optionalPowershareType != nil ? mapPowershareType(pb.powershareType) : nil,
            status: pb.optionalPowershareStatus != nil ? mapPowershareStatus(pb.powershareStatus) : nil,
            stopReason: pb.optionalPowershareStopReason != nil
                ? mapPowershareStopReason(pb.powershareStopReason) : nil,
            instantaneousLoadKW: pb.optionalPowershareInstantaneousLoadKw != nil
                ? Double(pb.powershareInstantaneousLoadKw) : nil,
            vehicleEnergyLeftHours: pb.optionalPowershareVehicleEnergyLeftHr != nil
                ? Int(pb.powershareVehicleEnergyLeftHr) : nil,
            socLimitPercent: pb.optionalPowershareSocLimit != nil ? Int(pb.powershareSocLimit) : nil,
        )
    }

    private static func mapLatLong(_ pb: CarServer_LatLong) -> Coordinate {
        Coordinate(latitude: Double(pb.latitude), longitude: Double(pb.longitude))
    }

    private static func mapClimate(_ pb: CarServer_ClimateState) -> ClimateState {
        ClimateState(
            insideTempCelsius: pb.optionalInsideTempCelsius != nil
                ? Double(pb.insideTempCelsius) : nil,
            outsideTempCelsius: pb.optionalOutsideTempCelsius != nil
                ? Double(pb.outsideTempCelsius) : nil,
            driverTempSettingCelsius: pb.optionalDriverTempSetting != nil
                ? Double(pb.driverTempSetting) : nil,
            passengerTempSettingCelsius: pb.optionalPassengerTempSetting != nil
                ? Double(pb.passengerTempSetting) : nil,
            minAvailTempCelsius: pb.optionalMinAvailTempCelsius != nil
                ? Double(pb.minAvailTempCelsius) : nil,
            maxAvailTempCelsius: pb.optionalMaxAvailTempCelsius != nil
                ? Double(pb.maxAvailTempCelsius) : nil,
            fanStatus: pb.optionalFanStatus != nil ? Int(pb.fanStatus) : nil,
            isClimateOn: pb.optionalIsClimateOn != nil ? pb.isClimateOn : nil,
            isAutoConditioningOn: pb.optionalIsAutoConditioningOn != nil
                ? pb.isAutoConditioningOn : nil,
            isPreconditioning: pb.optionalIsPreconditioning != nil
                ? pb.isPreconditioning : nil,
            hvacAutoRequest: pb.optionalHvacAutoRequest != nil
                ? mapHvacAutoRequest(pb.hvacAutoRequest) : nil,
            climateKeeperMode: pb.hasClimateKeeperMode
                ? mapClimateKeeperMode(pb.climateKeeperMode) : nil,
            isFrontDefrosterOn: pb.optionalIsFrontDefrosterOn != nil
                ? pb.isFrontDefrosterOn : nil,
            isRearDefrosterOn: pb.optionalIsRearDefrosterOn != nil
                ? pb.isRearDefrosterOn : nil,
            defrostOn: pb.hasDefrostMode ? mapDefrost(pb.defrostMode) : nil,
            remoteHeaterControlEnabled: pb.optionalRemoteHeaterControlEnabled != nil
                ? pb.remoteHeaterControlEnabled : nil,
            bioweaponMode: pb.optionalBioweaponModeOn != nil ? pb.bioweaponModeOn : nil,
            seatHeaterFrontLeft: pb.optionalSeatHeaterLeft != nil
                ? mapSeatHeater(pb.seatHeaterLeft) : nil,
            seatHeaterFrontRight: pb.optionalSeatHeaterRight != nil
                ? mapSeatHeater(pb.seatHeaterRight) : nil,
            seatHeaterRearLeft: pb.optionalSeatHeaterRearLeft != nil
                ? mapSeatHeater(pb.seatHeaterRearLeft) : nil,
            seatHeaterRearCenter: pb.optionalSeatHeaterRearCenter != nil
                ? mapSeatHeater(pb.seatHeaterRearCenter) : nil,
            seatHeaterRearRight: pb.optionalSeatHeaterRearRight != nil
                ? mapSeatHeater(pb.seatHeaterRearRight) : nil,
            seatHeaterRearLeftBack: pb.optionalSeatHeaterRearLeftBack != nil
                ? mapSeatHeater(pb.seatHeaterRearLeftBack) : nil,
            seatHeaterRearRightBack: pb.optionalSeatHeaterRearRightBack != nil
                ? mapSeatHeater(pb.seatHeaterRearRightBack) : nil,
            seatHeaterThirdRowLeft: pb.optionalSeatHeaterThirdRowLeft != nil
                ? mapSeatHeater(pb.seatHeaterThirdRowLeft) : nil,
            seatHeaterThirdRowRight: pb.optionalSeatHeaterThirdRowRight != nil
                ? mapSeatHeater(pb.seatHeaterThirdRowRight) : nil,
            autoSeatClimateLeft: pb.optionalAutoSeatClimateLeft != nil
                ? pb.autoSeatClimateLeft : nil,
            autoSeatClimateRight: pb.optionalAutoSeatClimateRight != nil
                ? pb.autoSeatClimateRight : nil,
            seatFanFrontLeft: pb.optionalSeatFanFrontLeft != nil
                ? Int(pb.seatFanFrontLeft) : nil,
            seatFanFrontRight: pb.optionalSeatFanFrontRight != nil
                ? Int(pb.seatFanFrontRight) : nil,
            steeringWheelHeater: pb.optionalSteeringWheelHeater != nil
                ? pb.steeringWheelHeater : nil,
            autoSteeringWheelHeat: pb.optionalAutoSteeringWheelHeat != nil
                ? pb.autoSteeringWheelHeat : nil,
            steeringWheelHeatLevel: pb.optionalSteeringWheelHeatLevel != nil
                ? mapSteeringWheelHeatLevel(pb.steeringWheelHeatLevel) : nil,
            wiperBladeHeater: pb.optionalWiperBladeHeater != nil
                ? pb.wiperBladeHeater : nil,
            sideMirrorHeaters: pb.optionalSideMirrorHeaters != nil
                ? pb.sideMirrorHeaters : nil,
            isBatteryHeaterOn: pb.optionalBatteryHeater != nil ? pb.batteryHeater : nil,
            isBatteryHeaterNoPower: pb.optionalBatteryHeaterNoPower != nil
                ? pb.batteryHeaterNoPower : nil,
            allowCabinOverheatProtection: pb.optionalAllowCabinOverheatProtection != nil
                ? pb.allowCabinOverheatProtection : nil,
            supportsFanOnlyCabinOverheatProtection: pb.optionalSupportsFanOnlyCabinOverheatProtection != nil
                ? pb.supportsFanOnlyCabinOverheatProtection : nil,
            cabinOverheatProtection: pb.optionalCabinOverheatProtection != nil
                ? mapCabinOverheatProtection(pb.cabinOverheatProtection) : nil,
            cabinOverheatProtectionActivelyCooling: pb.optionalCabinOverheatProtectionActivelyCooling != nil
                ? pb.cabinOverheatProtectionActivelyCooling : nil,
            copActivationTemperature: pb.optionalCopActivationTemperature != nil
                ? mapCopActivationTemp(pb.copActivationTemperature) : nil,
            copNotRunningReason: pb.optionalCopNotRunningReason != nil
                ? mapCopNotRunningReason(pb.copNotRunningReason) : nil,
        )
    }

    private static func mapDrive(_ pb: CarServer_DriveState) -> DriveState {
        let shiftState = pb.hasShiftState ? mapShift(pb.shiftState) : nil
        let speedMph: Double? = pb.optionalSpeedFloat != nil ? Double(pb.speedFloat) : nil
        let powerKW: Int? = pb.optionalPower != nil ? Int(pb.power) : nil
        let odometerHundredthsMile: Int? = pb.optionalOdometerInHundredthsOfAMile != nil
            ? Int(pb.odometerInHundredthsOfAMile) : nil
        let destination: String? = pb.optionalActiveRouteDestination != nil
            ? pb.activeRouteDestination : nil
        let minutesToArrival: Double? = pb.optionalActiveRouteMinutesToArrival != nil
            ? Double(pb.activeRouteMinutesToArrival) : nil
        let milesToArrival: Double? = pb.optionalActiveRouteMilesToArrival != nil
            ? Double(pb.activeRouteMilesToArrival) : nil
        let trafficDelay: Double? = pb.optionalActiveRouteTrafficMinutesDelay != nil
            ? Double(pb.activeRouteTrafficMinutesDelay) : nil
        let energyAtArrival: Double? = pb.optionalActiveRouteEnergyAtArrival != nil
            ? Double(pb.activeRouteEnergyAtArrival) : nil
        let coordinates: Coordinate? = pb.hasActiveRouteCoordinates
            ? mapLatLong(pb.activeRouteCoordinates) : nil
        let lastRouteUpdate: UInt32? = pb.optionalLastRouteUpdate != nil
            ? pb.lastRouteUpdate : nil
        let lastTrafficUpdate: Int64? = pb.hasLastTrafficUpdate
            ? pb.lastTrafficUpdate.seconds : nil
        let timestamp: Int64? = pb.hasTimestamp ? pb.timestamp.seconds : nil

        return DriveState(
            shiftState: shiftState,
            speedMph: speedMph,
            powerKW: powerKW,
            odometerHundredthsMile: odometerHundredthsMile,
            activeRouteDestination: destination,
            activeRouteMinutesToArrival: minutesToArrival,
            activeRouteMilesToArrival: milesToArrival,
            activeRouteTrafficMinutesDelay: trafficDelay,
            activeRouteEnergyAtArrival: energyAtArrival,
            activeRouteCoordinates: coordinates,
            lastRouteUpdateSecondsSinceEpoch: lastRouteUpdate,
            lastTrafficUpdateSecondsSinceEpoch: lastTrafficUpdate,
            timestampSecondsSinceEpoch: timestamp,
        )
    }

    private static func mapLocation(_ pb: CarServer_LocationState) -> LocationState {
        LocationState(
            latitude: pb.optionalLatitude != nil ? Double(pb.latitude) : nil,
            longitude: pb.optionalLongitude != nil ? Double(pb.longitude) : nil,
            headingDegrees: pb.optionalHeading != nil ? Double(pb.heading) : nil,
            gpsAsOfSecondsSinceEpoch: pb.optionalGpsAsOf != nil ? pb.gpsAsOf : nil,
            correctedLatitude: pb.optionalCorrectedLatitude != nil ? Double(pb.correctedLatitude) : nil,
            correctedLongitude: pb.optionalCorrectedLongitude != nil ? Double(pb.correctedLongitude) : nil,
            nativeLatitude: pb.optionalNativeLatitude != nil ? Double(pb.nativeLatitude) : nil,
            nativeLongitude: pb.optionalNativeLongitude != nil ? Double(pb.nativeLongitude) : nil,
            homelinkNearby: pb.optionalHomelinkNearby != nil ? pb.homelinkNearby : nil,
            locationName: pb.optionalLocationName != nil ? pb.locationName : nil,
            geoLatitude: pb.optionalGeoLatitude != nil ? Double(pb.geoLatitude) : nil,
            geoLongitude: pb.optionalGeoLongitude != nil ? Double(pb.geoLongitude) : nil,
            geoHeadingDegrees: pb.optionalGeoHeading != nil ? Double(pb.geoHeading) : nil,
            geoElevationMeters: pb.optionalGeoElevation != nil ? Double(pb.geoElevation) : nil,
            geoAccuracyMeters: pb.optionalGeoAccuracy != nil ? Double(pb.geoAccuracy) : nil,
            estimatedGpsValid: pb.optionalEstimatedGpsValid != nil ? pb.estimatedGpsValid : nil,
        )
    }

    private static func mapClosures(_ pb: CarServer_ClosuresState) -> ClosuresState {
        let sunroofState: ClosuresState.SunroofState? = pb.hasSunRoofState
            ? mapSunroof(pb.sunRoofState) : nil
        let sunroofPercentOpen: Int? = pb.optionalSunRoofPercentOpen != nil
            ? Int(pb.sunRoofPercentOpen) : nil
        let sentryModeActive: Bool? = pb.hasSentryModeState
            ? mapSentry(pb.sentryModeState) : nil

        return ClosuresState(
            frontDriverDoor: pb.optionalDoorOpenDriverFront != nil ? pb.doorOpenDriverFront : nil,
            frontPassengerDoor: pb.optionalDoorOpenPassengerFront != nil ? pb.doorOpenPassengerFront : nil,
            rearDriverDoor: pb.optionalDoorOpenDriverRear != nil ? pb.doorOpenDriverRear : nil,
            rearPassengerDoor: pb.optionalDoorOpenPassengerRear != nil ? pb.doorOpenPassengerRear : nil,
            frontTrunk: pb.optionalDoorOpenTrunkFront != nil ? pb.doorOpenTrunkFront : nil,
            rearTrunk: pb.optionalDoorOpenTrunkRear != nil ? pb.doorOpenTrunkRear : nil,
            locked: pb.optionalLocked != nil ? pb.locked : nil,
            windowDriverFront: pb.optionalWindowOpenDriverFront != nil ? pb.windowOpenDriverFront : nil,
            windowPassengerFront: pb.optionalWindowOpenPassengerFront != nil ? pb.windowOpenPassengerFront : nil,
            windowDriverRear: pb.optionalWindowOpenDriverRear != nil ? pb.windowOpenDriverRear : nil,
            windowPassengerRear: pb.optionalWindowOpenPassengerRear != nil ? pb.windowOpenPassengerRear : nil,
            sunroofState: sunroofState,
            sunroofPercentOpen: sunroofPercentOpen,
            tonneauState: pb.optionalTonneauState != nil
                ? mapTonneau(pb.tonneauState) : nil,
            tonneauPercentOpen: pb.optionalTonneauPercentOpen != nil
                ? Int(pb.tonneauPercentOpen) : nil,
            tonneauInMotion: pb.optionalTonneauInMotion != nil ? pb.tonneauInMotion : nil,
            centerDisplayState: pb.hasCenterDisplayState
                ? mapDisplayState(pb.centerDisplayState) : nil,
            sentryModeActive: sentryModeActive,
            sentryModeAvailable: pb.optionalSentryModeAvailable != nil
                ? pb.sentryModeAvailable : nil,
            remoteStart: pb.optionalRemoteStart != nil ? pb.remoteStart : nil,
            valetMode: pb.optionalValetMode != nil ? pb.valetMode : nil,
            valetPinNeeded: pb.optionalValetPinNeeded != nil ? pb.valetPinNeeded : nil,
            isUserPresent: pb.optionalIsUserPresent != nil ? pb.isUserPresent : nil,
            speedLimit: pb.hasSpeedLimitMode ? mapSpeedLimit(pb.speedLimitMode) : nil,
        )
    }

    private static func mapSpeedLimit(_ pb: CarServer_SpeedLimitMode) -> SpeedLimitMode {
        SpeedLimitMode(
            active: pb.optionalActive != nil ? pb.active : nil,
            pinCodeSet: pb.optionalPinCodeSet != nil ? pb.pinCodeSet : nil,
            maxLimitMph: pb.optionalMaxLimitMph != nil ? Double(pb.maxLimitMph) : nil,
            minLimitMph: pb.optionalMinLimitMph != nil ? Double(pb.minLimitMph) : nil,
            currentLimitMph: pb.optionalCurrentLimitMph != nil ? Double(pb.currentLimitMph) : nil,
        )
    }

    private static func mapTirePressure(_ pb: CarServer_TirePressureState) -> TirePressureState {
        TirePressureState(
            frontLeft: TirePressureState.Tire(
                pressureBar: pb.optionalTpmsPressureFl != nil ? Double(pb.tpmsPressureFl) : nil,
                hasWarning: pb.optionalTpmsHardWarningFl != nil || pb.optionalTpmsSoftWarningFl != nil
                    ? (pb.tpmsHardWarningFl || pb.tpmsSoftWarningFl) : nil,
            ),
            frontRight: TirePressureState.Tire(
                pressureBar: pb.optionalTpmsPressureFr != nil ? Double(pb.tpmsPressureFr) : nil,
                hasWarning: pb.optionalTpmsHardWarningFr != nil || pb.optionalTpmsSoftWarningFr != nil
                    ? (pb.tpmsHardWarningFr || pb.tpmsSoftWarningFr) : nil,
            ),
            rearLeft: TirePressureState.Tire(
                pressureBar: pb.optionalTpmsPressureRl != nil ? Double(pb.tpmsPressureRl) : nil,
                hasWarning: pb.optionalTpmsHardWarningRl != nil || pb.optionalTpmsSoftWarningRl != nil
                    ? (pb.tpmsHardWarningRl || pb.tpmsSoftWarningRl) : nil,
            ),
            rearRight: TirePressureState.Tire(
                pressureBar: pb.optionalTpmsPressureRr != nil ? Double(pb.tpmsPressureRr) : nil,
                hasWarning: pb.optionalTpmsHardWarningRr != nil || pb.optionalTpmsSoftWarningRr != nil
                    ? (pb.tpmsHardWarningRr || pb.tpmsSoftWarningRr) : nil,
            ),
            recommendedColdFrontBar: pb.optionalTpmsRcpFrontValue != nil
                ? Double(pb.tpmsRcpFrontValue) : nil,
            recommendedColdRearBar: pb.optionalTpmsRcpRearValue != nil
                ? Double(pb.tpmsRcpRearValue) : nil,
        )
    }

    private static func mapMedia(_ pb: CarServer_MediaState) -> MediaState {
        MediaState(
            nowPlayingArtist: pb.optionalNowPlayingArtist != nil ? pb.nowPlayingArtist : nil,
            nowPlayingTitle: pb.optionalNowPlayingTitle != nil ? pb.nowPlayingTitle : nil,
            audioVolume: pb.optionalAudioVolume != nil ? Double(pb.audioVolume) : nil,
            audioVolumeIncrement: pb.optionalAudioVolumeIncrement != nil
                ? Double(pb.audioVolumeIncrement) : nil,
            audioVolumeMax: pb.optionalAudioVolumeMax != nil ? Double(pb.audioVolumeMax) : nil,
            remoteControlEnabled: pb.optionalRemoteControlEnabled != nil
                ? pb.remoteControlEnabled : nil,
            nowPlayingSource: pb.optionalNowPlayingSource != nil
                ? mapMediaSource(pb.nowPlayingSource) : nil,
            playbackStatus: pb.optionalMediaPlaybackStatus != nil
                ? mapPlaybackStatus(pb.mediaPlaybackStatus) : nil,
        )
    }

    private static func mapMediaDetail(_ pb: CarServer_MediaDetailState) -> MediaDetailState {
        MediaDetailState(
            nowPlayingDurationSeconds: pb.optionalNowPlayingDuration != nil
                ? Double(pb.nowPlayingDuration) : nil,
            nowPlayingElapsedSeconds: pb.optionalNowPlayingElapsed != nil
                ? Double(pb.nowPlayingElapsed) : nil,
            nowPlayingAlbum: pb.optionalNowPlayingAlbum != nil ? pb.nowPlayingAlbum : nil,
            nowPlayingStation: pb.optionalNowPlayingStation != nil ? pb.nowPlayingStation : nil,
            nowPlayingSourceName: pb.optionalNowPlayingSourceString != nil
                ? pb.nowPlayingSourceString : nil,
            a2dpSourceName: pb.optionalA2DpSourceName != nil ? pb.a2DpSourceName : nil,
        )
    }

    private static func mapMediaSource(
        _ pb: CarServer_MediaSourceType,
    ) -> MediaState.MediaSource {
        switch pb {
        case .none: .none
        case .am: .am
        case .fm: .fm
        case .xm: .xm
        case .slacker: .slacker
        case .localFiles: .localFiles
        case .iPod: .iPod
        case .bluetooth: .bluetooth
        case .auxIn: .auxIn
        case .dab: .dab
        case .rdio: .rdio
        case .spotify: .spotify
        case .usradio: .usRadio
        case .euradio: .euRadio
        case .mediaFile: .mediaFile
        case .tuneIn: .tuneIn
        case .stingray: .stingray
        case .siriusXm: .siriusXm
        case .tidal: .tidal
        case .qqmusic: .qqmusic
        case .qqmusic2: .qqmusic2
        case .ximalaya: .ximalaya
        case .onlineRadio: .onlineRadio
        case .onlineRadio2: .onlineRadio2
        case .netEaseMusic: .netEaseMusic
        case .browser: .browser
        case .theater: .theater
        case .game: .game
        case .tutorial: .tutorial
        case .toybox: .toybox
        case .recentsFavorites: .recentsFavorites
        case .homeApps: .homeApps
        case .search: .search
        case let .UNRECOGNIZED(raw): .unknown(raw)
        }
    }

    private static func mapPlaybackStatus(
        _ pb: CarServer_MediaPlaybackStatus,
    ) -> MediaState.PlaybackStatus? {
        switch pb {
        case .stopped: .stopped
        case .playing: .playing
        case .paused: .paused
        case .UNRECOGNIZED: nil
        }
    }

    private static func mapSoftwareUpdate(_ pb: CarServer_SoftwareUpdateState) -> SoftwareUpdateState {
        SoftwareUpdateState(
            version: pb.optionalVersion != nil ? pb.version : nil,
            status: pb.hasStatus ? mapSoftwareUpdateStatus(pb.status) : nil,
            downloadPercent: pb.optionalDownloadPerc != nil ? Int(pb.downloadPerc) : nil,
            installPercent: pb.optionalInstallPerc != nil ? Int(pb.installPerc) : nil,
            expectedDurationSeconds: pb.optionalExpectedDurationSec != nil
                ? Int(pb.expectedDurationSec) : nil,
            scheduledTimeMs: pb.optionalScheduledTimeMs != nil ? pb.scheduledTimeMs : nil,
            warningTimeRemainingMs: pb.optionalWarningTimeRemainingMs != nil
                ? pb.warningTimeRemainingMs : nil,
        )
    }

    private static func mapSoftwareUpdateStatus(
        _ pb: CarServer_SoftwareUpdateState.SoftwareUpdateStatus,
    ) -> SoftwareUpdateState.Status? {
        guard let type = pb.type else { return nil }
        switch type {
        case .unknown: return .unknown
        case .installing: return .installing
        case .scheduled: return .scheduled
        case .available: return .available
        case .downloadingWifiWait: return .downloadingWifiWait
        case .downloading: return .downloading
        }
    }

    private static func mapParentalControls(_ pb: CarServer_ParentalControlsState) -> ParentalControlsState {
        ParentalControlsState(
            active: pb.optionalParentalControlsActive != nil ? pb.parentalControlsActive : nil,
            pinSet: pb.optionalParentalControlsPinSet != nil ? pb.parentalControlsPinSet : nil,
            settings: pb.hasParentalControlsSettings
                ? mapParentalControlsSettings(pb.parentalControlsSettings) : nil,
        )
    }

    private static func mapParentalControlsSettings(
        _ pb: CarServer_ParentalControlsSettings,
    ) -> ParentalControlsSettings {
        ParentalControlsSettings(
            speedLimitEnabled: pb.optionalSpeedLimitEnabled != nil
                ? pb.speedLimitEnabled : nil,
            maxLimitMph: pb.optionalMaxLimitMph != nil ? Double(pb.maxLimitMph) : nil,
            minLimitMph: pb.optionalMinLimitMph != nil ? Double(pb.minLimitMph) : nil,
            currentLimitMph: pb.optionalCurrentLimitMph != nil ? Double(pb.currentLimitMph) : nil,
            chillAccelerationEnabled: pb.optionalChillAccelerationEnabled != nil
                ? pb.chillAccelerationEnabled : nil,
            requireSafetySettingsEnabled: pb.optionalRequireSafetySettingsEnabled != nil
                ? pb.requireSafetySettingsEnabled : nil,
            curfewEnabled: pb.optionalCurfewEnabled != nil ? pb.curfewEnabled : nil,
            curfewStartTime: pb.optionalCurfewStartTime != nil ? Int(pb.curfewStartTime) : nil,
            curfewEndTime: pb.optionalCurfewEndTime != nil ? Int(pb.curfewEndTime) : nil,
        )
    }

    private static func mapChargeSchedule(
        _ pb: CarServer_ChargeScheduleState,
    ) -> ChargeScheduleState {
        let pendingWindow: ChargeScheduleEntry? = {
            if case let .chargeScheduleWindow(entry) = pb.optionalChargeScheduleWindow {
                return mapChargeScheduleEntry(entry)
            }
            return nil
        }()

        return ChargeScheduleState(
            schedules: pb.chargeSchedules.map(mapChargeScheduleEntry(_:)),
            pendingScheduleWindow: pendingWindow,
            chargeBufferMinutes: pb.optionalChargeBuffer != nil ? Int(pb.chargeBuffer) : nil,
            maxScheduleCount: pb.optionalMaxNumChargeSchedules != nil
                ? pb.maxNumChargeSchedules : nil,
            nextScheduleEnabled: pb.optionalNextSchedule != nil ? pb.nextSchedule : nil,
            showScheduleCompleteState: pb.optionalShowScheduleCompleteState != nil
                ? pb.showScheduleCompleteState : nil,
            timestampSecondsSinceEpoch: pb.hasTimestamp ? pb.timestamp.seconds : nil,
        )
    }

    private static func mapChargeScheduleEntry(
        _ pb: CarServer_ChargeSchedule,
    ) -> ChargeScheduleEntry {
        ChargeScheduleEntry(
            id: pb.id,
            name: pb.name,
            daysOfWeek: pb.daysOfWeek,
            startEnabled: pb.startEnabled,
            startTimeMinutes: pb.startTime,
            endEnabled: pb.endEnabled,
            endTimeMinutes: pb.endTime,
            oneTime: pb.oneTime,
            enabled: pb.enabled,
            latitude: pb.latitude,
            longitude: pb.longitude,
        )
    }

    private static func mapPreconditionSchedule(
        _ pb: CarServer_PreconditioningScheduleState,
    ) -> PreconditionScheduleState {
        let pendingWindow: PreconditionScheduleEntry? = {
            if case let .preconditioningScheduleWindow(entry) = pb.optionalPreconditioningScheduleWindow {
                return mapPreconditionScheduleEntry(entry)
            }
            return nil
        }()

        return PreconditionScheduleState(
            schedules: pb.preconditionSchedules.map(mapPreconditionScheduleEntry(_:)),
            pendingScheduleWindow: pendingWindow,
            maxScheduleCount: pb.optionalMaxNumPreconditionSchedules != nil
                ? pb.maxNumPreconditionSchedules : nil,
            nextScheduleEnabled: pb.optionalNextSchedule != nil ? pb.nextSchedule : nil,
            timestampSecondsSinceEpoch: pb.hasTimestamp ? pb.timestamp.seconds : nil,
        )
    }

    private static func mapPreconditionScheduleEntry(
        _ pb: CarServer_PreconditionSchedule,
    ) -> PreconditionScheduleEntry {
        PreconditionScheduleEntry(
            id: pb.id,
            name: pb.name,
            daysOfWeek: pb.daysOfWeek,
            preconditionTimeMinutes: pb.preconditionTime,
            oneTime: pb.oneTime,
            enabled: pb.enabled,
            latitude: pb.latitude,
            longitude: pb.longitude,
        )
    }

    // MARK: - Enum helpers

    private static func mapChargingStatus(
        _ pb: CarServer_ChargeState.ChargingState,
    ) -> ChargeState.ChargingStatus? {
        guard let type = pb.type else { return nil }
        switch type {
        case .disconnected: return .disconnected
        case .charging: return .charging
        case .complete: return .complete
        case .stopped: return .stopped
        case .starting: return .starting
        case .unknown, .noPower, .calibrating: return .disconnected
        }
    }

    private static func mapShift(_ pb: CarServer_ShiftState) -> DriveState.ShiftState? {
        guard let type = pb.type else { return nil }
        switch type {
        case .p: return .park
        case .r: return .reverse
        case .n: return .neutral
        case .d: return .drive
        case .invalid, .sna: return nil
        }
    }

    private static func mapSunroof(
        _ pb: CarServer_ClosuresState.SunRoofState,
    ) -> ClosuresState.SunroofState? {
        guard let type = pb.type else { return nil }
        switch type {
        case .closed: return .closed
        case .open: return .open
        case .vent: return .vent
        case .moving: return .moving
        case .calibrating: return .calibrating
        case .unknown: return .unknown
        }
    }

    private static func mapTonneau(
        _ pb: VCSEC_ClosureState_E,
    ) -> ClosuresState.TonneauState? {
        switch pb {
        case .closurestateClosed: .closed
        case .closurestateOpen: .open
        case .closurestateAjar: .ajar
        case .closurestateUnknown: .unknown
        case .closurestateFailedUnlatch: .failedUnlatch
        case .closurestateOpening: .opening
        case .closurestateClosing: .closing
        case .UNRECOGNIZED: nil
        }
    }

    private static func mapDisplayState(
        _ pb: CarServer_ClosuresState.DisplayState,
    ) -> ClosuresState.DisplayState? {
        guard let type = pb.type else { return nil }
        switch type {
        case .off: return .off
        case .dim: return .dim
        case .accessory: return .accessory
        case .on: return .on
        case .driving: return .driving
        case .charging: return .charging
        case .lock: return .lock
        case .sentry: return .sentry
        case .dog: return .dog
        case .entertainment: return .entertainment
        }
    }

    private static func mapSentry(
        _ pb: CarServer_ClosuresState.SentryModeState,
    ) -> Bool? {
        guard let type = pb.type else { return nil }
        switch type {
        case .off: return false
        case .idle, .armed, .aware, .panic, .quiet: return true
        }
    }

    private static func mapDefrost(
        _ pb: CarServer_ClimateState.DefrostMode,
    ) -> Bool? {
        guard let type = pb.type else { return nil }
        switch type {
        case .off: return false
        case .normal, .max: return true
        }
    }

    private static func mapSeatHeater(_ rawLevel: Int32) -> ClimateState.SeatHeaterLevel? {
        ClimateState.SeatHeaterLevel(rawValue: Int(rawLevel))
    }

    private static func mapChargeLimitReason(
        _ pb: CarServer_ChargeState.ChargeLimitReason,
    ) -> ChargeState.ChargeLimitReason? {
        switch pb {
        case .unknown: .unknown
        case .none: ChargeState.ChargeLimitReason.none
        case .evse: .evse
        case .battTempLow: .batteryTempLow
        case .highSoc: .highSoc
        case .cabin: .cabin
        case .UNRECOGNIZED: nil
        }
    }

    private static func mapScheduledChargingMode(
        _ pb: CarServer_ChargeState.ScheduledChargingMode,
    ) -> ChargeState.ScheduledChargingMode? {
        switch pb {
        case .off: .off
        case .startAt: .startAt
        case .departBy: .departBy
        case .UNRECOGNIZED: nil
        }
    }

    private static func mapChargePortLatch(
        _ pb: CarServer_ChargePortLatchState,
    ) -> ChargeState.ChargePortLatchState? {
        guard let type = pb.type else { return nil }
        switch type {
        case .sna: return .sna
        case .disengaged: return .disengaged
        case .engaged: return .engaged
        case .blocking: return .blocking
        }
    }

    private static func mapChargePortColor(
        _ pb: CarServer_ChargeState.ChargePortColor_E,
    ) -> ChargeState.ChargePortColor? {
        switch pb {
        case .chargePortColorOff: .off
        case .chargePortColorRed: .red
        case .chargePortColorGreen: .green
        case .chargePortColorBlue: .blue
        case .chargePortColorWhite: .white
        case .chargePortColorFlashingGreen: .flashingGreen
        case .chargePortColorFlashingAmber: .flashingAmber
        case .chargePortColorAmber: .amber
        case .chargePortColorRave: .rave
        case .chargePortColorDebug: .debug
        case .chargePortColorFlashingBlue: .flashingBlue
        case .UNRECOGNIZED: nil
        }
    }

    private static func mapCableType(
        _ pb: CarServer_ChargeState.CableType,
    ) -> ChargeState.CableType? {
        guard let type = pb.type else { return nil }
        switch type {
        case .sna: return .sna
        case .iec: return .iec
        case .sae: return .sae
        case .gbAc: return .gbAc
        case .gbDc: return .gbDc
        }
    }

    private static func mapFastChargerType(
        _ pb: CarServer_ChargeState.ChargerType,
    ) -> ChargeState.FastChargerType? {
        guard let type = pb.type else { return nil }
        switch type {
        case .sna: return .sna
        case .supercharger: return .supercharger
        case .chademo: return .chademo
        case .gb: return .gb
        case .acsingleWireCan: return .acSingleWireCan
        case .combo: return .combo
        case .mcsingleWireCan: return .mcSingleWireCan
        case .other: return .other
        case .tesla: return .tesla
        }
    }

    private static func mapFastChargerBrand(
        _ pb: CarServer_ChargeState.ChargerBrand,
    ) -> ChargeState.FastChargerBrand? {
        guard let type = pb.type else { return nil }
        switch type {
        case .tesla: return .tesla
        case .sna: return .sna
        }
    }

    private static func mapOutletState(
        _ pb: CarServer_ChargeState.OutletState,
    ) -> ChargeState.OutletState? {
        switch pb {
        case .off: .off
        case .cabinAndBed: .cabinAndBed
        case .cabin: .cabin
        case .UNRECOGNIZED: nil
        }
    }

    private static func mapPowerFeedState(
        _ pb: CarServer_ChargeState.PowerFeedState,
    ) -> ChargeState.OutletState? {
        switch pb {
        case .off: .off
        case .cabinAndBed: .cabinAndBed
        case .cabin: .cabin
        case .UNRECOGNIZED: nil
        }
    }

    private static func mapPowershareType(
        _ pb: CarServer_ChargeState.PowershareType,
    ) -> PowershareState.PowershareType? {
        switch pb {
        case .none: PowershareState.PowershareType.none
        case .load: .load
        case .home: .home
        case .UNRECOGNIZED: nil
        }
    }

    private static func mapPowershareStatus(
        _ pb: CarServer_ChargeState.PowershareStatus,
    ) -> PowershareState.PowershareStatus? {
        switch pb {
        case .inactive: .inactive
        case .init_: .initializing
        case .active: .active
        case .stopped: .stopped
        case .handshaking: .handshaking
        case .activeReconnectingSoon: .activeReconnectingSoon
        case .UNRECOGNIZED: nil
        }
    }

    private static func mapPowershareStopReason(
        _ pb: CarServer_ChargeState.PowershareStopReason,
    ) -> PowershareState.PowershareStopReason? {
        switch pb {
        case .none: PowershareState.PowershareStopReason.none
        case .soctooLow: .socTooLow
        case .retry: .retry
        case .fault: .fault
        case .user: .user
        case .reconnecting: .reconnecting
        case .authentication: .authentication
        case .UNRECOGNIZED: nil
        }
    }

    private static func mapHvacAutoRequest(
        _ pb: CarServer_ClimateState.HvacAutoRequest,
    ) -> ClimateState.HvacAutoRequest? {
        switch pb {
        case .on: .on
        case .override: .override
        case .UNRECOGNIZED: nil
        }
    }

    private static func mapClimateKeeperMode(
        _ pb: CarServer_ClimateState.ClimateKeeperMode,
    ) -> ClimateState.ClimateKeeperMode? {
        guard let type = pb.type else { return nil }
        switch type {
        case .unknown: return .unknown
        case .off: return .off
        case .on: return .on
        case .dog: return .dog
        case .party: return .party
        }
    }

    private static func mapCabinOverheatProtection(
        _ pb: CarServer_ClimateState.CabinOverheatProtection_E,
    ) -> ClimateState.CabinOverheatProtectionMode? {
        switch pb {
        case .cabinOverheatProtectionOff: .off
        case .cabinOverheatProtectionOn: .on
        case .cabinOverheatProtectionFanOnly: .fanOnly
        case .UNRECOGNIZED: nil
        }
    }

    private static func mapCopActivationTemp(
        _ pb: CarServer_ClimateState.CopActivationTemp,
    ) -> ClimateState.CopActivationTemperature? {
        switch pb {
        case .unspecified: .unspecified
        case .low: .low
        case .medium: .medium
        case .high: .high
        case .UNRECOGNIZED: nil
        }
    }

    private static func mapCopNotRunningReason(
        _ pb: CarServer_ClimateState.COPNotRunningReason,
    ) -> ClimateState.CopNotRunningReason? {
        switch pb {
        case .noReason: .noReason
        case .userInteraction: .userInteraction
        case .energyConsumptionReached: .energyConsumptionReached
        case .timeout: .timeout
        case .lowSolarLoad: .lowSolarLoad
        case .fault: .fault
        case .cabinBelowThreshold: .cabinBelowThreshold
        case .UNRECOGNIZED: nil
        }
    }

    private static func mapSteeringWheelHeatLevel(
        _ pb: CarServer_StwHeatLevel,
    ) -> ClimateState.SteeringWheelHeatLevel? {
        switch pb {
        case .unknown: .unknown
        case .off: .off
        case .low: .low
        case .high: .high
        case .UNRECOGNIZED: nil
        }
    }
}
