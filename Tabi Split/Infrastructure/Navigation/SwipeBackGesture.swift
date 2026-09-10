//
//  SwipeBackGesture.swift
//  Tabi Split
//
//  Created by Claude on 10/09/26.
//

import SwiftUI
import UIKit

/// Re-arms the native edge-swipe back gesture for the screen that renders it.
///
/// Every pushed screen hides the system back button (`navigationBarBackButtonHidden`)
/// in favour of `TopNavigation`'s own arrow, and UIKit refuses the interactive pop
/// gesture whenever that back button is hidden. This zero-sized view reaches the
/// `UINavigationController` backing the `NavigationStack`, takes over the pop
/// gesture's delegate, and lets the gesture begin only while the top screen contains
/// one of these views. Screens without it (login, register, roots) keep the
/// no-swipe behaviour, which is what stopped the old global override — swiping
/// away the login screen mid sign-in left the stack in a bad state.
struct SwipeBackGesture: UIViewControllerRepresentable {
    /// Runs once a swipe-back has landed (not when the drag is released short of the
    /// threshold and snaps back), so a screen's back-arrow side effects
    /// (`TopNavigation.additionalBackFunction`) also happen on swipe.
    var onSwipeBack: (() -> Void)?

    func makeUIViewController(context: Context) -> Marker {
        Marker()
    }

    func updateUIViewController(_ marker: Marker, context: Context) {
        marker.onSwipeBack = onSwipeBack
    }

    /// Flags its owning screen as swipe-back enabled. SwiftUI adds it as a child of
    /// the screen's hosting controller, so `navigationController` resolves to the
    /// stack's backing navigation controller.
    final class Marker: UIViewController {
        var onSwipeBack: (() -> Void)?

        override func viewDidLoad() {
            super.viewDidLoad()
            view.isUserInteractionEnabled = false
        }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            SwipeBackCoordinator.install(on: navigationController)
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            // Re-run on every appearance: the navigation controller may not have been
            // reachable yet in `didMove(toParent:)`.
            SwipeBackCoordinator.install(on: navigationController)
        }
    }
}

/// One per navigation controller (tied to its lifetime via an associated object).
/// Acts as the pop gesture's delegate and relays a completed swipe to the popped
/// screen's `onSwipeBack`.
private final class SwipeBackCoordinator: NSObject, UIGestureRecognizerDelegate {
    private static var associatedKey: UInt8 = 0

    private weak var navigationController: UINavigationController?

    /// Callback of the screen being swiped away. Captured when the gesture is allowed
    /// to begin — while that screen is still `topViewController` — and fired once the
    /// pop has actually landed.
    private var pendingSwipeBack: (() -> Void)?

    static func install(on navigationController: UINavigationController?) {
        guard let navigationController,
              let gesture = navigationController.interactivePopGestureRecognizer else {
            return
        }

        let coordinator: SwipeBackCoordinator
        if let existing = objc_getAssociatedObject(navigationController, &associatedKey) as? SwipeBackCoordinator {
            coordinator = existing
        } else {
            coordinator = SwipeBackCoordinator(navigationController: navigationController)
            objc_setAssociatedObject(navigationController, &associatedKey, coordinator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            gesture.addTarget(coordinator, action: #selector(gestureStateChanged(_:)))
        }

        // Re-asserted on every install: SwiftUI owns this navigation controller and
        // may reset the delegate as screens come and go.
        gesture.delegate = coordinator
        gesture.isEnabled = true
    }

    private init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
    }

    // MARK: UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let navigationController,
              // Nothing to pop back to.
              navigationController.viewControllers.count > 1,
              // Never start a pop while a push/pop is animating: UIKit's stock delegate
              // blocks this too, because it wedges the navigation stack.
              navigationController.transitionCoordinator == nil,
              let topViewController = navigationController.topViewController,
              let marker = Self.marker(in: topViewController) else {
            return false
        }

        pendingSwipeBack = marker.onSwipeBack
        return true
    }

    // MARK: Gesture completion

    @objc private func gestureStateChanged(_ gestureRecognizer: UIGestureRecognizer) {
        switch gestureRecognizer.state {
        case .ended, .cancelled, .failed:
            guard let onSwipeBack = pendingSwipeBack else { return }
            pendingSwipeBack = nil

            // The pop was started by UIKit when the gesture began, so its transition
            // coordinator is still alive here. Its completion runs after the animation
            // settles, with `isCancelled` set when the drag snapped back instead.
            navigationController?.transitionCoordinator?.animate(alongsideTransition: nil) { context in
                guard !context.isCancelled else { return }
                onSwipeBack()
            }
        default:
            break
        }
    }

    private static func marker(in viewController: UIViewController) -> SwipeBackGesture.Marker? {
        if let marker = viewController as? SwipeBackGesture.Marker {
            return marker
        }
        for child in viewController.children {
            if let marker = marker(in: child) {
                return marker
            }
        }
        return nil
    }
}
