# Validation

The library and sample target iOS / iPadOS 15 and later. Runtime support is only verified where a result is recorded below.

## Local validation

Verified on 6 September 2026 with Xcode 27 beta (`27A5228h`):

| Check | Result |
| --- | --- |
| Package graph resolution and library compilation | Passed |
| Sample and shared test targets, build-for-testing | Passed |
| iPhone 17 / iOS 27.0 beta | 18 tests passed; 0 failures or skips |
| iPhone 16 / iOS 18.5 | 18 tests passed; 0 failures or skips |
| Public API and integration source review | No remaining findings |
| Manifest, project/plist, storyboard/scheme, and diff checks | Passed |

Each runtime executed 7 public API tests, 6 hosted layout/storyboard tests, and 5 UI tests. UI coverage includes large text/RTL, completed and cancelled edge swipes, height/status-bar changes, rotation/scrolling, sheet/full-screen dismissal, and title/back actions. The sheet test explicitly selects the presented title and Close control because the presenting screen remains in the accessibility tree.

The [main screen](images/ios27-main.png), [presented sheet](images/ios27-sheet.png), and [landscape layout](images/ios27-landscape.png) are native captures inspected in dark appearance. After switching to full-screen capture and waiting for landscape geometry, the focused rotation test passed again on iOS 27. Interaction claims are backed by the executed UI tests, not only these static captures.

The package/project metadata remained unchanged during builds and tests with automatic resolution disabled. Xcode 27's XCTest libraries declare an iOS 17 minimum, producing linker warnings for the test targets' iOS 15 setting; both tested runtimes are newer than that floor. App and package deployment targets remain iOS 15. No signing configuration was changed.

## Automated contracts

Public package tests cover external subclassing, wrapper containment and initial titles, stack identity, live theme updates, height bounds, and optional title actions. Hosted UIKit tests cover configured header heights, storyboard loading, safe-area/content alignment, accessibility text growth, leading-edge layout in RTL, and root/stack gesture admission. UI tests cover push/back/title actions, sheet and full-screen dismissal, completed/cancelled edge swipes, height/status-bar changes, rotation, scrolling, and large text in RTL.

Run the shared `CustomNavigationBar` scheme for all public API, app integration, and UI tests. The hosted unit target includes the same public API test source declared by `Package.swift`. Xcode exposes a dependency package scheme but generates no test configurations for it, so CI uses the explicit shared app scheme. Open `Package.swift` separately to work on the standalone package test target. UIKit tests require an iOS Simulator; plain macOS `swift test` cannot execute them. Resolve packages explicitly first, then build/test with `-disableAutomaticPackageResolution`.

CI is configured for these hosted images. A configured workflow is not a recorded CI pass.

| Runner | Xcode | Simulator |
| --- | --- | --- |
| macOS 15 | 16.4 | iPhone 16 / iOS 18.5 |
| macOS 26 | 26.6 | iPhone 17 / iOS 26.5 |
| macOS 26 | 26.6 | iPad Pro 11-inch (M5) / iOS 26.5 |

Toolchain and destination availability were checked against GitHub's [macOS 15](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md) and [macOS 26](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-Readme.md) image manifests on 6 September 2026.

## Remaining coverage

- iOS 15 and any other release without an available test runtime.
- Physical devices, VoiceOver exploration, Reduce Motion settings, and iPad multiwindow resizing until explicitly recorded.
- Future SDKs and final releases corresponding to tested betas.
