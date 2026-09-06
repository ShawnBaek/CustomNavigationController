import UIKit
import CustomNavigationController

final class ViewController: HeaderViewController {
    private weak var statusButton: UIButton?
    private var openedFeatureSample = false

    override func viewDidLoad() {
        customNavigationController?.headerBackgroundColor = .systemYellow
        customNavigationController?.headerTintColor = .black
        customNavigationController?.statusBarStyle = .darkContent
        customNavigationController?.hidesStatusBar = true
        super.viewDidLoad()
        title = "Main"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Info", style: .plain, target: self, action: #selector(showInfo))
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "rootInfo"
        addText("Your height. Your header.", style: .title1)
        addText("Try a taller navigation header, move between screens, and return from a modal. The yellow area stays with its screen.")
        addText("Header height", style: .headline)
        let heightPicker = UISegmentedControl(items: ["44 pt", "66 pt", "88 pt"])
        heightPicker.selectedSegmentIndex = 1
        heightPicker.accessibilityIdentifier = "heightPicker"
        heightPicker.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        heightPicker.addAction(UIAction { [weak self, weak heightPicker] _ in
            guard let heightPicker else { return }
            self?.customNavigationController?.headerHeight = [44, 66, 88][heightPicker.selectedSegmentIndex]
        }, for: .valueChanged)
        contentStack.addArrangedSubview(heightPicker)
        statusButton = addButton("Show status bar", identifier: "toggleStatusBar") { [weak self] in
            guard let navigation = self?.customNavigationController else { return }
            navigation.hidesStatusBar.toggle()
            self?.statusButton?.configuration?.title = navigation.hidesStatusBar ? "Show status bar" : "Hide status bar"
            self?.feedbackLabel.text = navigation.hidesStatusBar ? "Status bar hidden." : "Status bar visible."
        }
        addButton("Push view controller", identifier: "pushDetail") { [weak self] in
            guard self?.navigationController?.transitionCoordinator == nil else { return }
            self?.performSegue(withIdentifier: "showDetail", sender: nil)
        }
        addButton("Present sheet", identifier: "presentSheet") { [weak self] in self?.presentSample(style: .pageSheet) }
        addButton("Present full screen", identifier: "presentFullScreen") { [weak self] in self?.presentSample(style: .fullScreen) }
        contentStack.addArrangedSubview(feedbackLabel)
        addText("The selected height excludes the device safe area. Larger accessibility text can expand the header to stay readable.", style: .footnote)
        addButton("Navigation buttons & large titles", identifier: "showNavigationFeatures") { [weak self] in
            self?.showNavigationFeatures(animated: true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !openedFeatureSample && ProcessInfo.processInfo.arguments.contains("--navigation-features") {
            showNavigationFeatures(animated: false)
        }
    }

    private func showNavigationFeatures(animated: Bool) {
        guard let navigation = customNavigationController else { return }
        openedFeatureSample = true
        navigation.prefersLargeTitles = true
        let content = NavigationFeaturesViewController()
        let screen = navigation.pushContentViewController(content, animated: animated)
        screen.header.accessibilityIdentifier = "navigationHeader"
        screen.header.titleControl.accessibilityIdentifier = "headerTitle"
        screen.header.largeTitleControl.accessibilityIdentifier = "largeHeaderTitle"
        screen.header.backButton.accessibilityIdentifier = "headerBack"
        screen.largeTitleScrollView = content.scrollView
    }

    @objc private func showInfo() { feedbackLabel.text = "Native navigation item tapped." }
}
