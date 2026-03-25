//
//  SprintStartUITests.swift
//  SprintStartUITests
//
//  Created by Zachary Kralec on 6/10/25.
//

import XCTest

final class SprintStartUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOnboardingContinueDismisses() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "-skipSplash", "-resetOnboarding"]
        app.launch()

        let continueButton = app.buttons["onboardingContinueButton"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2.0))
        continueButton.tap()

        XCTAssertFalse(continueButton.waitForExistence(timeout: 1.2))
        XCTAssertTrue(app.tabBars.buttons["Standard"].waitForExistence(timeout: 2.0))
    }

    @MainActor
    func testSettingsHidesTabBarAndRestoresOnBack() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "-skipSplash", "-markLaunched"]
        app.launch()

        let settingsButton = app.buttons["openSettingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 2.0))
        settingsButton.tap()

        XCTAssertTrue(app.scrollViews["settingsScreen"].waitForExistence(timeout: 2.0))
        XCTAssertFalse(app.tabBars.firstMatch.exists)

        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 1.0))
        backButton.tap()

        XCTAssertTrue(app.tabBars.buttons["Standard"].waitForExistence(timeout: 2.0))
    }

    @MainActor
    func testTimingLockDisablesResetDefaults() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "-skipSplash", "-markLaunched"]
        app.launch()

        let lockButton = app.buttons["timingLockButton"]
        XCTAssertTrue(lockButton.waitForExistence(timeout: 2.0))
        lockButton.tap()

        let resetDefaults = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Reset to Defaults")).firstMatch
        for _ in 0..<4 where !resetDefaults.exists {
            app.swipeUp()
        }
        XCTAssertTrue(resetDefaults.waitForExistence(timeout: 1.5))
        XCTAssertFalse(resetDefaults.isEnabled)
    }

    @MainActor
    func testAdvancedRandomnessPresentsProPaywall() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "-skipSplash", "-markLaunched"]
        app.launch()

        let mediumButton = app.buttons["Med"]
        XCTAssertTrue(mediumButton.waitForExistence(timeout: 2.0))
        mediumButton.tap()

        let upgradeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Unlock Sprint Start Pro")).firstMatch
        XCTAssertTrue(upgradeButton.waitForExistence(timeout: 2.0))
    }

    @MainActor
    func testProPaywallShowsUnlockAndRestoreButtons() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "-skipSplash", "-markLaunched"]
        app.launch()

        let mediumButton = app.buttons["Med"]
        XCTAssertTrue(mediumButton.waitForExistence(timeout: 2.0))
        mediumButton.tap()

        XCTAssertTrue(app.buttons["proUnlockButton"].waitForExistence(timeout: 2.0))
        XCTAssertTrue(app.buttons["proRestoreButton"].waitForExistence(timeout: 2.0))
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
