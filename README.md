# CustomNavigationController

A small UIKit Swift package for custom-height navigation headers. Keep the original 66-point look, choose your own height and colors, and use UIKit's push, pop, edge-swipe, and modal transitions.

**iOS / iPadOS 15+ · Swift tools 5.9+ · No dependencies**

The header is an ordinary view owned by each screen. It uses safe areas and Dynamic Type instead of resizing UIKit's internal navigation bar. The design supports modern iOS; tested versions and remaining gaps are listed in [validation](docs/validation.md).

## Install

In Xcode, add a package dependency using [this repository](https://github.com/ShawnBaek/CustomNavigationController), choose the **master branch**, and select the **CustomNavigationController** product for your app target. Use the branch rule until a versioned package release is tagged.

For local development, add this checkout as a local package. The included `CustomNavigationBar.xcodeproj` already consumes the same package.

For another local Swift package:

```swift
// In Package.swift:
dependencies: [
    .package(path: "../CustomNavigationController")
],
targets: [
    .target(name: "YourFeature", dependencies: [
        .product(name: "CustomNavigationController", package: "CustomNavigationController")
    ])
]
```

## Use with existing screens

Keep your existing view controller and its layout:

```swift
import UIKit
import CustomNavigationController

let home = HomeViewController()
home.title = "Home"
let navigation = CustomNavigationController(contentViewController: home)
navigation.headerHeight = 66
navigation.headerBackgroundColor = .systemYellow
navigation.headerTintColor = .black
navigation.statusBarStyle = .darkContent
window.rootViewController = navigation
window.makeKeyAndVisible()
```

Push another existing screen:

```swift
let detail = DetailViewController()
detail.title = "Details"
let screen = navigation.pushContentViewController(detail)
screen.header.onTitleTap = { [weak detail] in
    detail?.showTitleDetails()
}
```

The helper embeds your controller below a header and returns the wrapper placed on the navigation stack. Initial `title` (or `navigationItem.title`) is copied, including a title set in `viewDidLoad`. For later changes, set `screen.title`. Pass controllers that do not already have a parent.

## Build a new screen

Subclass `CustomNavigationViewController` and pin content to `contentLayoutGuide`:

```swift
final class DetailsScreen: CustomNavigationViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Details"
        let label = UILabel()
        label.text = "Your content"
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor, constant: 24),
            label.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(lessThanOrEqualTo: contentLayoutGuide.trailingAnchor, constant: -24)
        ])
    }
}

// Header-capable screens use the normal UIKit stack API.
let navigation = CustomNavigationController(rootViewController: DetailsScreen())
navigation.pushViewController(DetailsScreen(), animated: true)
```

The preferred height excludes the top safe area, has a 44-point minimum, and grows for larger text. Titles use up to two visual lines; accessibility receives the full title. Colors adapt to light/dark appearance by default, and the status bar is visible unless `hidesStatusBar` is enabled. `backButtonAccessibilityLabel` and `closeButtonAccessibilityLabel` let your app supply localized labels.

For storyboard / `IBOutlet` adoption, modal examples, and wrapper boundaries, see the [adoption guide](docs/adoption.md). Use a system navigation bar if you need native large titles, search bars, navigation-item buttons, or the OS's navigation-bar appearance.

## Run the sample

Open `CustomNavigationBar.xcodeproj`, select `CustomNavigationBar`, and run on an iPhone or iPad Simulator. Try heights 44/66/88, title taps, push/back, cancelled edge swipes, sheets, full-screen modals, rotation, and accessibility text sizes.

[Architecture](docs/architecture.md) · [Tests and verification status](docs/validation.md) · [MIT license](LICENSE)
