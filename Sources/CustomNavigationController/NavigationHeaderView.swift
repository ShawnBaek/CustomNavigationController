import UIKit

/// Extra spacing around the native button row, in addition to UIKit's item padding.
public struct NavigationButtonLayout: Equatable {
    public var leadingInset: CGFloat
    public var trailingInset: CGFloat
    /// Zero (the default) centers buttons vertically at every compact header height.
    /// Positive values move them down. Limited to the space inside the compact header.
    public var verticalOffset: CGFloat

    public init(leadingInset: CGFloat = 0, trailingInset: CGFloat = 0, verticalOffset: CGFloat = 0) {
        self.leadingInset = leadingInset
        self.trailingInset = trailingInset
        self.verticalOffset = verticalOffset
    }
}

/// An app-owned header. UIKit renders its items; the package owns height and large-title layout.
public final class NavigationHeaderView: UIView {
    public var customHeight: CGFloat = 66 { didSet { setNeedsLayout(); updateMetrics() } }
    public var buttonLayout = NavigationButtonLayout() { didSet { setNeedsLayout() } }
    public var title: String = "" {
        didSet {
            inlineTitle.text = title
            expandedTitle.text = title
            setNeedsLayout()
            updateMetrics()
        }
    }
    public var onTitleTap: (() -> Void)? { didSet { updateTitleAccessibility() } }

    /// Automatic Back/Close control. Supply navigationItem.leftBarButtonItems to replace it.
    public let backButton = UIButton(type: .system)
    public var titleControl: UIControl { inlineTitle }
    public var largeTitleControl: UIControl { expandedTitle }
    public private(set) var expandedTitleHeight: CGFloat = 0
    public private(set) var largeTitleCollapseProgress: CGFloat = 0

    internal var onMetricsChange: (() -> Void)?
    internal var compactHeight: CGFloat { compactHeightConstraint.constant }
    internal var showsLargeTitle = false {
        didSet { updateMetrics(); updateTitleAccessibility() }
    }
    private let inlineTitle = HeaderTitleControl(style: .headline, alignment: .center)
    private let expandedTitle = HeaderTitleControl(style: .largeTitle, alignment: .natural)
    private let compactRow = UIView()
    private let itemBar = UINavigationBar()
    private let renderedItem = UINavigationItem()
    private let titleSlot = HeaderLayoutSlot()
    private let backSlot = HeaderLayoutSlot()
    private lazy var automaticBackItem = UIBarButtonItem(customView: backSlot)
    private var hasCustomTitleView = false
    private let expansion = UIView()
    private lazy var compactHeightConstraint = compactRow.heightAnchor.constraint(equalToConstant: 66)
    private lazy var barHeight = itemBar.heightAnchor.constraint(equalToConstant: 44)
    private lazy var barLeading = itemBar.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor)
    private lazy var barTrailing = itemBar.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
    private lazy var barCenterY = itemBar.centerYAnchor.constraint(equalTo: compactRow.centerYAnchor)
    private lazy var expansionHeight = expansion.heightAnchor.constraint(equalToConstant: 0)
    private lazy var titleHeight = expandedTitle.heightAnchor.constraint(equalToConstant: 0)

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    public override func tintColorDidChange() {
        super.tintColorDidChange()
        inlineTitle.label.textColor = tintColor
        expandedTitle.label.textColor = tintColor
        itemBar.tintColor = tintColor
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            inlineTitle.updateFont(compatibleWith: traitCollection)
            expandedTitle.updateFont(compatibleWith: traitCollection)
            updateMetrics()
        }
    }

    public override func layoutSubviews() {
        updateMetrics()
        super.layoutSubviews()
        // The row owns the bar's constraints; resolve them before reading its item slots.
        compactRow.layoutIfNeeded()
        itemBar.layoutIfNeeded()
        if !backButton.isHidden, backSlot.superview != nil {
            let slot = backSlot.convert(backSlot.bounds, to: compactRow)
            let width = max(44, slot.width)
            backButton.frame = CGRect(x: slot.midX - width / 2, y: itemBar.frame.midY - 22,
                                      width: width, height: 44)
        }
        if !hasCustomTitleView, titleSlot.superview != nil {
            let slot = titleSlot.convert(titleSlot.bounds, to: compactRow)
            inlineTitle.frame = CGRect(x: slot.minX, y: 0, width: slot.width, height: compactHeight)
            updateMetrics()
        }
    }

    internal func display(left: [UIBarButtonItem], right: [UIBarButtonItem], titleView: UIView?) {
        backSlot.requestedWidth = max(44, backButton.intrinsicContentSize.width)
        renderedItem.leftBarButtonItems = (backButton.isHidden ? [] : [automaticBackItem]) + left
        renderedItem.rightBarButtonItems = right
        hasCustomTitleView = titleView != nil
        renderedItem.titleView = titleView ?? titleSlot
        inlineTitle.isHidden = hasCustomTitleView
        setNeedsLayout()
    }

    internal func collapse(by distance: CGFloat) {
        let progress = showsLargeTitle && expandedTitleHeight > 0
            ? min(1, max(0, distance.isFinite ? distance / expandedTitleHeight : 0)) : 0
        guard progress != largeTitleCollapseProgress else { return }
        largeTitleCollapseProgress = progress
        expansionHeight.constant = visibleTitleHeight
        updateTitleAccessibility()
    }

    internal var visibleTitleHeight: CGFloat {
        showsLargeTitle ? expandedTitleHeight * (1 - largeTitleCollapseProgress) : 0
    }

    private func configure() {
        backgroundColor = .systemBackground
        tintColor = .label
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
        insetsLayoutMarginsFromSafeArea = true
        backButton.isHidden = true
        backButton.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        backButton.accessibilityLabel = "Back"
        backButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(textStyle: .headline), forImageIn: .normal)
        backButton.frame.size = CGSize(width: 44, height: 44)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        itemBar.standardAppearance = appearance
        itemBar.scrollEdgeAppearance = appearance
        itemBar.compactAppearance = appearance
        itemBar.isTranslucent = true
        itemBar.setItems([renderedItem], animated: false)
        renderedItem.titleView = titleSlot
        expansion.clipsToBounds = true
        for control in [inlineTitle, expandedTitle] {
            control.addTarget(self, action: #selector(titleTapped), for: .touchUpInside)
        }
        for child in [compactRow, expansion] {
            addSubview(child)
            child.translatesAutoresizingMaskIntoConstraints = false
        }
        compactRow.addSubview(itemBar)
        compactRow.addSubview(inlineTitle)
        compactRow.addSubview(backButton)
        itemBar.translatesAutoresizingMaskIntoConstraints = false
        expansion.addSubview(expandedTitle)
        expandedTitle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            compactRow.topAnchor.constraint(equalTo: topAnchor),
            compactRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            compactRow.trailingAnchor.constraint(equalTo: trailingAnchor),
            compactHeightConstraint, barLeading, barTrailing, barCenterY, barHeight,
            expansion.topAnchor.constraint(equalTo: compactRow.bottomAnchor),
            expansion.leadingAnchor.constraint(equalTo: leadingAnchor),
            expansion.trailingAnchor.constraint(equalTo: trailingAnchor),
            expansion.bottomAnchor.constraint(equalTo: bottomAnchor), expansionHeight,
            expandedTitle.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 8),
            expandedTitle.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -8),
            expandedTitle.topAnchor.constraint(equalTo: expansion.topAnchor), titleHeight
        ])
        updateMetrics()
        updateTitleAccessibility()
    }

    private func updateMetrics() {
        let width = max(44, bounds.width > 0 ? bounds.width : 390)
        let titleWidth = inlineTitle.bounds.width > 0 ? inlineTitle.bounds.width : width * 0.5
        let titleSize = inlineTitle.sizeThatFits(CGSize(width: titleWidth, height: .greatestFiniteMagnitude))
        let compact = max(titleSize.height, max(44, customHeight.isFinite ? customHeight : 66))
        titleSlot.requestedWidth = inlineTitle.intrinsicContentSize.width
        let marginsWidth = layoutMarginsGuide.layoutFrame.width
        let expandedWidth = marginsWidth > 0 ? marginsWidth - 16 : width - 48
        let expanded = showsLargeTitle
            ? expandedTitle.sizeThatFits(CGSize(width: max(44, expandedWidth), height: .greatestFiniteMagnitude)).height : 0
        let changed = compactHeightConstraint.constant != compact || expandedTitleHeight != expanded
        compactHeightConstraint.constant = compact
        barHeight.constant = 44
        expandedTitleHeight = expanded
        titleHeight.constant = expanded
        expansionHeight.constant = visibleTitleHeight
        let available = max(0, width - directionalLayoutMargins.leading - directionalLayoutMargins.trailing - 88)
        barLeading.constant = min(available / 2, finiteNonnegative(buttonLayout.leadingInset))
        barTrailing.constant = -min(available / 2, finiteNonnegative(buttonLayout.trailingInset))
        let offset = buttonLayout.verticalOffset.isFinite ? buttonLayout.verticalOffset : 0
        barCenterY.constant = min((compact - 44) / 2, max(-(compact - 44) / 2, offset))
        if changed { onMetricsChange?() }
    }

    private func finiteNonnegative(_ value: CGFloat) -> CGFloat { value.isFinite ? max(0, value) : 0 }

    private func updateTitleAccessibility() {
        let expandedIsAccessible = showsLargeTitle && largeTitleCollapseProgress < 0.5
        inlineTitle.alpha = showsLargeTitle ? largeTitleCollapseProgress : 1
        expandedTitle.alpha = 1 - largeTitleCollapseProgress
        inlineTitle.isAccessibilityElement = !expandedIsAccessible
        expandedTitle.isAccessibilityElement = expandedIsAccessible
        expandedTitle.isHidden = !showsLargeTitle || largeTitleCollapseProgress >= 1
        for control in [inlineTitle, expandedTitle] {
            control.isUserInteractionEnabled = onTitleTap != nil
            control.accessibilityTraits = onTitleTap == nil ? [.header] : [.button, .header]
        }
    }

    @objc private func titleTapped() { onTitleTap?() }
}

private final class HeaderTitleControl: UIControl {
    let label = UILabel()
    let style: UIFont.TextStyle
    var text = "" {
        didSet { label.text = text; accessibilityLabel = text; invalidateIntrinsicContentSize() }
    }

    init(style: UIFont.TextStyle, alignment: NSTextAlignment) {
        self.style = style
        super.init(frame: .zero)
        label.numberOfLines = 2
        label.textAlignment = alignment
        label.adjustsFontForContentSizeCategory = true
        label.isAccessibilityElement = false
        addSubview(label)
        updateFont()
    }

    required init?(coder: NSCoder) { fatalError("Use init(style:alignment:)") }

    func updateFont(compatibleWith traits: UITraitCollection? = nil) {
        let font = UIFont.preferredFont(forTextStyle: style, compatibleWith: traits ?? traitCollection)
        if style == .largeTitle, let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) {
            label.font = UIFont(descriptor: descriptor, size: font.pointSize)
        } else { label.font = font }
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize { sizeThatFits(CGSize(width: 240, height: CGFloat.greatestFiniteMagnitude)) }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let fitted = label.sizeThatFits(CGSize(width: size.width, height: .greatestFiniteMagnitude))
        return CGSize(width: fitted.width, height: max(44, ceil(fitted.height) + 16))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds.insetBy(dx: 0, dy: 8)
    }
}

/// Reserves space through public bar layout while our title and Back control remain app-owned.
private final class HeaderLayoutSlot: UIView {
    var requestedWidth: CGFloat = 44 {
        didSet {
            if requestedWidth != oldValue {
                invalidateIntrinsicContentSize()
                sizeToFit()
            }
        }
    }
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        isUserInteractionEnabled = false
        isAccessibilityElement = false
    }
    required init?(coder: NSCoder) { fatalError("Use init()") }
    override var intrinsicContentSize: CGSize { CGSize(width: requestedWidth, height: 44) }
    override func sizeThatFits(_ size: CGSize) -> CGSize { intrinsicContentSize }
}
