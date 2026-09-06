# Adoption guide

## Existing programmatic or storyboard screens

Use `CustomNavigationController(contentViewController:)` for your first screen and `pushContentViewController(_:animated:)` for subsequent screens. You can pass an existing `UITableViewController`, a programmatic controller, or a controller instantiated from a storyboard. The package adds it as a child below the header with standard UIKit containment; its existing layout stays inside that content area.

```swift
let storyboard = UIStoryboard(name: "Main", bundle: nil)
let existing = storyboard.instantiateViewController(withIdentifier: "Account")
let navigation = CustomNavigationController(contentViewController: existing)
```

The content's `navigationController` reaches the containing navigation controller. Use `navigationController as? CustomNavigationController` to call the push helper from that content. A header-capable `CustomNavigationViewController` passed to either helper is reused without another wrapper.

The wrapper is the entry returned by `popViewController`, `topViewController`, and `viewControllers`. Its `contentViewController` identifies the embedded screen. Set the wrapper's `title` for changes after initial loading. Buttons and large-title display mode come from the content's `navigationItem`. Search controllers, child orientation rules, and sizing/system-gesture preferences are not automatically forwarded. Screens with specialized container behavior should use the subclass path or integrate `NavigationHeaderView` directly.

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

## Navigation items and button positions

Use standard items in an existing controller or a package subclass:

```swift
navigationItem.rightBarButtonItem = UIBarButtonItem(
    barButtonSystemItem: .done, target: self, action: #selector(doneTapped)
)
// Implement @objc func doneTapped() in your screen.
```

Items are read after loading and on each appearance. If you replace an item or alter navigation-item settings while visible, call `reloadNavigationItems()` on your `CustomNavigationViewController` (the wrapper for an existing screen). Changes such as an existing item's `isEnabled` or title use UIKit's own item rendering. Original target/action, `UIAction`, menu, and custom-view behavior stay with the item.

Back is automatic on pushed screens and Close on a presented root. `hidesBackButton` hides that control. Leading items replace it unless `leftItemsSupplementBackButton` is true. Set the previous screen's `backButtonTitle` or `backBarButtonItem.title` to add text; `.minimal` keeps the chevron alone. The automatic action still pops or dismisses.

```swift
navigation.buttonLayout = NavigationButtonLayout(
    leadingInset: 16, trailingInset: 24, verticalOffset: 6
)
screen.buttonLayoutOverride = NavigationButtonLayout(trailingInset: 32)
```

Leading/trailing values are additional directional outer insets, so they follow RTL. The default `verticalOffset` is zero: buttons stay vertically centered in the compact navigation row regardless of `headerHeight`. Large-title expansion sits below that row and does not move its center. Setting an explicit offset moves the complete button row independently of the title. It is clamped within the compact header; use a taller `headerHeight` for more travel. Insets never reduce the row below its minimum width. UIKit still chooses individual item widths, padding, and overflow behavior. Custom views should provide an appropriate intrinsic size and touch target.

## Scrolling large titles

```swift
navigation.prefersLargeTitles = true
content.navigationItem.largeTitleDisplayMode = .always
screen.largeTitleScrollView = content.tableView
screen.reloadNavigationItems()
```

The navigation-wide preference enables the feature. `.always` and `.never` select a screen's mode; `.automatic` inherits the previous screen's mode, or the navigation preference at the root. The custom header implements expansion/collapse; it does not reproduce UIKit's private large-title animation or search behavior.

Choose one primary scroll view explicitly. For a subclass, assign `largeTitleScrollView` after creating your scroll view. For a wrapped table or collection controller, assign its `tableView` or `collectionView` to the returned wrapper. Enable `alwaysBounceVertical` if short content should still scroll.

With tracking enabled, `contentLayoutGuide` stays below the **compact** row and the package adds the expanded-title height to the scroll view's existing top content inset. The expanded header overlays that space while scrolling; the visible expansion controls the indicator inset. The scroll delegate is unchanged. Replacing/clearing the selected scroll view or disabling large titles removes the package's inset contribution. Without tracking, the guide stays below the full expanded header.

Use `header.largeTitleControl` to set accessibility labels or identifiers for the expanded title. `onTitleTap` applies to both title presentations, with only the visible presentation exposed as an accessible heading.

## Maintaining compatibility

The package uses public UIKit layout and transition APIs. The system navigation bar is hidden; the package does not reproduce every native navigation-bar feature or appearance. Edge-swipe behavior depends on UIKit and must be tested on each supported OS, including cancelled transitions. An iOS 15 deployment target is an API floor, not proof of execution on every version or future release.
