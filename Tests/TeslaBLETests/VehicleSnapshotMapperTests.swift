import SwiftProtobuf
@testable import TeslaBLE
import XCTest

final class VehicleSnapshotMapperTests: XCTestCase {
    func testEmptyVehicleDataProducesAllNils() {
        let data = CarServer_VehicleData()
        let snapshot = VehicleSnapshotMapper.map(data)
        XCTAssertNil(snapshot.charge)
        XCTAssertNil(snapshot.climate)
        XCTAssertNil(snapshot.drive)
        XCTAssertNil(snapshot.location)
        XCTAssertNil(snapshot.closures)
        XCTAssertNil(snapshot.tirePressure)
        XCTAssertNil(snapshot.media)
        XCTAssertNil(snapshot.mediaDetail)
        XCTAssertNil(snapshot.softwareUpdate)
        XCTAssertNil(snapshot.chargeSchedule)
        XCTAssertNil(snapshot.preconditionSchedule)
        XCTAssertNil(snapshot.parentalControls)
    }

    func testChargeStateMapping() {
        var data = CarServer_VehicleData()
        var charge = CarServer_ChargeState()
        charge.batteryLevel = 75
        charge.batteryRange = 250.5
        charge.estBatteryRange = 240.0
        charge.chargerVoltage = 240
        charge.chargerActualCurrent = 32
        charge.chargerPower = 7
        charge.chargeLimitSoc = 90
        charge.minutesToFullCharge = 120
        charge.chargeRateMph = 30
        charge.chargePortDoorOpen = true
        data.chargeState = charge

        let snapshot = VehicleSnapshotMapper.map(data)
        XCTAssertEqual(snapshot.charge?.batteryLevel, 75)
        XCTAssertEqual(snapshot.charge?.batteryRangeMiles ?? 0, Double(Float(250.5)), accuracy: 0.01)
        XCTAssertEqual(snapshot.charge?.estBatteryRangeMiles ?? 0, Double(Float(240.0)), accuracy: 0.01)
        XCTAssertEqual(snapshot.charge?.chargerVoltage, 240)
        XCTAssertEqual(snapshot.charge?.chargerCurrent, 32)
        XCTAssertEqual(snapshot.charge?.chargerPower, 7)
        XCTAssertEqual(snapshot.charge?.chargeLimitPercent, 90)
        XCTAssertEqual(snapshot.charge?.minutesToFullCharge, 120)
        XCTAssertEqual(snapshot.charge?.chargeRateMph, 30.0)
        XCTAssertEqual(snapshot.charge?.chargePortOpen, true)
    }

    func testChargeStateUnsetFieldsAreNil() {
        var data = CarServer_VehicleData()
        // Submessage present so `hasChargeState` is true, but no fields set.
        data.chargeState = CarServer_ChargeState()
        let charge = VehicleSnapshotMapper.map(data).charge
        XCTAssertNotNil(charge)
        XCTAssertNil(charge?.batteryLevel)
        XCTAssertNil(charge?.batteryRangeMiles)
        XCTAssertNil(charge?.chargerVoltage)
        XCTAssertNil(charge?.chargingAmps)
        XCTAssertNil(charge?.chargeLimitPercent)
        XCTAssertNil(charge?.chargePortOpen)
        XCTAssertNil(charge?.chargePortLatch)
        XCTAssertNil(charge?.connectedCableType)
        XCTAssertNil(charge?.fastChargerType)
        XCTAssertNil(charge?.fastChargerBrand)
        XCTAssertNil(charge?.scheduledChargingMode)
        XCTAssertNil(charge?.outletState)
        XCTAssertNil(charge?.powershare)
        XCTAssertNil(charge?.homeLocation)
        XCTAssertNil(charge?.workLocation)
    }

    func testChargeStateDepthMapping() {
        var data = CarServer_VehicleData()
        var charge = CarServer_ChargeState()
        charge.usableBatteryLevel = 73
        charge.idealBatteryRange = 260.0
        charge.chargerPilotCurrent = 40
        charge.chargeCurrentRequest = 32
        charge.chargeCurrentRequestMax = 48
        charge.chargingAmps = 32
        charge.chargerPhases = 3
        charge.minutesToChargeLimit = 80
        charge.chargeEnergyAdded = 12.4
        charge.chargeMilesAddedRated = 30.0
        charge.chargeMilesAddedIdeal = 32.5
        charge.chargeRateMphFloat = 31.5
        charge.tripCharging = true
        charge.superchargerSessionTripPlanner = true
        charge.chargeLimitSocStd = 80
        charge.chargeLimitSocMin = 50
        charge.chargeLimitSocMax = 100
        charge.oneTimeSocLimit = 95
        charge.chargePortColdWeatherMode = false
        charge.chargeCableUnlatched = false
        charge.fastChargerPresent = true
        charge.scheduledChargingPending = true
        charge.scheduledChargingStartTime = 1_700_000_000
        charge.scheduledChargingStartTimeMinutes = 1320
        charge.scheduledChargingStartTimeApp = 1320
        charge.scheduledDepartureTimeMinutes = 480
        charge.offPeakHoursEndTime = 360
        charge.preconditioningEnabled = true
        charge.userChargeEnableRequest = true
        charge.chargeEnableRequest = true
        charge.managedChargingActive = true
        charge.managedChargingUserCanceled = false
        charge.managedChargingStartTime = 1_700_000_500
        charge.outletSocLimit = 30
        charge.powerFeedSocLimit = 25
        charge.outletTimeRemaining = 7200
        charge.powerFeedTimeRemaining = 14400
        charge.outletMaxTimerMinutes = 720

        // Powershare cluster.
        charge.powershareFeatureAllowed = true
        charge.powershareFeatureEnabled = true
        charge.powershareRequest = true
        charge.powershareInstantaneousLoadKw = 4.2
        charge.powershareVehicleEnergyLeftHr = 18
        charge.powershareSocLimit = 20

        // Saved locations.
        var home = CarServer_LatLong()
        home.latitude = 37.4
        home.longitude = -122.1
        charge.homeLocation = home
        var work = CarServer_LatLong()
        work.latitude = 37.5
        work.longitude = -122.0
        charge.workLocation = work

        // ChargeLimitReason enum.
        charge.chargeLimitReason = .battTempLow

        // ScheduledChargingMode enum.
        charge.scheduledChargingMode = .departBy

        // ChargePortLatch oneof.
        var latch = CarServer_ChargePortLatchState()
        latch.type = .engaged(CarServer_Void())
        charge.chargePortLatch = latch

        // ChargePortColor enum.
        charge.chargePortColor = .chargePortColorGreen

        // CableType oneof.
        var cable = CarServer_ChargeState.CableType()
        cable.type = .iec(CarServer_Void())
        charge.connChargeCable = cable

        // FastChargerType / Brand oneof.
        var ftype = CarServer_ChargeState.ChargerType()
        ftype.type = .supercharger(CarServer_Void())
        charge.fastChargerType = ftype
        var brand = CarServer_ChargeState.ChargerBrand()
        brand.type = .tesla(CarServer_Void())
        charge.fastChargerBrand = brand

        // Outlet / power-feed enums.
        charge.outletState = .cabin
        charge.powerFeedState = .cabinAndBed

        // Powershare enums.
        charge.powershareType = .home
        charge.powershareStatus = .active
        charge.powershareStopReason = .user

        data.chargeState = charge

        let cs = VehicleSnapshotMapper.map(data).charge
        XCTAssertEqual(cs?.usableBatteryLevel, 73)
        XCTAssertEqual(cs?.idealBatteryRangeMiles ?? 0, Double(Float(260.0)), accuracy: 0.01)
        XCTAssertEqual(cs?.chargerPilotCurrent, 40)
        XCTAssertEqual(cs?.chargeCurrentRequest, 32)
        XCTAssertEqual(cs?.chargeCurrentRequestMax, 48)
        XCTAssertEqual(cs?.chargingAmps, 32)
        XCTAssertEqual(cs?.chargerPhases, 3)
        XCTAssertEqual(cs?.minutesToChargeLimit, 80)
        XCTAssertEqual(cs?.chargeEnergyAddedKWh ?? 0, Double(Float(12.4)), accuracy: 0.01)
        XCTAssertEqual(cs?.chargeMilesAddedRated ?? 0, Double(Float(30.0)), accuracy: 0.01)
        XCTAssertEqual(cs?.chargeMilesAddedIdeal ?? 0, Double(Float(32.5)), accuracy: 0.01)
        // chargeRateMphFloat takes precedence over the integer field.
        XCTAssertEqual(cs?.chargeRateMph ?? 0, Double(Float(31.5)), accuracy: 0.01)
        XCTAssertEqual(cs?.tripCharging, true)
        XCTAssertEqual(cs?.superchargerSessionTripPlanner, true)
        XCTAssertEqual(cs?.chargeLimitStandardPercent, 80)
        XCTAssertEqual(cs?.chargeLimitMinPercent, 50)
        XCTAssertEqual(cs?.chargeLimitMaxPercent, 100)
        XCTAssertEqual(cs?.oneTimeChargeLimitPercent, 95)
        XCTAssertEqual(cs?.chargeLimitReason, .batteryTempLow)
        XCTAssertEqual(cs?.scheduledChargingMode, .departBy)
        XCTAssertEqual(cs?.scheduledChargingPending, true)
        XCTAssertEqual(cs?.scheduledChargingStartTimeSecondsSinceEpoch, 1_700_000_000)
        XCTAssertEqual(cs?.scheduledChargingStartTimeMinutes, 1320)
        XCTAssertEqual(cs?.scheduledChargingStartTimeAppMinutes, 1320)
        XCTAssertEqual(cs?.scheduledDepartureTimeMinutes, 480)
        XCTAssertEqual(cs?.offPeakHoursEndTimeMinutes, 360)
        XCTAssertEqual(cs?.preconditioningEnabled, true)
        XCTAssertEqual(cs?.userChargeEnableRequest, true)
        XCTAssertEqual(cs?.chargeEnableRequest, true)
        XCTAssertEqual(cs?.managedChargingActive, true)
        XCTAssertEqual(cs?.managedChargingUserCanceled, false)
        XCTAssertEqual(cs?.managedChargingStartTimeSecondsSinceEpoch, 1_700_000_500)
        XCTAssertEqual(cs?.outletState, .cabin)
        XCTAssertEqual(cs?.powerFeedState, .cabinAndBed)
        XCTAssertEqual(cs?.outletSocLimitPercent, 30)
        XCTAssertEqual(cs?.powerFeedSocLimitPercent, 25)
        XCTAssertEqual(cs?.outletTimeRemainingSeconds, 7200)
        XCTAssertEqual(cs?.powerFeedTimeRemainingSeconds, 14400)
        XCTAssertEqual(cs?.outletMaxTimerMinutes, 720)
        XCTAssertEqual(cs?.chargePortLatch, .engaged)
        XCTAssertEqual(cs?.chargePortColor, .green)
        XCTAssertEqual(cs?.chargePortColdWeatherMode, false)
        XCTAssertEqual(cs?.chargeCableUnlatched, false)
        XCTAssertEqual(cs?.connectedCableType, .iec)
        XCTAssertEqual(cs?.fastChargerType, .supercharger)
        XCTAssertEqual(cs?.fastChargerBrand, .tesla)
        XCTAssertEqual(cs?.fastChargerPresent, true)

        let ps = cs?.powershare
        XCTAssertNotNil(ps)
        XCTAssertEqual(ps?.featureAllowed, true)
        XCTAssertEqual(ps?.featureEnabled, true)
        XCTAssertEqual(ps?.requestActive, true)
        XCTAssertEqual(ps?.type, .home)
        XCTAssertEqual(ps?.status, .active)
        XCTAssertEqual(ps?.stopReason, .user)
        XCTAssertEqual(ps?.instantaneousLoadKW ?? 0, Double(Float(4.2)), accuracy: 0.001)
        XCTAssertEqual(ps?.vehicleEnergyLeftHours, 18)
        XCTAssertEqual(ps?.socLimitPercent, 20)

        XCTAssertEqual(cs?.homeLocation?.latitude ?? 0, Double(Float(37.4)), accuracy: 0.01)
        XCTAssertEqual(cs?.homeLocation?.longitude ?? 0, Double(Float(-122.1)), accuracy: 0.01)
        XCTAssertEqual(cs?.workLocation?.latitude ?? 0, Double(Float(37.5)), accuracy: 0.01)
        XCTAssertEqual(cs?.workLocation?.longitude ?? 0, Double(Float(-122.0)), accuracy: 0.01)
    }

    func testDriveStateShiftMapping() {
        var data = CarServer_VehicleData()
        var drive = CarServer_DriveState()
        var shift = CarServer_ShiftState()
        shift.type = .d(CarServer_Void())
        drive.shiftState = shift
        drive.speedFloat = 42.0
        data.driveState = drive

        let snapshot = VehicleSnapshotMapper.map(data)
        XCTAssertEqual(snapshot.drive?.shiftState, .drive)
        XCTAssertEqual(snapshot.drive?.speedMph ?? 0, 42.0, accuracy: 0.001)
    }

    func testMapDriveOnlyReturnsDriveState() {
        var data = CarServer_VehicleData()
        var drive = CarServer_DriveState()
        var shift = CarServer_ShiftState()
        shift.type = .p(CarServer_Void())
        drive.shiftState = shift
        data.driveState = drive

        let result = VehicleSnapshotMapper.mapDrive(data)
        XCTAssertEqual(result.shiftState, .park)
    }

    func testMapDriveMissingStateReturnsEmpty() {
        let result = VehicleSnapshotMapper.mapDrive(CarServer_VehicleData())
        XCTAssertNil(result.shiftState)
        XCTAssertNil(result.speedMph)
    }

    func testDriveStateDepthMapping() {
        var data = CarServer_VehicleData()
        var drive = CarServer_DriveState()
        drive.activeRouteDestination = "Tesla HQ"
        drive.activeRouteMinutesToArrival = 12.5
        drive.activeRouteMilesToArrival = 7.3
        drive.activeRouteTrafficMinutesDelay = 2.0
        drive.activeRouteEnergyAtArrival = 47.0
        var coords = CarServer_LatLong()
        coords.latitude = 37.4275
        coords.longitude = -122.1697
        drive.activeRouteCoordinates = coords
        drive.lastRouteUpdate = 1_700_000_100
        var lastTraffic = SwiftProtobuf.Google_Protobuf_Timestamp()
        lastTraffic.seconds = 1_700_000_200
        drive.lastTrafficUpdate = lastTraffic
        var ts = SwiftProtobuf.Google_Protobuf_Timestamp()
        ts.seconds = 1_700_000_300
        drive.timestamp = ts
        data.driveState = drive

        let d = VehicleSnapshotMapper.map(data).drive
        XCTAssertEqual(d?.activeRouteDestination, "Tesla HQ")
        XCTAssertEqual(d?.activeRouteMinutesToArrival ?? 0, 12.5, accuracy: 0.001)
        XCTAssertEqual(d?.activeRouteMilesToArrival ?? 0, 7.3, accuracy: 0.001)
        XCTAssertEqual(d?.activeRouteTrafficMinutesDelay ?? 0, 2.0, accuracy: 0.001)
        XCTAssertEqual(d?.activeRouteEnergyAtArrival ?? 0, 47.0, accuracy: 0.001)
        XCTAssertEqual(d?.activeRouteCoordinates?.latitude ?? 0, 37.4275, accuracy: 0.001)
        XCTAssertEqual(d?.activeRouteCoordinates?.longitude ?? 0, -122.1697, accuracy: 0.001)
        XCTAssertEqual(d?.lastRouteUpdateSecondsSinceEpoch, 1_700_000_100)
        XCTAssertEqual(d?.lastTrafficUpdateSecondsSinceEpoch, 1_700_000_200)
        XCTAssertEqual(d?.timestampSecondsSinceEpoch, 1_700_000_300)
    }

    func testDriveStateUnsetFieldsAreNil() {
        var data = CarServer_VehicleData()
        data.driveState = CarServer_DriveState()
        let d = VehicleSnapshotMapper.map(data).drive
        XCTAssertNotNil(d)
        XCTAssertNil(d?.activeRouteDestination)
        XCTAssertNil(d?.activeRouteMinutesToArrival)
        XCTAssertNil(d?.activeRouteMilesToArrival)
        XCTAssertNil(d?.activeRouteTrafficMinutesDelay)
        XCTAssertNil(d?.activeRouteEnergyAtArrival)
        XCTAssertNil(d?.activeRouteCoordinates)
        XCTAssertNil(d?.lastRouteUpdateSecondsSinceEpoch)
        XCTAssertNil(d?.lastTrafficUpdateSecondsSinceEpoch)
        XCTAssertNil(d?.timestampSecondsSinceEpoch)
    }

    // MARK: - ChargingStatus enum

    func testChargingStatusAllVariants() {
        let cases: [(CarServer_ChargeState.ChargingState.OneOf_Type, ChargeState.ChargingStatus?)] = [
            (.disconnected(CarServer_Void()), .disconnected),
            (.charging(CarServer_Void()), .charging),
            (.complete(CarServer_Void()), .complete),
            (.stopped(CarServer_Void()), .stopped),
            (.starting(CarServer_Void()), .starting),
            (.unknown(CarServer_Void()), .disconnected),
            (.noPower(CarServer_Void()), .disconnected),
            (.calibrating(CarServer_Void()), .disconnected),
        ]
        for (type, expected) in cases {
            var data = CarServer_VehicleData()
            var charge = CarServer_ChargeState()
            var state = CarServer_ChargeState.ChargingState()
            state.type = type
            charge.chargingState = state
            data.chargeState = charge
            let snapshot = VehicleSnapshotMapper.map(data)
            XCTAssertEqual(snapshot.charge?.chargingStatus, expected, "status=\(type)")
        }

        // type == nil → nil
        var data = CarServer_VehicleData()
        var charge = CarServer_ChargeState()
        charge.chargingState = CarServer_ChargeState.ChargingState()
        data.chargeState = charge
        XCTAssertNil(VehicleSnapshotMapper.map(data).charge?.chargingStatus)
    }

    // MARK: - Shift enum

    func testShiftAllVariants() {
        let cases: [(CarServer_ShiftState.OneOf_Type, DriveState.ShiftState?)] = [
            (.p(CarServer_Void()), .park),
            (.r(CarServer_Void()), .reverse),
            (.n(CarServer_Void()), .neutral),
            (.d(CarServer_Void()), .drive),
            (.invalid(CarServer_Void()), nil),
            (.sna(CarServer_Void()), nil),
        ]
        for (type, expected) in cases {
            var data = CarServer_VehicleData()
            var drive = CarServer_DriveState()
            var shift = CarServer_ShiftState()
            shift.type = type
            drive.shiftState = shift
            data.driveState = drive
            XCTAssertEqual(VehicleSnapshotMapper.map(data).drive?.shiftState, expected, "type=\(type)")
        }

        // type == nil → nil
        var data = CarServer_VehicleData()
        var drive = CarServer_DriveState()
        drive.shiftState = CarServer_ShiftState()
        data.driveState = drive
        XCTAssertNil(VehicleSnapshotMapper.map(data).drive?.shiftState)
    }

    // MARK: - Climate

    func testClimateStateMappingFull() {
        var data = CarServer_VehicleData()
        var climate = CarServer_ClimateState()
        climate.insideTempCelsius = 21.5
        climate.outsideTempCelsius = 10.0
        climate.driverTempSetting = 22.0
        climate.passengerTempSetting = 23.0
        climate.fanStatus = 4
        climate.isClimateOn = true
        climate.seatHeaterLeft = 2
        climate.seatHeaterRight = 1
        climate.seatHeaterRearLeft = 0
        climate.seatHeaterRearCenter = 3
        climate.seatHeaterRearRight = 2
        climate.steeringWheelHeater = true
        climate.batteryHeater = false
        climate.bioweaponModeOn = true
        var defrost = CarServer_ClimateState.DefrostMode()
        defrost.type = .normal(CarServer_Void())
        climate.defrostMode = defrost
        data.climateState = climate

        let c = VehicleSnapshotMapper.map(data).climate
        XCTAssertEqual(c?.insideTempCelsius ?? 0, 21.5, accuracy: 0.01)
        XCTAssertEqual(c?.outsideTempCelsius ?? 0, 10.0, accuracy: 0.01)
        XCTAssertEqual(c?.driverTempSettingCelsius ?? 0, 22.0, accuracy: 0.01)
        XCTAssertEqual(c?.passengerTempSettingCelsius ?? 0, 23.0, accuracy: 0.01)
        XCTAssertEqual(c?.fanStatus, 4)
        XCTAssertEqual(c?.isClimateOn, true)
        XCTAssertEqual(c?.seatHeaterFrontLeft, .medium)
        XCTAssertEqual(c?.seatHeaterFrontRight, .low)
        XCTAssertEqual(c?.seatHeaterRearLeft, .off)
        XCTAssertEqual(c?.seatHeaterRearCenter, .high)
        XCTAssertEqual(c?.seatHeaterRearRight, .medium)
        XCTAssertEqual(c?.steeringWheelHeater, true)
        XCTAssertEqual(c?.isBatteryHeaterOn, false)
        XCTAssertEqual(c?.defrostOn, true)
        XCTAssertEqual(c?.bioweaponMode, true)
    }

    func testClimateDefrostModeAllVariants() {
        let cases: [(CarServer_ClimateState.DefrostMode.OneOf_Type, Bool?)] = [
            (.off(CarServer_Void()), false),
            (.normal(CarServer_Void()), true),
            (.max(CarServer_Void()), true),
        ]
        for (type, expected) in cases {
            var data = CarServer_VehicleData()
            var climate = CarServer_ClimateState()
            var defrost = CarServer_ClimateState.DefrostMode()
            defrost.type = type
            climate.defrostMode = defrost
            data.climateState = climate
            XCTAssertEqual(VehicleSnapshotMapper.map(data).climate?.defrostOn, expected, "type=\(type)")
        }

        // type == nil → nil
        var data = CarServer_VehicleData()
        var climate = CarServer_ClimateState()
        climate.defrostMode = CarServer_ClimateState.DefrostMode()
        data.climateState = climate
        XCTAssertNil(VehicleSnapshotMapper.map(data).climate?.defrostOn)
    }

    func testClimateStateUnsetFieldsAreNil() {
        var data = CarServer_VehicleData()
        data.climateState = CarServer_ClimateState()

        let c = VehicleSnapshotMapper.map(data).climate
        XCTAssertNotNil(c)
        XCTAssertNil(c?.insideTempCelsius)
        XCTAssertNil(c?.outsideTempCelsius)
        XCTAssertNil(c?.driverTempSettingCelsius)
        XCTAssertNil(c?.passengerTempSettingCelsius)
        XCTAssertNil(c?.minAvailTempCelsius)
        XCTAssertNil(c?.maxAvailTempCelsius)
        XCTAssertNil(c?.fanStatus)
        XCTAssertNil(c?.isClimateOn)
        XCTAssertNil(c?.isAutoConditioningOn)
        XCTAssertNil(c?.isPreconditioning)
        XCTAssertNil(c?.hvacAutoRequest)
        XCTAssertNil(c?.climateKeeperMode)
        XCTAssertNil(c?.isFrontDefrosterOn)
        XCTAssertNil(c?.isRearDefrosterOn)
        XCTAssertNil(c?.defrostOn)
        XCTAssertNil(c?.remoteHeaterControlEnabled)
        XCTAssertNil(c?.bioweaponMode)
        XCTAssertNil(c?.seatHeaterFrontLeft)
        XCTAssertNil(c?.seatHeaterRearLeftBack)
        XCTAssertNil(c?.seatHeaterThirdRowLeft)
        XCTAssertNil(c?.autoSeatClimateLeft)
        XCTAssertNil(c?.seatFanFrontLeft)
        XCTAssertNil(c?.steeringWheelHeater)
        XCTAssertNil(c?.steeringWheelHeatLevel)
        XCTAssertNil(c?.wiperBladeHeater)
        XCTAssertNil(c?.sideMirrorHeaters)
        XCTAssertNil(c?.isBatteryHeaterOn)
        XCTAssertNil(c?.isBatteryHeaterNoPower)
        XCTAssertNil(c?.allowCabinOverheatProtection)
        XCTAssertNil(c?.supportsFanOnlyCabinOverheatProtection)
        XCTAssertNil(c?.cabinOverheatProtection)
        XCTAssertNil(c?.cabinOverheatProtectionActivelyCooling)
        XCTAssertNil(c?.copActivationTemperature)
        XCTAssertNil(c?.copNotRunningReason)
    }

    func testClimateStateDepthMapping() {
        var data = CarServer_VehicleData()
        var climate = CarServer_ClimateState()
        climate.minAvailTempCelsius = 15.0
        climate.maxAvailTempCelsius = 28.0
        climate.isAutoConditioningOn = true
        climate.isPreconditioning = false
        climate.hvacAutoRequest = .override
        var keeper = CarServer_ClimateState.ClimateKeeperMode()
        keeper.type = .dog(CarServer_Void())
        climate.climateKeeperMode = keeper
        climate.isFrontDefrosterOn = true
        climate.isRearDefrosterOn = false
        climate.remoteHeaterControlEnabled = true
        climate.seatHeaterRearLeftBack = 1
        climate.seatHeaterRearRightBack = 2
        climate.seatHeaterThirdRowLeft = 3
        climate.seatHeaterThirdRowRight = 0
        climate.autoSeatClimateLeft = true
        climate.autoSeatClimateRight = false
        climate.seatFanFrontLeft = 2
        climate.seatFanFrontRight = 3
        climate.autoSteeringWheelHeat = true
        climate.steeringWheelHeatLevel = .high
        climate.wiperBladeHeater = false
        climate.sideMirrorHeaters = true
        climate.batteryHeaterNoPower = true
        climate.allowCabinOverheatProtection = true
        climate.supportsFanOnlyCabinOverheatProtection = false
        climate.cabinOverheatProtection = .cabinOverheatProtectionFanOnly
        climate.cabinOverheatProtectionActivelyCooling = true
        climate.copActivationTemperature = .high
        climate.copNotRunningReason = .energyConsumptionReached
        data.climateState = climate

        let c = VehicleSnapshotMapper.map(data).climate
        XCTAssertEqual(c?.minAvailTempCelsius ?? 0, 15.0, accuracy: 0.01)
        XCTAssertEqual(c?.maxAvailTempCelsius ?? 0, 28.0, accuracy: 0.01)
        XCTAssertEqual(c?.isAutoConditioningOn, true)
        XCTAssertEqual(c?.isPreconditioning, false)
        XCTAssertEqual(c?.hvacAutoRequest, .override)
        XCTAssertEqual(c?.climateKeeperMode, .dog)
        XCTAssertEqual(c?.isFrontDefrosterOn, true)
        XCTAssertEqual(c?.isRearDefrosterOn, false)
        XCTAssertEqual(c?.remoteHeaterControlEnabled, true)
        XCTAssertEqual(c?.seatHeaterRearLeftBack, .low)
        XCTAssertEqual(c?.seatHeaterRearRightBack, .medium)
        XCTAssertEqual(c?.seatHeaterThirdRowLeft, .high)
        XCTAssertEqual(c?.seatHeaterThirdRowRight, .off)
        XCTAssertEqual(c?.autoSeatClimateLeft, true)
        XCTAssertEqual(c?.autoSeatClimateRight, false)
        XCTAssertEqual(c?.seatFanFrontLeft, 2)
        XCTAssertEqual(c?.seatFanFrontRight, 3)
        XCTAssertEqual(c?.autoSteeringWheelHeat, true)
        XCTAssertEqual(c?.steeringWheelHeatLevel, .high)
        XCTAssertEqual(c?.wiperBladeHeater, false)
        XCTAssertEqual(c?.sideMirrorHeaters, true)
        XCTAssertEqual(c?.isBatteryHeaterNoPower, true)
        XCTAssertEqual(c?.allowCabinOverheatProtection, true)
        XCTAssertEqual(c?.supportsFanOnlyCabinOverheatProtection, false)
        XCTAssertEqual(c?.cabinOverheatProtection, .fanOnly)
        XCTAssertEqual(c?.cabinOverheatProtectionActivelyCooling, true)
        XCTAssertEqual(c?.copActivationTemperature, .high)
        XCTAssertEqual(c?.copNotRunningReason, .energyConsumptionReached)
    }

    func testClimateSeatHeaterOutOfRangeReturnsNil() {
        var data = CarServer_VehicleData()
        var climate = CarServer_ClimateState()
        climate.seatHeaterLeft = 99 // not a valid SeatHeaterLevel raw value
        data.climateState = climate
        XCTAssertNil(VehicleSnapshotMapper.map(data).climate?.seatHeaterFrontLeft)
    }

    // MARK: - Location

    func testLocationStateMappingPopulated() {
        var data = CarServer_VehicleData()
        var loc = CarServer_LocationState()
        loc.latitude = 37.4275
        loc.longitude = -122.1697
        loc.heading = 270
        loc.gpsAsOf = 1_700_000_000
        loc.correctedLatitude = 37.4276
        loc.correctedLongitude = -122.1698
        loc.nativeLatitude = 37.4274
        loc.nativeLongitude = -122.1696
        loc.homelinkNearby = true
        loc.locationName = "Home"
        loc.geoLatitude = 37.4275
        loc.geoLongitude = -122.1697
        loc.geoHeading = 271.5
        loc.geoElevation = 30.0
        loc.geoAccuracy = 5.0
        loc.estimatedGpsValid = true
        data.locationState = loc

        let snapshot = VehicleSnapshotMapper.map(data)
        let location = snapshot.location
        XCTAssertNotNil(location)
        XCTAssertEqual(location?.latitude ?? 0, Double(Float(37.4275)), accuracy: 0.0001)
        XCTAssertEqual(location?.longitude ?? 0, Double(Float(-122.1697)), accuracy: 0.0001)
        XCTAssertEqual(location?.headingDegrees, 270)
        XCTAssertEqual(location?.gpsAsOfSecondsSinceEpoch, 1_700_000_000)
        XCTAssertEqual(location?.correctedLatitude ?? 0, Double(Float(37.4276)), accuracy: 0.0001)
        XCTAssertEqual(location?.correctedLongitude ?? 0, Double(Float(-122.1698)), accuracy: 0.0001)
        XCTAssertEqual(location?.nativeLatitude ?? 0, Double(Float(37.4274)), accuracy: 0.0001)
        XCTAssertEqual(location?.nativeLongitude ?? 0, Double(Float(-122.1696)), accuracy: 0.0001)
        XCTAssertEqual(location?.homelinkNearby, true)
        XCTAssertEqual(location?.locationName, "Home")
        XCTAssertEqual(location?.geoLatitude ?? 0, Double(Float(37.4275)), accuracy: 0.0001)
        XCTAssertEqual(location?.geoLongitude ?? 0, Double(Float(-122.1697)), accuracy: 0.0001)
        XCTAssertEqual(location?.geoHeadingDegrees ?? 0, Double(Float(271.5)), accuracy: 0.01)
        XCTAssertEqual(location?.geoElevationMeters ?? 0, 30.0, accuracy: 0.001)
        XCTAssertEqual(location?.geoAccuracyMeters ?? 0, 5.0, accuracy: 0.001)
        XCTAssertEqual(location?.estimatedGpsValid, true)
    }

    func testLocationStateMissingFieldsAreNil() {
        var data = CarServer_VehicleData()
        // Set only latitude — other oneofs should map to nil.
        var loc = CarServer_LocationState()
        loc.latitude = 1.5
        data.locationState = loc

        let snapshot = VehicleSnapshotMapper.map(data)
        let location = snapshot.location
        XCTAssertNotNil(location)
        XCTAssertEqual(location?.latitude ?? 0, Double(Float(1.5)), accuracy: 0.0001)
        XCTAssertNil(location?.longitude)
        XCTAssertNil(location?.headingDegrees)
        XCTAssertNil(location?.gpsAsOfSecondsSinceEpoch)
        XCTAssertNil(location?.homelinkNearby)
    }

    // MARK: - Closures

    func testClosuresStateFullMapping() {
        var data = CarServer_VehicleData()
        var closures = CarServer_ClosuresState()
        closures.doorOpenDriverFront = true
        closures.doorOpenPassengerFront = false
        closures.doorOpenDriverRear = true
        closures.doorOpenPassengerRear = false
        closures.doorOpenTrunkFront = true
        closures.doorOpenTrunkRear = false
        closures.locked = true
        closures.windowOpenDriverFront = false
        closures.windowOpenPassengerFront = true
        closures.windowOpenDriverRear = false
        closures.windowOpenPassengerRear = true
        closures.sunRoofPercentOpen = 50
        closures.valetMode = false
        closures.isUserPresent = true

        var sunroof = CarServer_ClosuresState.SunRoofState()
        sunroof.type = .open(CarServer_Void())
        closures.sunRoofState = sunroof

        var sentry = CarServer_ClosuresState.SentryModeState()
        sentry.type = .armed(CarServer_Void())
        closures.sentryModeState = sentry

        data.closuresState = closures

        let c = VehicleSnapshotMapper.map(data).closures
        XCTAssertEqual(c?.frontDriverDoor, true)
        XCTAssertEqual(c?.frontPassengerDoor, false)
        XCTAssertEqual(c?.rearDriverDoor, true)
        XCTAssertEqual(c?.rearPassengerDoor, false)
        XCTAssertEqual(c?.frontTrunk, true)
        XCTAssertEqual(c?.rearTrunk, false)
        XCTAssertEqual(c?.locked, true)
        XCTAssertEqual(c?.windowDriverFront, false)
        XCTAssertEqual(c?.windowPassengerFront, true)
        XCTAssertEqual(c?.windowDriverRear, false)
        XCTAssertEqual(c?.windowPassengerRear, true)
        XCTAssertEqual(c?.sunroofState, .open)
        XCTAssertEqual(c?.sunroofPercentOpen, 50)
        XCTAssertEqual(c?.sentryModeActive, true)
        XCTAssertEqual(c?.valetMode, false)
        XCTAssertEqual(c?.isUserPresent, true)
    }

    func testClosuresStateDepthMapping() {
        var data = CarServer_VehicleData()
        var closures = CarServer_ClosuresState()
        closures.tonneauState = .closurestateOpening
        closures.tonneauPercentOpen = 42
        closures.tonneauInMotion = true
        var display = CarServer_ClosuresState.DisplayState()
        display.type = .driving(CarServer_Void())
        closures.centerDisplayState = display
        closures.sentryModeAvailable = true
        closures.remoteStart = true
        closures.valetPinNeeded = false

        var speedLimit = CarServer_SpeedLimitMode()
        speedLimit.active = true
        speedLimit.pinCodeSet = true
        speedLimit.maxLimitMph = 90.0
        speedLimit.minLimitMph = 50.0
        speedLimit.currentLimitMph = 65.0
        closures.speedLimitMode = speedLimit

        data.closuresState = closures

        let c = VehicleSnapshotMapper.map(data).closures
        XCTAssertEqual(c?.tonneauState, .opening)
        XCTAssertEqual(c?.tonneauPercentOpen, 42)
        XCTAssertEqual(c?.tonneauInMotion, true)
        XCTAssertEqual(c?.centerDisplayState, .driving)
        XCTAssertEqual(c?.sentryModeAvailable, true)
        XCTAssertEqual(c?.remoteStart, true)
        XCTAssertEqual(c?.valetPinNeeded, false)
        XCTAssertEqual(c?.speedLimit?.active, true)
        XCTAssertEqual(c?.speedLimit?.pinCodeSet, true)
        XCTAssertEqual(c?.speedLimit?.maxLimitMph ?? 0, 90.0, accuracy: 0.01)
        XCTAssertEqual(c?.speedLimit?.minLimitMph ?? 0, 50.0, accuracy: 0.01)
        XCTAssertEqual(c?.speedLimit?.currentLimitMph ?? 0, 65.0, accuracy: 0.01)
    }

    func testClosuresStateUnsetExtrasAreNil() {
        var data = CarServer_VehicleData()
        data.closuresState = CarServer_ClosuresState()

        let c = VehicleSnapshotMapper.map(data).closures
        XCTAssertNotNil(c)
        XCTAssertNil(c?.tonneauState)
        XCTAssertNil(c?.tonneauPercentOpen)
        XCTAssertNil(c?.tonneauInMotion)
        XCTAssertNil(c?.centerDisplayState)
        XCTAssertNil(c?.sentryModeAvailable)
        XCTAssertNil(c?.remoteStart)
        XCTAssertNil(c?.valetPinNeeded)
        XCTAssertNil(c?.speedLimit)
    }

    func testSunroofStateAllVariants() {
        let cases: [(CarServer_ClosuresState.SunRoofState.OneOf_Type, ClosuresState.SunroofState?)] = [
            (.closed(CarServer_Void()), .closed),
            (.open(CarServer_Void()), .open),
            (.vent(CarServer_Void()), .vent),
            (.moving(CarServer_Void()), .moving),
            (.calibrating(CarServer_Void()), .calibrating),
            (.unknown(CarServer_Void()), .unknown),
        ]
        for (type, expected) in cases {
            var data = CarServer_VehicleData()
            var closures = CarServer_ClosuresState()
            var sunroof = CarServer_ClosuresState.SunRoofState()
            sunroof.type = type
            closures.sunRoofState = sunroof
            data.closuresState = closures
            XCTAssertEqual(VehicleSnapshotMapper.map(data).closures?.sunroofState, expected, "type=\(type)")
        }

        // type == nil → nil
        var data = CarServer_VehicleData()
        var closures = CarServer_ClosuresState()
        closures.sunRoofState = CarServer_ClosuresState.SunRoofState()
        data.closuresState = closures
        XCTAssertNil(VehicleSnapshotMapper.map(data).closures?.sunroofState)
    }

    func testSentryModeStateAllVariants() {
        let cases: [(CarServer_ClosuresState.SentryModeState.OneOf_Type, Bool?)] = [
            (.off(CarServer_Void()), false),
            (.idle(CarServer_Void()), true),
            (.armed(CarServer_Void()), true),
            (.aware(CarServer_Void()), true),
            (.panic(CarServer_Void()), true),
            (.quiet(CarServer_Void()), true),
        ]
        for (type, expected) in cases {
            var data = CarServer_VehicleData()
            var closures = CarServer_ClosuresState()
            var sentry = CarServer_ClosuresState.SentryModeState()
            sentry.type = type
            closures.sentryModeState = sentry
            data.closuresState = closures
            XCTAssertEqual(VehicleSnapshotMapper.map(data).closures?.sentryModeActive, expected, "type=\(type)")
        }

        // type == nil → nil
        var data = CarServer_VehicleData()
        var closures = CarServer_ClosuresState()
        closures.sentryModeState = CarServer_ClosuresState.SentryModeState()
        data.closuresState = closures
        XCTAssertNil(VehicleSnapshotMapper.map(data).closures?.sentryModeActive)
    }

    // MARK: - Tire pressure

    func testTirePressureStateFullMapping() {
        var data = CarServer_VehicleData()
        var tires = CarServer_TirePressureState()
        tires.tpmsPressureFl = 2.5
        tires.tpmsPressureFr = 2.6
        tires.tpmsPressureRl = 2.7
        tires.tpmsPressureRr = 2.8
        tires.tpmsSoftWarningFl = true
        tires.tpmsHardWarningFl = false
        tires.tpmsSoftWarningFr = false
        tires.tpmsHardWarningFr = false
        tires.tpmsSoftWarningRl = false
        tires.tpmsHardWarningRl = true
        tires.tpmsSoftWarningRr = false
        tires.tpmsHardWarningRr = false
        tires.tpmsRcpFrontValue = 2.4
        tires.tpmsRcpRearValue = 2.6
        data.tirePressureState = tires

        let t = VehicleSnapshotMapper.map(data).tirePressure
        XCTAssertEqual(t?.frontLeft?.pressureBar ?? 0, 2.5, accuracy: 0.01)
        XCTAssertEqual(t?.frontLeft?.hasWarning, true) // soft warn set
        XCTAssertEqual(t?.frontRight?.pressureBar ?? 0, 2.6, accuracy: 0.01)
        XCTAssertEqual(t?.frontRight?.hasWarning, false)
        XCTAssertEqual(t?.rearLeft?.hasWarning, true) // hard warn set
        XCTAssertEqual(t?.rearRight?.pressureBar ?? 0, 2.8, accuracy: 0.01)
        XCTAssertEqual(t?.recommendedColdFrontBar ?? 0, 2.4, accuracy: 0.01)
        XCTAssertEqual(t?.recommendedColdRearBar ?? 0, 2.6, accuracy: 0.01)
    }

    // MARK: - Media / MediaDetail

    func testMediaStateMapping() {
        var data = CarServer_VehicleData()
        var media = CarServer_MediaState()
        media.nowPlayingArtist = "Daft Punk"
        media.nowPlayingTitle = "Around the World"
        media.audioVolume = 6.5
        media.audioVolumeIncrement = 0.5
        media.audioVolumeMax = 11.0
        media.remoteControlEnabled = true
        media.nowPlayingSource = .spotify
        media.mediaPlaybackStatus = .playing
        data.mediaState = media

        let m = VehicleSnapshotMapper.map(data).media
        XCTAssertEqual(m?.nowPlayingArtist, "Daft Punk")
        XCTAssertEqual(m?.nowPlayingTitle, "Around the World")
        XCTAssertEqual(m?.audioVolume ?? 0, 6.5, accuracy: 0.01)
        XCTAssertEqual(m?.audioVolumeIncrement ?? 0, 0.5, accuracy: 0.01)
        XCTAssertEqual(m?.audioVolumeMax ?? 0, 11.0, accuracy: 0.01)
        XCTAssertEqual(m?.remoteControlEnabled, true)
        XCTAssertEqual(m?.nowPlayingSource, .spotify)
        XCTAssertEqual(m?.playbackStatus, .playing)
    }

    func testMediaStateOmittedExtrasAreNil() {
        var data = CarServer_VehicleData()
        let media = CarServer_MediaState()
        data.mediaState = media

        let m = VehicleSnapshotMapper.map(data).media
        XCTAssertNotNil(m)
        XCTAssertNil(m?.audioVolumeIncrement)
        XCTAssertNil(m?.nowPlayingSource)
        XCTAssertNil(m?.playbackStatus)
    }

    func testMediaSourceAllVariants() {
        let cases: [(CarServer_MediaSourceType, MediaState.MediaSource)] = [
            (.none, .none),
            (.am, .am),
            (.fm, .fm),
            (.xm, .xm),
            (.slacker, .slacker),
            (.localFiles, .localFiles),
            (.iPod, .iPod),
            (.bluetooth, .bluetooth),
            (.auxIn, .auxIn),
            (.dab, .dab),
            (.rdio, .rdio),
            (.spotify, .spotify),
            (.usradio, .usRadio),
            (.euradio, .euRadio),
            (.mediaFile, .mediaFile),
            (.tuneIn, .tuneIn),
            (.stingray, .stingray),
            (.siriusXm, .siriusXm),
            (.tidal, .tidal),
            (.qqmusic, .qqmusic),
            (.qqmusic2, .qqmusic2),
            (.ximalaya, .ximalaya),
            (.onlineRadio, .onlineRadio),
            (.onlineRadio2, .onlineRadio2),
            (.netEaseMusic, .netEaseMusic),
            (.browser, .browser),
            (.theater, .theater),
            (.game, .game),
            (.tutorial, .tutorial),
            (.toybox, .toybox),
            (.recentsFavorites, .recentsFavorites),
            (.homeApps, .homeApps),
            (.search, .search),
        ]
        for (raw, expected) in cases {
            var data = CarServer_VehicleData()
            var media = CarServer_MediaState()
            media.nowPlayingSource = raw
            data.mediaState = media
            XCTAssertEqual(
                VehicleSnapshotMapper.map(data).media?.nowPlayingSource,
                expected,
                "raw \(raw) should map to \(expected)",
            )
        }
    }

    func testMediaDetailStateMapping() {
        var data = CarServer_VehicleData()
        var detail = CarServer_MediaDetailState()
        detail.nowPlayingDuration = 240
        detail.nowPlayingElapsed = 60
        detail.nowPlayingAlbum = "Discovery"
        detail.nowPlayingStation = "KEXP"
        detail.nowPlayingSourceString = "Spotify"
        detail.a2DpSourceName = "iPhone"
        data.mediaDetailState = detail

        let d = VehicleSnapshotMapper.map(data).mediaDetail
        XCTAssertEqual(d?.nowPlayingDurationSeconds, 240)
        XCTAssertEqual(d?.nowPlayingElapsedSeconds, 60)
        XCTAssertEqual(d?.nowPlayingAlbum, "Discovery")
        XCTAssertEqual(d?.nowPlayingStation, "KEXP")
        XCTAssertEqual(d?.nowPlayingSourceName, "Spotify")
        XCTAssertEqual(d?.a2dpSourceName, "iPhone")
    }

    // MARK: - Software update

    func testSoftwareUpdateStateMapping() {
        var data = CarServer_VehicleData()
        var update = CarServer_SoftwareUpdateState()
        update.version = "2026.4.1"
        update.downloadPerc = 75
        update.installPerc = 0
        update.expectedDurationSec = 1800
        data.softwareUpdateState = update

        let u = VehicleSnapshotMapper.map(data).softwareUpdate
        XCTAssertEqual(u?.version, "2026.4.1")
        XCTAssertEqual(u?.downloadPercent, 75)
        XCTAssertEqual(u?.installPercent, 0)
        XCTAssertEqual(u?.expectedDurationSeconds, 1800)
    }

    func testSoftwareUpdateStateDepth() {
        var data = CarServer_VehicleData()
        var update = CarServer_SoftwareUpdateState()
        var status = CarServer_SoftwareUpdateState.SoftwareUpdateStatus()
        status.type = .scheduled(CarServer_Void())
        update.status = status
        update.scheduledTimeMs = 1_700_000_000_000
        update.warningTimeRemainingMs = 60000
        data.softwareUpdateState = update

        let u = VehicleSnapshotMapper.map(data).softwareUpdate
        XCTAssertEqual(u?.status, .scheduled)
        XCTAssertEqual(u?.scheduledTimeMs, 1_700_000_000_000)
        XCTAssertEqual(u?.warningTimeRemainingMs, 60000)
    }

    func testSoftwareUpdateStatusAllVariants() {
        let cases: [(CarServer_SoftwareUpdateState.SoftwareUpdateStatus.OneOf_Type, SoftwareUpdateState.Status)] = [
            (.unknown(CarServer_Void()), .unknown),
            (.installing(CarServer_Void()), .installing),
            (.scheduled(CarServer_Void()), .scheduled),
            (.available(CarServer_Void()), .available),
            (.downloadingWifiWait(CarServer_Void()), .downloadingWifiWait),
            (.downloading(CarServer_Void()), .downloading),
        ]
        for (type, expected) in cases {
            var data = CarServer_VehicleData()
            var update = CarServer_SoftwareUpdateState()
            var status = CarServer_SoftwareUpdateState.SoftwareUpdateStatus()
            status.type = type
            update.status = status
            data.softwareUpdateState = update
            XCTAssertEqual(VehicleSnapshotMapper.map(data).softwareUpdate?.status, expected, "type=\(type)")
        }
    }

    // MARK: - Parental controls

    func testParentalControlsMapping() {
        var data = CarServer_VehicleData()
        var pc = CarServer_ParentalControlsState()
        pc.parentalControlsActive = true
        pc.parentalControlsPinSet = false
        data.parentalControlsState = pc

        let result = VehicleSnapshotMapper.map(data).parentalControls
        XCTAssertEqual(result?.active, true)
        XCTAssertEqual(result?.pinSet, false)
        XCTAssertNil(result?.settings)
    }

    func testParentalControlsSettingsMapping() {
        var data = CarServer_VehicleData()
        var pc = CarServer_ParentalControlsState()
        var settings = CarServer_ParentalControlsSettings()
        settings.speedLimitEnabled = true
        settings.maxLimitMph = 90.0
        settings.minLimitMph = 50.0
        settings.currentLimitMph = 70.0
        settings.chillAccelerationEnabled = true
        settings.requireSafetySettingsEnabled = false
        settings.curfewEnabled = true
        settings.curfewStartTime = 22 * 3600
        settings.curfewEndTime = 6 * 3600
        pc.parentalControlsSettings = settings
        data.parentalControlsState = pc

        let s = VehicleSnapshotMapper.map(data).parentalControls?.settings
        XCTAssertEqual(s?.speedLimitEnabled, true)
        XCTAssertEqual(s?.maxLimitMph ?? 0, 90.0, accuracy: 0.01)
        XCTAssertEqual(s?.minLimitMph ?? 0, 50.0, accuracy: 0.01)
        XCTAssertEqual(s?.currentLimitMph ?? 0, 70.0, accuracy: 0.01)
        XCTAssertEqual(s?.chillAccelerationEnabled, true)
        XCTAssertEqual(s?.requireSafetySettingsEnabled, false)
        XCTAssertEqual(s?.curfewEnabled, true)
        XCTAssertEqual(s?.curfewStartTime, 22 * 3600)
        XCTAssertEqual(s?.curfewEndTime, 6 * 3600)
    }

    // MARK: - Schedule state sentinels

    func testScheduleStateSentinelsArePresentWhenSubmessageSet() {
        var data = CarServer_VehicleData()
        data.chargeScheduleState = CarServer_ChargeScheduleState()
        data.preconditioningScheduleState = CarServer_PreconditioningScheduleState()
        let snapshot = VehicleSnapshotMapper.map(data)
        XCTAssertNotNil(snapshot.chargeSchedule)
        XCTAssertNotNil(snapshot.preconditionSchedule)
        XCTAssertEqual(snapshot.chargeSchedule?.schedules, [])
        XCTAssertNil(snapshot.chargeSchedule?.pendingScheduleWindow)
        XCTAssertNil(snapshot.chargeSchedule?.chargeBufferMinutes)
        XCTAssertNil(snapshot.chargeSchedule?.maxScheduleCount)
        XCTAssertNil(snapshot.chargeSchedule?.nextScheduleEnabled)
        XCTAssertNil(snapshot.chargeSchedule?.showScheduleCompleteState)
        XCTAssertNil(snapshot.chargeSchedule?.timestampSecondsSinceEpoch)
        XCTAssertEqual(snapshot.preconditionSchedule?.schedules, [])
        XCTAssertNil(snapshot.preconditionSchedule?.pendingScheduleWindow)
        XCTAssertNil(snapshot.preconditionSchedule?.maxScheduleCount)
        XCTAssertNil(snapshot.preconditionSchedule?.nextScheduleEnabled)
        XCTAssertNil(snapshot.preconditionSchedule?.timestampSecondsSinceEpoch)
    }

    func testChargeScheduleStateFullMapping() {
        var entry = CarServer_ChargeSchedule()
        entry.id = 1_730_000_000
        entry.name = "Weekday home"
        entry.daysOfWeek = 0b0011_1110 // Mon–Fri
        entry.startEnabled = true
        entry.startTime = 22 * 60 // 22:00
        entry.endEnabled = true
        entry.endTime = 6 * 60 // 06:00
        entry.oneTime = false
        entry.enabled = true
        entry.latitude = 37.4419
        entry.longitude = -122.1430

        var window = CarServer_ChargeSchedule()
        window.id = 1_730_000_001
        window.name = "Pending"
        window.daysOfWeek = 0b0100_0000
        window.startEnabled = true
        window.startTime = 60
        window.enabled = false

        var state = CarServer_ChargeScheduleState()
        state.chargeSchedules = [entry]
        state.chargeScheduleWindow = window
        state.chargeBuffer = 30
        state.maxNumChargeSchedules = 50
        state.nextSchedule = true
        state.showScheduleCompleteState = false
        var ts = SwiftProtobuf.Google_Protobuf_Timestamp()
        ts.seconds = 1_730_000_500
        state.timestamp = ts

        var data = CarServer_VehicleData()
        data.chargeScheduleState = state

        let result = VehicleSnapshotMapper.map(data).chargeSchedule
        XCTAssertEqual(result?.schedules.count, 1)
        let mapped = result?.schedules.first
        XCTAssertEqual(mapped?.id, 1_730_000_000)
        XCTAssertEqual(mapped?.name, "Weekday home")
        XCTAssertEqual(mapped?.daysOfWeek, 0b0011_1110)
        XCTAssertEqual(mapped?.startEnabled, true)
        XCTAssertEqual(mapped?.startTimeMinutes, 22 * 60)
        XCTAssertEqual(mapped?.endEnabled, true)
        XCTAssertEqual(mapped?.endTimeMinutes, 6 * 60)
        XCTAssertEqual(mapped?.oneTime, false)
        XCTAssertEqual(mapped?.enabled, true)
        XCTAssertEqual(mapped?.latitude, 37.4419)
        XCTAssertEqual(mapped?.longitude, -122.1430)

        let pending = result?.pendingScheduleWindow
        XCTAssertEqual(pending?.id, 1_730_000_001)
        XCTAssertEqual(pending?.name, "Pending")
        XCTAssertEqual(pending?.startTimeMinutes, 60)

        XCTAssertEqual(result?.chargeBufferMinutes, 30)
        XCTAssertEqual(result?.maxScheduleCount, 50)
        XCTAssertEqual(result?.nextScheduleEnabled, true)
        XCTAssertEqual(result?.showScheduleCompleteState, false)
        XCTAssertEqual(result?.timestampSecondsSinceEpoch, 1_730_000_500)
    }

    func testPreconditionScheduleStateFullMapping() {
        var entry = CarServer_PreconditionSchedule()
        entry.id = 1_730_000_100
        entry.name = "Morning warmup"
        entry.daysOfWeek = 0b0011_1110
        entry.preconditionTime = 7 * 60 + 30
        entry.oneTime = false
        entry.enabled = true
        entry.latitude = 47.6062
        entry.longitude = -122.3321

        var window = CarServer_PreconditionSchedule()
        window.id = 1_730_000_101
        window.name = "Pending"
        window.preconditionTime = 8 * 60
        window.enabled = true

        var state = CarServer_PreconditioningScheduleState()
        state.preconditionSchedules = [entry]
        state.preconditioningScheduleWindow = window
        state.maxNumPreconditionSchedules = 25
        state.nextSchedule = false
        var ts = SwiftProtobuf.Google_Protobuf_Timestamp()
        ts.seconds = 1_730_000_900
        state.timestamp = ts

        var data = CarServer_VehicleData()
        data.preconditioningScheduleState = state

        let result = VehicleSnapshotMapper.map(data).preconditionSchedule
        XCTAssertEqual(result?.schedules.count, 1)
        let mapped = result?.schedules.first
        XCTAssertEqual(mapped?.id, 1_730_000_100)
        XCTAssertEqual(mapped?.name, "Morning warmup")
        XCTAssertEqual(mapped?.daysOfWeek, 0b0011_1110)
        XCTAssertEqual(mapped?.preconditionTimeMinutes, 7 * 60 + 30)
        XCTAssertEqual(mapped?.oneTime, false)
        XCTAssertEqual(mapped?.enabled, true)
        XCTAssertEqual(mapped?.latitude, 47.6062)
        XCTAssertEqual(mapped?.longitude, -122.3321)

        let pending = result?.pendingScheduleWindow
        XCTAssertEqual(pending?.id, 1_730_000_101)
        XCTAssertEqual(pending?.preconditionTimeMinutes, 8 * 60)
        XCTAssertEqual(pending?.enabled, true)

        XCTAssertEqual(result?.maxScheduleCount, 25)
        XCTAssertEqual(result?.nextScheduleEnabled, false)
        XCTAssertEqual(result?.timestampSecondsSinceEpoch, 1_730_000_900)
    }
}
