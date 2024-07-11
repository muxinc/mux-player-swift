# Mux Player Swift

A collection of helpful utilities for using AVKit and AVFoundation to stream video from Mux.

We'd love to hear your feedback, shoot us a note at avplayer@mux.com with any feature requests, API feedback, or to tell us about what you'd like to build.

#### Mux Video DRM Beta

This SDK supports Mux Video's DRM feature, which is currently in closed beta. If you are interested in using our DRM features, please sign up on our [beta page](https://www.mux.com/beta/drm)

## Installation

### Installing in Xcode using Swift Package Manager

1. In your Xcode project click "File" > "Add Package"
2. In the top-right corner of the modal window paste in the SDK repository URL:

```
https://github.com/muxinc/mux-player-swift
```
3. Click `Next`
4. Select package version. We recommend setting the "Rules" to install the latest version and choosing the option "Up to Next Major". [Here's an overview of the different SPM Dependency Rules and their semantics](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app#Decide-on-package-requirements).


### Swift Package Manager - Package.swift

In your `Package.swift` file, add the following to as an item to the `dependencies` parameter.

```
.package(
      url: "https://github.com/muxinc/mux-player-swift,
      .upToNextMajor(from: "1.0.0")
    ),
```

## Usage

Use the Mux Player Swift SDK to setup to download and play HLS with a playback ID. The SDK will also enable Mux Data monitoring to help you measure the performance and quality of your application's video experiences.x

```swift
import AVFoundation
import MuxPlayerSwift

/// After you're done testing, you can check out this video out to learn more about video and players (as well as some philosophy)
let playbackID = "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"

func preparePlayerViewController(
  playbackID: String
) -> AVPlayerViewController {

  let playerViewController = AVPlayerViewController(
    playbackID: playbackID
  )

  return playerViewController
}

let examplePlayerViewController = preparePlayerViewController(playbackID: playbackID)
```

Your application can customize how Mux Video delivers video to the player using playback URL modifiers. A playback URL modifier is appended as a query parameter to a public playback URL. The Mux AVPlayer SDK exposes a Swift API to avoid manually working with strings or URLs.

```swift
import AVFoundation
import MuxPlayerSwift

/// After you're done testing, you can check out this video out to learn more about video and players (as well as some philosophy)
let playbackID = "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"

/// Prepares a ready-for-display AVPlayer instance that will not exceed 720 x 1280 resolution
/// when streaming video
func preparePlayerViewController(
  playbackID: String
) -> AVPlayerViewController {
  let playbackOptions = PlaybackOptions(
    maximumResolution: ResolutionTier.upTo720p
  )

  let playerViewController = AVPlayerViewController(
    playbackID: playbackID,
    playbackOptions: playbackOptions
  )

  return playerViewController
}

let examplePlayerViewController = preparePlayerViewController(playbackID: playbackID)
```

When using the AVPlayerViewController convenience initializers provided by `MuxPlayerSwift` there are no required steps to enable Mux Data monitoring for video streamed from a Mux playback URL. Metrics and monitoring data will be routed to the same environment as the asset being played

See the below section for how to route monitoring data to a specific environment key and how to change or customize metadata provided to Mux Data.

## Use AVPlayer and AVKit with Mux Data

By default Mux Data metrics will be populated in the same environment as your playback ID. [Learn more about Mux Data metric definitions here](https://docs.mux.com/guides/data/understand-metric-definitions).

Read on for additional (and optional) setup steps to modify or extend the information Mux Data tracks.

Set custom metadata using MonitoringOptions.

```swift

import AVKit
import MuxPlayerSwift

// A separate import is needed
// to use MUXSDKCustomerData
// and related Mux Data types
import MuxCore

func preparePlayerViewController(
  playbackID: String
) -> AVPlayerViewController {

  let customEnvironmentKey = "ENV_KEY"

  let playerData = MUXSDKCustomerPlayerData()
  playerData.environmentKey = customEnvironmentKey

  let videoData = = MUXSDKCustomerVideoData()
  videoData.videoTitle = "Video Behind the Scenes"
  videoData.videoSeries = "Video101"

  let customerData = MUXSDKCustomerData()
  customerData.playerData = playerData
  customerData.videoData = videoData

  let monitoringOptions = MonitoringOptions(
    customerData: customerData
  )

  let playerViewController = AVPlayerViewController(
      playbackID: playbackID,
      monitoringOptions: monitoringOptions
  )

  return playerViewController

}
```

## Stream Mux assets with a signed playback policy

Mux Video supports playback access control. [See here for more](https://docs.mux.com/guides/video/secure-video-playback). `MuxPlayerSwift` supports signed playback URLs.

Generate a JSON Web Token (JWT) and sign it in a trusted environment. Any playback modifiers must be passed through as part of the JWT, they must be included among the JWT claims.

Once your application receives the JWT, use it to initialize `PlaybackOptions`. Then, initialize `AVPlayerViewController` as before.

```swift

import AVKit
import MuxPlayerSwift

func preparePlayerViewController(
  playbackID: String,
  playbackToken: String
) -> AVPlayerViewController {

  let playbackOptions = PlaybackOptions(playbackToken: playbackToken)

  let playerViewController = AVPlayerViewController(
      playbackID: playbackID,
      playbackOptions: playbackOptions
  )

  return playerViewController

}
```

If your JWT includes a playback restriction, Mux will not be able perform domain validation when the playback URL is loaded by AVPlayer because no referrer information is supplied.

To allow AVPlayer playback of referrer restricted assets set the allow_no_referrer boolean parameter to true when creating a playback restriction. Conversely, a playback restriction with allow_no_referrer to false will disallow AVPlayer playback. [See here for more](https://docs.mux.com/guides/video/secure-video-playback#using-referer-http-header-for-validation).

## Release

Steps to release a new version of the SDK
1. Merge any changes directly into `main`.
2. Update `SemanticVersion.swift` with new version values.
3. Tag the commit for the release on `main` with the name `vX.Y.Z` where X, Y, and Z are the major, minor, and patch versions of the release respectively.
4. Create a new GitHub release on `main` for the tag with the tag name as the title and include releases notes in the description.
5. Update the SDK static documentation by running: `./scripts/generate-static-documentation.sh`.
