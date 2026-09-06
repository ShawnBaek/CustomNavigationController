import UIKit

/// Owns only the extra top insets. The client's delegate and other inset edges are untouched.
@MainActor
internal final class LargeTitleScrollCoordinator {
    private weak var scrollView: UIScrollView?
    private var observations: [NSKeyValueObservation] = []
    private var expandedHeight: CGFloat = 0
    private var indicatorContribution: CGFloat = 0
    private var isUpdating = false
    private let onScroll: (CGFloat) -> Void

    init(onScroll: @escaping (CGFloat) -> Void) { self.onScroll = onScroll }

    func attach(_ scrollView: UIScrollView?) {
        guard self.scrollView !== scrollView else { return }
        setExpandedHeight(0)
        observations.removeAll()
        self.scrollView = scrollView
        if let scrollView {
            observations = [
                scrollView.observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
                    MainActor.assumeIsolated { self?.didScroll() }
                },
                scrollView.observe(\.adjustedContentInset, options: [.new]) { [weak self] _, _ in
                    MainActor.assumeIsolated { self?.didScroll() }
                }
            ]
        }
    }

    func setExpandedHeight(_ height: CGFloat) {
        guard !isUpdating else { return }
        guard let scrollView else {
            expandedHeight = 0
            indicatorContribution = 0
            return
        }
        let height = max(0, height.isFinite ? height : 0)
        guard height != expandedHeight else { didScroll(); return }
        isUpdating = true
        let oldProgress = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        let oldCollapsed = min(expandedHeight, max(0, oldProgress))
        let fraction = expandedHeight > 0 ? oldCollapsed / expandedHeight : (oldProgress > 0 ? 1 : 0)
        let newProgress = oldProgress + fraction * height - oldCollapsed
        let delta = height - expandedHeight
        expandedHeight = height
        var inset = scrollView.contentInset
        inset.top += delta
        scrollView.contentInset = inset
        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x,
                                           y: newProgress - scrollView.adjustedContentInset.top), animated: false)
        isUpdating = false
        didScroll()
    }

    private func didScroll() {
        guard !isUpdating, let scrollView else { return }
        let distance = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        let visible = max(0, expandedHeight - max(0, distance))
        var indicators = scrollView.verticalScrollIndicatorInsets
        indicators.top += visible - indicatorContribution
        indicatorContribution = visible
        scrollView.verticalScrollIndicatorInsets = indicators
        onScroll(distance)
    }

    deinit {
        observations.forEach { $0.invalidate() }
        let cleanup: @MainActor () -> Void = { [weak scrollView, expandedHeight, indicatorContribution] in
            guard let scrollView else { return }
            let progress = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
            let collapsed = min(expandedHeight, max(0, progress))
            scrollView.contentInset.top -= expandedHeight
            scrollView.verticalScrollIndicatorInsets.top -= indicatorContribution
            scrollView.contentOffset.y = progress - collapsed - scrollView.adjustedContentInset.top
        }
        if Thread.isMainThread { MainActor.assumeIsolated { cleanup() } }
        else { DispatchQueue.main.async { cleanup() } }
    }
}
