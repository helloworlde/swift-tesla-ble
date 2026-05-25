# AGENTS.md

This file gives AI coding assistants (Claude Code, Cursor, etc.) context for
working in this repository. `CLAUDE.md` is a symlink to this file.

## Repository

`swift-tesla-ble` is a Swift port of Tesla's official Go SDK
[`teslamotors/vehicle-command`](https://github.com/teslamotors/vehicle-command),
scoped to the BLE transport. The Go repo is vendored as a git submodule at
`Vendor/tesla-vehicle-command` and pinned at commit
`49977a18fd68567501d59e16a6c9e4a8b9348544`. Crypto, session and dispatcher
modules are line-for-line mirrors of `internal/authentication/*` and
`internal/dispatcher/*`; command encoders are ports of `pkg/vehicle/*.go`;
protobuf types are regenerated from `pkg/protocol/protobuf/*.proto`.

The README claim "byte-identical with Tesla's Go reference implementation" is
load-bearing — fixture vectors under `Tests/TeslaBLETests/Fixtures/` are
dumped from the Go reference and pin Swift output to the same bytes. Do not
"improve" wire-compat decisions (notably the SHA-1 KDF in
`Sources/TeslaBLE/Crypto/SessionKey.swift`) without breaking those fixtures.

## Layout

```
Sources/TeslaBLE/
  Client/      TeslaVehicleClient (actor, public entrypoint)
  Commands/    Command enum, CommandEncoder, ResponseDecoder, StateQuery,
               VehicleQuery, Subcommands/{Actions,Charge,Climate,Infotainment,
               Media,Security}Encoder.swift
  Crypto/      P256ECDH, SessionKey, MetadataHash, CounterWindow,
               MessageAuthenticator
  Session/     VehicleSession (per-domain actor), SessionNegotiator,
               SessionMetadata, OutboundSigner, InboundVerifier
  Dispatcher/  Dispatcher (actor), RequestTable, MessageTransport
  Transport/   BLETransport (CoreBluetooth), MessageFramer
  Keys/        TeslaKeyStore protocol, KeychainTeslaKeyStore, KeyPairFactory
  Model/       Swift-native vehicle state types + VehicleSnapshotMapper
               (the only file allowed to import CarServer_*)
  Support/     TeslaBLEError, TeslaBLELogger, VINHelper
  Generated/   Nine *.pb.swift — do not hand-edit; regenerate via
               scripts/generate-protos.sh
```

Public entrypoint: `TeslaVehicleClient` actor (one per VIN). Surface is
`connect / disconnect / send / fetch / fetchDrive / query / stateStream`.

## Build / Test

```bash
swift build
swift test                       # all tests
swift test --filter SessionTests # one suite
scripts/generate-protos.sh       # regenerate Generated/*.pb.swift after
                                 # bumping the submodule
```

The example app lives at `Examples/TeslaBLEDemo/` (SwiftUI iOS, links the
local SPM package only).

## Conventions

- Public API never exposes `Generated/*_pb.swift` types. The translation
  boundary is `Model/VehicleSnapshotMapper.swift` (CarServer/VehicleData) and,
  for VCSEC, the wrapper types under `Model/`.
- New control commands: add a case to the appropriate `Command` enum nest in
  `Commands/Command.swift`, an arm in `Commands/CommandEncoder.swift`, and an
  encoder function in `Commands/Subcommands/<Area>Encoder.swift`. Cite the
  upstream Go file in a header comment like the existing files
  (`// Mirrors pkg/vehicle/<area>.go in tesla-vehicle-command`).
- New read fields: extend the matching `Model/<X>State.swift` struct and add
  the line in `VehicleSnapshotMapper.swift`. Use the `optional*` proto getters
  to preserve "field absent" as Swift `nil`.
- Crypto changes: must keep fixture tests green. If a fixture genuinely needs
  to change, regenerate it from the Go reference, don't hand-edit JSON.
- Strict concurrency is on — actors for stateful types, `Sendable` for value
  types, `nonisolated(unsafe)` only inside `BLETransport`.

## Implementation tracker

Active multi-phase work tracks progress in
`~/.claude/plans/tesla-ble-progress.md` (not committed, local to this
machine). When picking up where the previous session left off, read that
file first.

## Upstream parity

This package is being aligned with the upstream Go SDK. Gap analysis and
phased rollout are in `~/.claude/plans/tesla-ble-nested-hedgehog.md`.
