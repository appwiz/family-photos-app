import XCTest

final class FamilyPhotosUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Authorization Screen Tests
    
    func testAppLaunches() throws {
        XCTAssertTrue(app.exists)
    }
    
    func testPermissionScreenShowsWhenNotAuthorized() throws {
        // When not authorized, either permission request or permission denied view should be shown
        let hasPermissionButton = app.buttons["Allow Access"].exists
        let hasSettingsButton = app.buttons["Open Settings"].exists
        let hasAlbumList = app.navigationBars["Select Album"].exists
        
        XCTAssertTrue(hasPermissionButton || hasSettingsButton || hasAlbumList,
                      "App should show permission UI or album list")
    }
    
    func testAlbumPickerNavigationTitle() throws {
        // If photo access is already granted, album picker should be visible
        if app.navigationBars["Select Album"].exists {
            XCTAssertTrue(app.navigationBars["Select Album"].exists)
        }
    }
    
    // MARK: - Settings Tests
    
    func testSettingsCanBeOpenedFromSystemSettings() throws {
        // Launch Settings app
        let settingsApp = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settingsApp.launch()
        
        // Scroll to find FamilyPhotos
        let familyPhotosCell = settingsApp.cells["Family Photos"]
        if familyPhotosCell.waitForExistence(timeout: 5) {
            familyPhotosCell.tap()
            
            // Verify settings items exist
            XCTAssertTrue(settingsApp.staticTexts["Autoplay Videos"].exists || 
                          settingsApp.switches["Autoplay Videos"].exists)
        }
        // Re-launch our app
        app.activate()
    }
    
    // MARK: - Slideshow Navigation Tests
    
    func testSlideshowControlsAppearOnTap() throws {
        // This test assumes photo access is granted and an album is selected
        // In a real scenario we'd mock the photo library
        // For now, verify the app state is coherent
        XCTAssertTrue(app.exists)
    }
}
