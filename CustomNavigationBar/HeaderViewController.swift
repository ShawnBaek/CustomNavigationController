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
