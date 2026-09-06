import UIKit

/// Subclass for new screens, or initialize with an existing content controller.
/// The header travels with this controller through UIKit's push/pop transitions.
open class CustomNavigationViewController: UIViewController {
    public let header = NavigationHeaderView()
    /// Pin screen content here to keep it below the header and inside the device safe area.
    public let contentLayoutGuide = UILayoutGuide()
    /// The embedded controller, if this screen was created using the wrapping initializer.
    public let contentViewController: UIViewController?
    private let topBackdrop = UIView()

    public var customNavigationController: CustomNavigationController? {
        navigationController as? CustomNavigationController
    }

    open override var title: String? {
        didSet { header.title = title ?? "" }
    }

    public override init(nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: Bundle? = nil) {
        contentViewController = nil
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    /// The content must not already have a parent. Its initial title is copied to this wrapper.
    public init(contentViewController: UIViewController) {
        precondition(contentViewController.parent == nil, "Pass an unattached content view controller.")
        precondition(!(contentViewController is CustomNavigationViewController), "Use header-capable screens directly.")
        self.contentViewController = contentViewController
        super.init(nibName: nil, bundle: nil)
        title = contentViewController.title ?? contentViewController.navigationItem.title
    }

    public required init?(coder: NSCoder) {
        contentViewController = nil
        super.init(coder: coder)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addLayoutGuide(contentLayoutGuide)
        for item in [topBackdrop, header] {
            item.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(item)
        }
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            topBackdrop.topAnchor.constraint(equalTo: view.topAnchor),
            topBackdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBackdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBackdrop.bottomAnchor.constraint(equalTo: header.bottomAnchor),
            header.topAnchor.constraint(equalTo: safe.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentLayoutGuide.topAnchor.constraint(equalTo: header.bottomAnchor),
            contentLayoutGuide.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            contentLayoutGuide.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            contentLayoutGuide.bottomAnchor.constraint(equalTo: safe.bottomAnchor)
        ])
        header.backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        if let content = contentViewController {
            precondition(content.parent == nil, "The content view controller already has a parent.")
            addChild(content)
            view.addSubview(content.view)
            content.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                content.view.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
                content.view.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
                content.view.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
                content.view.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor)
            ])
            content.didMove(toParent: self)
            // Many existing controllers assign their initial title in viewDidLoad.
            if title == nil { title = content.title ?? content.navigationItem.title }
        }
        updateHeaderAppearance()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeaderAppearance()
    }

    internal func updateHeaderAppearance() {
        header.title = title ?? ""
        if let navigation = customNavigationController {
            header.customHeight = navigation.headerHeight
            header.backgroundColor = navigation.headerBackgroundColor
            header.tintColor = navigation.headerTintColor
        }
        topBackdrop.backgroundColor = header.backgroundColor
        let isRoot = navigationController?.viewControllers.first === self
        let canDismiss = navigationController?.presentingViewController != nil
        header.backButton.isHidden = navigationController == nil || (isRoot && !canDismiss)
        header.backButton.accessibilityLabel = isRoot && canDismiss
            ? customNavigationController?.closeButtonAccessibilityLabel ?? "Close"
            : customNavigationController?.backButtonAccessibilityLabel ?? "Back"
        header.backButton.setImage(UIImage(systemName: isRoot && canDismiss ? "xmark" : "chevron.backward"), for: .normal)
    }

    @objc private func goBack() {
        guard let navigationController, navigationController.transitionCoordinator == nil else { return }
        if navigationController.viewControllers.first !== self {
            navigationController.popViewController(animated: true)
        } else if navigationController.presentingViewController != nil {
            navigationController.dismiss(animated: true)
        }
    }
}
