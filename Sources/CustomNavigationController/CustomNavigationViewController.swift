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
    private var didConfigureHeader = false
    private lazy var fullContentTop = contentLayoutGuide.topAnchor.constraint(equalTo: header.bottomAnchor)
    private lazy var compactContentTop = contentLayoutGuide.topAnchor.constraint(equalTo: header.topAnchor)
    private lazy var scrollTracking = LargeTitleScrollCoordinator { [weak self] distance in
        self?.header.collapse(by: distance)
    }

    /// Set the primary scroll view to enable scroll-driven large-title collapse.
    /// Its delegate and existing inset edges remain owned by the caller.
    public weak var largeTitleScrollView: UIScrollView? {
        didSet {
            scrollTracking.attach(largeTitleScrollView)
            if isViewLoaded { updateLargeTitleLayout() }
        }
    }

    /// Override the navigation controller's shared button layout for this screen.
    public var buttonLayoutOverride: NavigationButtonLayout? {
        didSet { if isViewLoaded { updateHeaderAppearance() } }
    }

    private var sourceNavigationItem: UINavigationItem { contentViewController?.navigationItem ?? navigationItem }

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
            fullContentTop,
            contentLayoutGuide.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            contentLayoutGuide.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            contentLayoutGuide.bottomAnchor.constraint(equalTo: safe.bottomAnchor)
        ])
        didConfigureHeader = true
        header.onMetricsChange = { [weak self] in self?.updateLargeTitleLayout() }
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
        view.bringSubviewToFront(topBackdrop)
        view.bringSubviewToFront(header)
    }

    /// Refresh after replacing items or changing navigation-item settings while visible.
    /// Called automatically after loading and whenever the screen appears.
    public func reloadNavigationItems() {
        guard didConfigureHeader else { return }
        let item = sourceNavigationItem
        header.title = contentViewController == nil ? item.title ?? title ?? "" : title ?? item.title ?? ""
        header.showsLargeTitle = wantsLargeTitle
        let isRoot = navigationController?.viewControllers.first === self
        let canDismiss = navigationController?.presentingViewController != nil
        let left = item.leftBarButtonItems ?? []
        header.backButton.isHidden = navigationController == nil || (isRoot && !canDismiss)
            || item.hidesBackButton || (!left.isEmpty && !item.leftItemsSupplementBackButton)
        header.backButton.accessibilityLabel = isRoot && canDismiss
            ? customNavigationController?.closeButtonAccessibilityLabel ?? "Close"
            : customNavigationController?.backButtonAccessibilityLabel ?? "Back"
        header.backButton.setImage(UIImage(systemName: isRoot && canDismiss ? "xmark" : "chevron.backward"), for: .normal)
        var backTitle: String?
        if !isRoot, let stack = navigationController?.viewControllers,
           let index = stack.firstIndex(of: self), index > 0 {
            let previous = stack[index - 1]
            let previousItem = (previous as? CustomNavigationViewController)?.sourceNavigationItem ?? previous.navigationItem
            if previousItem.backButtonDisplayMode != .minimal {
                backTitle = previousItem.backButtonTitle ?? previousItem.backBarButtonItem?.title
            }
        }
        header.backButton.setTitle(backTitle, for: .normal)
        header.display(left: left,
                       right: item.rightBarButtonItems ?? [], titleView: item.titleView)
        updateLargeTitleLayout()
    }

    private var wantsLargeTitle: Bool {
        guard let navigation = customNavigationController, navigation.prefersLargeTitles else { return false }
        var enabled = true
        for screen in navigation.viewControllers {
            let item = (screen as? CustomNavigationViewController)?.sourceNavigationItem ?? screen.navigationItem
            if item.largeTitleDisplayMode == .always { enabled = true }
            if item.largeTitleDisplayMode == .never { enabled = false }
            if screen === self { break }
        }
        return enabled
    }

    private func updateLargeTitleLayout() {
        guard didConfigureHeader else { return }
        let tracksScroll = header.showsLargeTitle && largeTitleScrollView != nil
        compactContentTop.constant = header.compactHeight
        if tracksScroll {
            fullContentTop.isActive = false
            compactContentTop.isActive = true
        } else {
            compactContentTop.isActive = false
            fullContentTop.isActive = true
        }
        scrollTracking.setExpandedHeight(tracksScroll ? header.expandedTitleHeight : 0)
        if !tracksScroll { header.collapse(by: 0) }
    }

    internal func updateHeaderAppearance() {
        if let navigation = customNavigationController {
            header.customHeight = navigation.headerHeight
            header.backgroundColor = navigation.headerBackgroundColor
            header.tintColor = navigation.headerTintColor
        }
        header.buttonLayout = buttonLayoutOverride ?? customNavigationController?.buttonLayout ?? NavigationButtonLayout()
        topBackdrop.backgroundColor = header.backgroundColor
        reloadNavigationItems()
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
