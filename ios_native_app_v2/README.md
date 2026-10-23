# Yashswi iOS Native App (v2)

This folder contains the **pure native Swift** equivalent of the Android application (`android_app`). 

Because we are working in a Windows environment, we cannot compile an `.ipa` file directly. However, these files are 100% complete and ready to be compiled in Xcode by any iOS Developer.

## How to Build the App

1. Open **Xcode** on a Mac.
2. Go to **File -> New -> Project...**
3. Select **iOS -> App** and click Next.
4. Name the project `YashswiNative`.
5. For Interface, select **Storyboard** (or **UIKit App Delegate** life cycle). Language should be **Swift**.
6. Delete the default `ViewController.swift` that Xcode creates.
7. Drag and drop all the `.swift` files from this folder into the Xcode project:
   - `Models.swift`
   - `ApiService.swift`
   - `SplashViewController.swift`
   - `LoginViewController.swift`
   - `DashboardViewController.swift`
8. In Xcode, open the `SceneDelegate.swift` file (if using iOS 13+). Change the `scene(_:willConnectTo:options:)` method to load the `SplashViewController` first:

```swift
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = SplashViewController()
    window.makeKeyAndVisible()
    self.window = window
}
```

9. Press **Cmd + R** to run the app in the iOS Simulator or on a connected iPhone.

## Architecture & Features

This codebase mirrors the Kotlin Native Android app exactly:

- **No Storyboards needed**: The UI for Login and Dashboard is built 100% programmatically using AutoLayout (`NSLayoutConstraint`). This ensures you won't get any XML/Storyboard merge conflicts.
- **ApiService**: Uses native `URLSession` to communicate with `https://yashswi.in/api/`.
- **Codable Models**: Fully maps the PHP backend JSON structures (Login, Attendance, FSR, Products) safely into Swift types.
- **Dynamic Role-Based Dashboard**: Just like Android, the UI dynamically changes its menu options based on if the user is an `admin`, `sc`, `engineer`, or `sales`.
