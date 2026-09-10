//
//  SwipeBackGestureTests.swift
//  Tabi Split Tests
//
//  Hosts a real NavigationStack in a window and checks that the interactive pop
//  (edge-swipe back) gesture is allowed exactly on screens that render a
//  TopNavigation header, and stays blocked on the root and on header-less screens.
//

import XCTest
import SwiftUI
@testable import Tabi_Split

@MainActor
final class SwipeBackGestureTests: XCTestCase {
    private var window: UIWindow?

    override func tearDown() {
        window?.isHidden = true
        window = nil
    }

    /// Stand-in for the app's destinations: `.profile` renders the shared header,
    /// `.login` does not (mirrors the real LoginView, which has no TopNavigation).
    private struct Harness: View {
        @Bindable var router: Router

        var body: some View {
            NavigationStack(path: $router.path) {
                Text("Root")
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .profile:
                            VStack {
                                TopNavigation(title: "With header")
                                Text("Body")
                            }
                            .navigationBarBackButtonHidden(true)
                        default:
                            Text("No header")
                                .navigationBarBackButtonHidden(true)
                        }
                    }
            }
            .environment(router)
        }
    }

    // MARK: Tests

    func testRootScreenDoesNotAllowSwipeBackOnceCoordinatorInstalled() throws {
        let router = Router()
        let nav = try host(router)

        // Visiting a header screen installs the coordinator for the stack's lifetime;
        // back on the root there is nothing to pop to, so it must refuse.
        push(.profile, on: router)
        pop(on: router)

        XCTAssertEqual(nav.viewControllers.count, 1)
        XCTAssertFalse(shouldBeginPop(nav))
    }

    func testScreenWithTopNavigationAllowsSwipeBack() throws {
        let router = Router()
        let nav = try host(router)

        push(.profile, on: router)

        XCTAssertEqual(nav.viewControllers.count, 2)
        let delegate = try XCTUnwrap(nav.interactivePopGestureRecognizer?.delegate)
        XCTAssertTrue(String(describing: type(of: delegate)).contains("SwipeBackCoordinator"),
                      "TopNavigation should install the swipe-back coordinator as the pop gesture delegate")
        XCTAssertTrue(shouldBeginPop(nav))
    }

    func testScreenWithoutTopNavigationBlocksSwipeBackEvenAfterCoordinatorInstalled() throws {
        let router = Router()
        let nav = try host(router)

        push(.profile, on: router)
        XCTAssertTrue(shouldBeginPop(nav))

        // A header-less screen pushed on top must not inherit the gesture.
        push(.login, on: router)
        XCTAssertEqual(nav.viewControllers.count, 3)
        XCTAssertFalse(shouldBeginPop(nav))

        // Back on the header screen, the gesture is available again.
        pop(on: router)
        XCTAssertEqual(nav.viewControllers.count, 2)
        XCTAssertTrue(shouldBeginPop(nav))
    }

    // MARK: Helpers

    private func host(_ router: Router) throws -> UINavigationController {
        // Attach to the host app's scene: a scene-less window never lays out, so
        // SwiftUI would never bridge the NavigationStack to UIKit.
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.rootViewController = UIHostingController(rootView: Harness(router: router))
        window.makeKeyAndVisible()
        self.window = window
        window.layoutIfNeeded()
        pump()
        let root = try XCTUnwrap(window.rootViewController)
        return try XCTUnwrap(navigationController(in: root.view),
                             "NavigationStack should be backed by a UINavigationController")
    }

    private func push(_ route: AppRoute, on router: Router) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { router.push(route) }
        pump()
    }

    private func pop(on router: Router) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { router.pop() }
        pump()
    }

    private func shouldBeginPop(_ nav: UINavigationController) -> Bool {
        guard let gesture = nav.interactivePopGestureRecognizer,
              let delegate = gesture.delegate else {
            return false
        }
        return delegate.gestureRecognizerShouldBegin?(gesture) ?? true
    }

    /// Lets SwiftUI lay out, attach representables and finish (disabled) transitions.
    private func pump(_ seconds: TimeInterval = 1.0) {
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    }

    /// SwiftUI does not expose the stack's navigation controller as a child view
    /// controller, so locate it through the responder chain of the hosted views.
    private func navigationController(in view: UIView) -> UINavigationController? {
        var responder: UIResponder? = view
        while let current = responder {
            if let nav = current as? UINavigationController {
                return nav
            }
            responder = current.next
        }
        for subview in view.subviews {
            if let nav = navigationController(in: subview) {
                return nav
            }
        }
        return nil
    }
}
