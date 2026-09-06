# Custom header layout

The library replaces internal `UINavigationBar` frame manipulation with a screen-owned `NavigationHeaderView`. Its minimum deployment target is iOS 15; it has no external dependencies or resource bundles.

`CustomNavigationController` owns the UIKit stack, theme, status-bar policy, and public edge-gesture admission gate. `CustomNavigationViewController` owns a header and safe content layout guide. It can be subclassed or contain an existing controller. UIKit moves the whole screen and header together through push, pop, and cancellation, avoiding a separate header whose state needs repairing after transitions.

The header begins at the top safe-area anchor. A backdrop of the same color fills the top inset. Content begins at the header's bottom and stays within horizontal and bottom safe areas. There are no global status-bar measurements, fixed screen widths, device-name branches, or duplicate safe-area insets. Height is preferred rather than required so Dynamic Type can expand the two-line title while maintaining 44-point controls.

The Xcode sample links the local Swift package product. Its storyboard constructs the package navigation controller, while app-only subclasses implement the demonstration controls. Public API tests import only the package module. The app test target also compiles that same test source so the shared app scheme executes it reliably; Xcode omits test configurations from its dependency package scheme. App integration tests exercise storyboard loading and scene layout, while UI tests exercise complete interactions.

The wrapper API uses standard child-controller containment. It deliberately does not intercept ordinary pushes/segues or forward native navigation-item features. See [adoption](adoption.md) for the two integration paths and their boundaries. The system edge recognizer keeps UIKit's target/action with a narrow public delegate gate; this remains a regression-test area for every supported OS.
