import UIKit

/// A self-sizing header that does not resize or inspect UIKit's navigation bar.
public final class NavigationHeaderView: UIView {
    /// Preferred height below the safe area. Clamped to 44 points; large text can expand it.
    public var customHeight: CGFloat = 66 {
        didSet { preferredHeight.constant = max(44, customHeight.isFinite ? customHeight : 66) }
    }

    public var title: String = "" {
        didSet {
            titleLabel.text = title
            titleControl.accessibilityLabel = title
        }
    }

    /// An optional title action. Capture owning view controllers weakly.
    public var onTitleTap: (() -> Void)? {
        didSet {
            titleControl.isUserInteractionEnabled = onTitleTap != nil
            titleControl.accessibilityTraits = onTitleTap == nil ? [.header] : [.button, .header]
        }
    }

    /// Hidden until the owning screen supplies a back or dismiss action.
    public let backButton = UIButton(type: .system)
    /// Exposed for accessibility labels/hints and inspection; use `onTitleTap` for actions.
    public let titleControl = UIControl()
    private let titleLabel = UILabel()
    private let trailingSpace = UIView()
    private lazy var preferredHeight = heightAnchor.constraint(equalToConstant: customHeight)

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
        titleLabel.textColor = tintColor
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

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.textColor = tintColor
        titleLabel.isAccessibilityElement = false
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleControl.isAccessibilityElement = true
        titleControl.isUserInteractionEnabled = false
        titleControl.accessibilityTraits = [.header]
        titleControl.addTarget(self, action: #selector(titleTapped), for: .touchUpInside)
        titleControl.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        for item in [backButton, titleControl, trailingSpace] {
            addSubview(item)
            item.translatesAutoresizingMaskIntoConstraints = false
        }
        preferredHeight.priority = .defaultHigh
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 44), preferredHeight,
            backButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            trailingSpace.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            trailingSpace.centerYAnchor.constraint(equalTo: centerYAnchor),
            trailingSpace.widthAnchor.constraint(equalTo: backButton.widthAnchor),
            trailingSpace.heightAnchor.constraint(equalToConstant: 44),
            titleControl.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 4),
            titleControl.trailingAnchor.constraint(equalTo: trailingSpace.leadingAnchor, constant: -4),
            titleControl.topAnchor.constraint(equalTo: topAnchor),
            titleControl.bottomAnchor.constraint(equalTo: bottomAnchor),
            titleControl.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            titleLabel.leadingAnchor.constraint(equalTo: titleControl.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: titleControl.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: titleControl.topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: titleControl.bottomAnchor, constant: -8)
        ])
    }

    @objc private func titleTapped() { onTitleTap?() }
}
