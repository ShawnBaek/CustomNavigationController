# Adoption guide

## Existing programmatic or storyboard screens

Use `CustomNavigationController(contentViewController:)` for your first screen and `pushContentViewController(_:animated:)` for subsequent screens. You can pass an existing `UITableViewController`, a programmatic controller, or a controller instantiated from a storyboard. The package adds it as a child below the header with standard UIKit containment; its existing layout stays inside that content area.

```swift
let storyboard = UIStoryboard(name: "Main", bundle: nil)
let existing = storyboard.instantiateViewController(withIdentifier: "Account")
let navigation = CustomNavigationController(contentViewController: existing)
```

The content's `navigationController` reaches the containing navigation controller. Use `navigationController as? CustomNavigationController` to call the push helper from that content. A header-capable `CustomNavigationViewController` passed to either helper is reused without another wrapper.

The wrapper is the entry returned by `popViewController`, `topViewController`, and `viewControllers`. Its `contentViewController` identifies the embedded screen. Set the wrapper's `title` for changes after initial loading. Native `navigationItem` buttons, large titles, search controllers, child orientation rules, and sizing/system-gesture preferences are not automatically forwarded. Screens with specialized container behavior should use the subclass path or integrate `NavigationHeaderView` directly.

A normal `pushViewController`, `show`, or storyboard Show segue does not automatically wrap an arbitrary screen. Use the helper for existing controllers, or make segue destinations subclasses of `CustomNavigationViewController` as the sample does.

## Storyboard and IBOutlet layout

For a new storyboard-backed screen, set its custom class to your subclass of `CustomNavigationViewController`, in your app module. Set the navigation controller scene's custom class **and module** to `CustomNavigationController`; turn off “Inherit Module From Target” for that navigation scene. The sample's Main storyboard demonstrates this setup.

Put the screen's content inside a container view connected to an outlet. Keep the container's internal constraints in Interface Builder. Remove its four outer position/size constraints there, then constrain it to the package's content guide after `super.viewDidLoad()`:

```swift
import UIKit
import CustomNavigationController

final class AccountScreen: CustomNavigationViewController {
    @IBOutlet private var contentContainer: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Account"
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor)
        ])
    }
}
```

Changing only the superclass does not move existing safe-area constraints below the header. Use the wrapper path if you want to retain those existing constraints unchanged.

## Modals and appearance

Wrap the presented screen in a custom navigation controller. A presented root automatically gets a Close control; pushed screens get Back.

```swift
let modal = CustomNavigationController(contentViewController: SettingsViewController())
modal.headerHeight = navigation.headerHeight
modal.headerBackgroundColor = navigation.headerBackgroundColor
modal.headerTintColor = navigation.headerTintColor
modal.hidesStatusBar = navigation.hidesStatusBar
modal.statusBarStyle = navigation.statusBarStyle
modal.modalPresentationStyle = .pageSheet // Or .fullScreen
present(modal, animated: true)
```

Prefer navigation-controller properties for shared height and color settings. They update loaded screens immediately and are applied to newly loaded screens. `header.onTitleTap` is optional; capture the owning screen weakly to avoid a retain cycle. The exposed back button and title control allow app-specific accessibility labels, hints, and identifiers. The library ships no demo identifiers or feedback actions.

## Maintaining compatibility

The package uses public UIKit layout and transition APIs. The system navigation bar is hidden; the package does not reproduce every native navigation-bar feature or appearance. Edge-swipe behavior depends on UIKit and must be tested on each supported OS, including cancelled transitions. An iOS 15 deployment target is an API floor, not proof of execution on every version or future release.
