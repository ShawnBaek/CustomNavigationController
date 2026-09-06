# Validation

The library and sample target iOS / iPadOS 15 and later. Runtime support is only verified where a result is recorded below.

## Local validation

Verified on 6 September 2026 with Xcode 27 beta (`27A5228h`):

| Check | Result |
| --- | --- |
| Package graph resolution and library compilation | Passed |
| Sample and shared test targets, build-for-testing | Passed |
| iPhone 17 / iOS 27.0 beta | 28 cases verified; final runs had 0 failures or skips |
| iPhone 16 / iOS 18.5 | 28 cases verified; final runs had 0 failures or skips |
| iPad Pro 11-inch (M5) / iPadOS 27.0 beta | 28 cases verified; final runs had 0 failures or skips |
| Public API and integration source review | No remaining findings |
| Manifest, project/plist, storyboard/scheme, and diff checks | Passed |

Verification on each runtime combines a passing 27-test full suite with a new default-centering regression and three focused push/back UI reruns. The current suite contains 14 public API tests, 6 hosted layout/storyboard tests, and 8 UI tests. The centering regression checks Back and Done at compact heights of 44, 66, 88, 120, and 200 points, with large titles both enabled and disabled. The UI reruns exercise button-driven push/Back, repeated pushes after completed/cancelled edge swipes, and restoring a collapsed large title after returning from Detail.

Other coverage includes native Done and menu actions, item replacement and enablement, directional/vertical button movement, Back policy, large-title modes, scroll collapse, reversible insets, and replacement of a released scroll view. Existing coverage retains large text/RTL, height/status-bar changes, rotation, sheet/full-screen dismissal, and title actions.

The [expanded title](images/ios27-large-title-expanded.png), [collapsed title](images/ios27-large-title-collapsed.png), [adjusted buttons](images/ios27-items-positioned-large-title.png), [accessibility/RTL](images/ios27-large-title-accessibility-rtl.png), and [landscape layout](images/ios27-native-items-landscape.png) are native iPhone captures from passing UI tests, inspected in dark appearance. The comparison below only scales and arranges the first three captures; it does not alter their UI. The adjusted state uses 16-point additional leading/trailing insets and an 8-point downward offset. UIKit renders the system Done item as a checkmark on this OS.

![Expanded title, collapsed title, and adjusted buttons](images/ios27-navigation-items-proof.png)

The iOS 18.5 suite ran in light appearance. Its native Done item uses text. Touch checks use a centered 44-point target across both native styles, and rotation assertions wait for the window and header to reach the requested geometry. Interaction claims are backed by executed UI tests, not only static captures.

The [iPad scroll recording](images/ipados27-large-title-scroll.mp4) shows expansion collapsing into the compact row while the controls remain available. It is a continuous 2.8-second excerpt from the passing iPad UI test, trimmed without re-encoding or changing playback speed. The iPad run used the generated test-run specification with `SystemAttachmentLifetime=keepAlways` so its successful recording was retained.

The [push and Back recording](images/ios27-push-back.mp4) is a continuous 4.5-second excerpt from a passing iPhone UI test. It shows a push to Second, a title action, and Back returning to Main. Separate UI assertions cover repeated pushes, completed/cancelled edge swipes, and returning from Detail to the collapsed large-title screen.

The package/project metadata remained unchanged during builds and tests with automatic resolution disabled. Xcode 27's XCTest libraries declare an iOS 17 minimum, producing linker warnings for the test targets' iOS 15 setting; both tested runtimes are newer than that floor. App and package deployment targets remain iOS 15. No signing configuration was changed.

## Automated contracts

Public package tests cover external subclassing, wrapper containment and initial titles, stack identity, live theme updates, height bounds, optional title actions, navigation-item forwarding/reload, button layout, large-title modes, scroll progress, and inset ownership. Hosted UIKit tests cover configured header heights, storyboard loading, safe-area/content alignment, accessibility text growth and nonzero title width, leading-edge layout in RTL, and root/stack gesture admission.

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
