import UIKit
import CustomNavigationController

/// Demo-only controls; header layout and navigation come from the Swift package.
class HeaderViewController: CustomNavigationViewController {
    let contentStack = UIStackView()
    let feedbackLabel = UILabel()
    private let scrollView = UIScrollView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        contentStack.axis = .vertical
        contentStack.spacing = 20
        scrollView.accessibilityIdentifier = "sampleContent"
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.addSubview(contentStack)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        ])
        header.accessibilityIdentifier = "navigationHeader"
        header.backButton.accessibilityIdentifier = "headerBack"
        header.titleControl.accessibilityIdentifier = "headerTitle"
        header.titleControl.accessibilityHint = "Shows a confirmation message."
        header.onTitleTap = { [weak self] in self?.titleTapped() }
        feedbackLabel.font = .preferredFont(forTextStyle: .footnote)
        feedbackLabel.adjustsFontForContentSizeCategory = true
        feedbackLabel.textColor = .secondaryLabel
        feedbackLabel.numberOfLines = 0
        feedbackLabel.accessibilityIdentifier = "titleFeedback"
        feedbackLabel.text = "Tap the header title to try its action."
    }

    private func titleTapped() {
        feedbackLabel.text = "\(title ?? "Header") title tapped."
        UIAccessibility.post(notification: .announcement, argument: feedbackLabel.text)
    }

    func addText(_ text: String, style: UIFont.TextStyle = .body) {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: style)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = style == .body ? .secondaryLabel : .label
        contentStack.addArrangedSubview(label)
    }

    @discardableResult
    func addButton(_ title: String, identifier: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.tinted()
        configuration.title = title
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        configuration.titleLineBreakMode = .byWordWrapping
        button.configuration = configuration
        button.accessibilityIdentifier = identifier
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        contentStack.addArrangedSubview(button)
        return button
    }

    func presentSample(style: UIModalPresentationStyle) {
        guard presentedViewController == nil,
              let screen = storyboard?.instantiateViewController(withIdentifier: "SecondViewController") as? SecondViewController else { return }
        screen.isModalSample = true
        let modal = CustomNavigationController(rootViewController: screen)
        modal.headerHeight = customNavigationController?.headerHeight ?? 66
        modal.hidesStatusBar = customNavigationController?.hidesStatusBar ?? true
        modal.headerBackgroundColor = customNavigationController?.headerBackgroundColor ?? .systemYellow
        modal.headerTintColor = customNavigationController?.headerTintColor ?? .black
        modal.statusBarStyle = customNavigationController?.statusBarStyle ?? .darkContent
        modal.modalPresentationStyle = style
        present(modal, animated: true)
    }
}


/// An ordinary UIViewController adopting the package through the wrapping initializer.
final class NavigationFeaturesViewController: UIViewController {
    let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let feedback = UILabel()
    private var layout = NavigationButtonLayout()
    private var doneItem: UIBarButtonItem!
    private var moreItem: UIBarButtonItem!
    private var owner: CustomNavigationViewController? { parent as? CustomNavigationViewController }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Navigation controls"
        navigationItem.largeTitleDisplayMode = .always
        view.backgroundColor = .systemBackground
        scrollView.accessibilityIdentifier = "featureContent"
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        stack.axis = .vertical
        stack.spacing = 16
        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        ])
        doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        doneItem.accessibilityIdentifier = "featureDone"
        moreItem = UIBarButtonItem(title: "More", style: .plain, target: nil, action: nil)
        moreItem.accessibilityIdentifier = "featureMore"
        moreItem.menu = UIMenu(children: [
            UIAction(title: "Mark favorite", image: UIImage(systemName: "star")) { [weak self] _ in
                self?.feedback.text = "Favorite selected."
            }
        ])
        navigationItem.rightBarButtonItems = [doneItem, moreItem]
        feedback.text = "Use Done or More, then adjust the button row."
        feedback.accessibilityIdentifier = "featureFeedback"
        feedback.font = .preferredFont(forTextStyle: .body)
        feedback.adjustsFontForContentSizeCategory = true
        feedback.numberOfLines = 0
        stack.addArrangedSubview(feedback)
        addPicker("Leading spacing", identifier: "leadingSpacing", items: ["0", "16", "32"], selected: 0) { [weak self] index in
            self?.layout.leadingInset = [0, 16, 32][index]
            self?.applyLayout()
        }
        addPicker("Trailing spacing", identifier: "trailingSpacing", items: ["0", "16", "32"], selected: 0) { [weak self] index in
            self?.layout.trailingInset = [0, 16, 32][index]
            self?.applyLayout()
        }
        addPicker("Vertical offset", identifier: "verticalPosition", items: ["−8", "0", "+8"], selected: 1) { [weak self] index in
            self?.layout.verticalOffset = [-8, 0, 8][index]
            self?.applyLayout()
        }
        addPicker("Title", identifier: "titleMode", items: ["Large", "Inline"], selected: 0) { [weak self] index in
            self?.navigationItem.largeTitleDisplayMode = index == 0 ? .always : .never
            self?.owner?.reloadNavigationItems()
        }
        addButton("Toggle Done enabled", identifier: "toggleDone") { [weak self] in
            guard let self else { return }
            self.doneItem.isEnabled.toggle()
            self.feedback.text = self.doneItem.isEnabled ? "Done enabled." : "Done disabled."
        }
        addButton("Replace Done with Save", identifier: "replaceDone") { [weak self] in
            guard let self else { return }
            self.doneItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(self.saved))
            self.doneItem.accessibilityIdentifier = "featureDone"
            self.navigationItem.rightBarButtonItems = [self.doneItem, self.moreItem]
            self.owner?.reloadNavigationItems()
        }
        addButton("Push detail", identifier: "featurePush") { [weak self] in
            guard let navigation = self?.navigationController as? CustomNavigationController else { return }
            let detail = UIViewController()
            detail.title = "Detail"
            detail.navigationItem.largeTitleDisplayMode = .never
            detail.view.backgroundColor = .systemBackground
            let screen = navigation.pushContentViewController(detail)
            screen.header.backButton.accessibilityIdentifier = "headerBack"
            screen.header.titleControl.accessibilityIdentifier = "headerTitle"
        }
        addButton("Present sheet with Done", identifier: "featureModal") { [weak self] in
            guard let self else { return }
            let content = UIViewController()
            content.title = "Modal"
            content.view.backgroundColor = .systemBackground
            content.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.closeModal))
            content.navigationItem.rightBarButtonItem?.accessibilityIdentifier = "modalDone"
            let modal = CustomNavigationController(contentViewController: content)
            modal.modalPresentationStyle = .pageSheet
            self.present(modal, animated: true)
        }
        let explanation = UILabel()
        explanation.text = "Scroll to collapse the large title. Back and Done stay in the compact row. Button spacing follows the layout direction; vertical movement stays inside the header."
        explanation.font = .preferredFont(forTextStyle: .body)
        explanation.adjustsFontForContentSizeCategory = true
        explanation.numberOfLines = 0
        stack.addArrangedSubview(explanation)
        for index in 1...12 {
            let label = UILabel()
            label.text = "Scroll example \(index)"
            label.font = .preferredFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
            stack.addArrangedSubview(label)
        }
    }

    private func applyLayout() { owner?.buttonLayoutOverride = layout }
    @objc private func doneTapped() { feedback.text = "Done tapped." }
    @objc private func saved() { feedback.text = "Saved." }
    @objc private func closeModal() { dismiss(animated: true) }

    private func addPicker(_ text: String, identifier: String, items: [String], selected: Int, action: @escaping (Int) -> Void) {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        stack.addArrangedSubview(label)
        let picker = UISegmentedControl(items: items)
        picker.selectedSegmentIndex = selected
        picker.accessibilityIdentifier = identifier
        picker.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        picker.addAction(UIAction { [weak picker] _ in
            if let picker { action(picker.selectedSegmentIndex) }
        }, for: .valueChanged)
        stack.addArrangedSubview(picker)
    }

    private func addButton(_ title: String, identifier: String, action: @escaping () -> Void) {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.tinted()
        configuration.title = title
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        button.configuration = configuration
        button.accessibilityIdentifier = identifier
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        stack.addArrangedSubview(button)
    }
}
