import UIKit
import CustomNavigationController

final class SecondViewController: HeaderViewController {
    var isModalSample = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = isModalSample ? "Modal" : "Second"
        addText(isModalSample ? "Return without losing your header." : "Keep the whole screen together.", style: .title1)
        addText(isModalSample ? "Close this screen, then try the title and navigation buttons again." : "Swipe from the leading edge to go back. Try releasing a short swipe to cancel; this screen and its header should stay together.")
        if !isModalSample {
            addButton("Present sheet", identifier: "presentSheet") { [weak self] in self?.presentSample(style: .pageSheet) }
            addButton("Present full screen", identifier: "presentFullScreen") { [weak self] in self?.presentSample(style: .fullScreen) }
        }
        contentStack.addArrangedSubview(feedbackLabel)
    }
}
