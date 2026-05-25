import Foundation

/// Basic now-playing media information and audio volume.
public struct MediaState: Sendable, Equatable {
    /// Artist name of the currently playing track. Nil if the vehicle did not report this field.
    public var nowPlayingArtist: String?
    /// Title of the currently playing track. Nil if the vehicle did not report this field.
    public var nowPlayingTitle: String?
    /// Current audio volume on the vehicle's raw scale. Nil if the vehicle did not report this field.
    public var audioVolume: Double?
    /// Smallest increment by which the volume can be adjusted, on the same
    /// raw scale as `audioVolume`. Nil if the vehicle did not report this
    /// field.
    public var audioVolumeIncrement: Double?
    /// Maximum audio volume on the vehicle's raw scale. Nil if the vehicle did not report this field.
    public var audioVolumeMax: Double?
    /// Whether remote media control is currently permitted. Nil if the vehicle did not report this field.
    public var remoteControlEnabled: Bool?
    /// Categorical source the vehicle is currently playing from (Bluetooth,
    /// Spotify, TuneIn, FM, …). Nil if the vehicle did not report this
    /// field.
    public var nowPlayingSource: MediaSource?
    /// Current playback transport state (playing/paused/stopped). Nil if
    /// the vehicle did not report this field.
    public var playbackStatus: PlaybackStatus?

    /// Categorical source identifier reported in
    /// `CarServer_MediaState.nowPlayingSource`. Mirrors
    /// `CarServer_MediaSourceType` 1:1; an unknown wire value is preserved
    /// in `.unknown(Int)` rather than being dropped.
    public enum MediaSource: Sendable, Equatable {
        case none
        case am
        case fm
        case xm
        case slacker
        case localFiles
        case iPod
        case bluetooth
        case auxIn
        case dab
        case rdio
        case spotify
        case usRadio
        case euRadio
        case mediaFile
        case tuneIn
        case stingray
        case siriusXm
        case tidal
        case qqmusic
        case qqmusic2
        case ximalaya
        case onlineRadio
        case onlineRadio2
        case netEaseMusic
        case browser
        case theater
        case game
        case tutorial
        case toybox
        case recentsFavorites
        case homeApps
        case search
        case unknown(Int)
    }

    /// Playback transport state. Mirrors `CarServer_MediaPlaybackStatus`.
    public enum PlaybackStatus: Sendable, Equatable {
        case stopped
        case playing
        case paused
    }

    public init(
        nowPlayingArtist: String? = nil,
        nowPlayingTitle: String? = nil,
        audioVolume: Double? = nil,
        audioVolumeIncrement: Double? = nil,
        audioVolumeMax: Double? = nil,
        remoteControlEnabled: Bool? = nil,
        nowPlayingSource: MediaSource? = nil,
        playbackStatus: PlaybackStatus? = nil,
    ) {
        self.nowPlayingArtist = nowPlayingArtist
        self.nowPlayingTitle = nowPlayingTitle
        self.audioVolume = audioVolume
        self.audioVolumeIncrement = audioVolumeIncrement
        self.audioVolumeMax = audioVolumeMax
        self.remoteControlEnabled = remoteControlEnabled
        self.nowPlayingSource = nowPlayingSource
        self.playbackStatus = playbackStatus
    }
}
