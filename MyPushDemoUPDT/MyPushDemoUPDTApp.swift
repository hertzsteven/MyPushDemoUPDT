//
//  CloudMessagingIosApp.swift
//  CloudMessagingIos
//
//  Created by Kentaro Mihara on 2023/08/16.
//

import Firebase
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import SwiftUI

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        print("🚀 App starting...")
        FirebaseApp.configure()

        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        // Check current authorization status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("📱 Current notification settings: \(settings.authorizationStatus.rawValue)")
            print("📱 Alert setting: \(settings.alertSetting.rawValue)")
            print("📱 Badge setting: \(settings.badgeSetting.rawValue)")
            print("📱 Sound setting: \(settings.soundSetting.rawValue)")
        }

        // Request notification permissions first
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            print("📱 Notification permission granted: \(granted)")
            if let error = error {
                print("❌ Notification permission error: \(error)")
            }
            
            DispatchQueue.main.async {
                // Register for remote notifications after getting permission
                print("📞 About to register for remote notifications...")
                application.registerForRemoteNotifications()
                print("📞 Called registerForRemoteNotifications()")
                
                // Check if the device supports remote notifications
                if application.isRegisteredForRemoteNotifications {
                    print("✅ Device is registered for remote notifications")
                } else {
                    print("❌ Device is NOT registered for remote notifications")
                }
            }
        }

        return true
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌❌❌ FAILED to register for remote notifications!")
        print("❌ Error code: \(error)")
        print("❌ Error description: \(error.localizedDescription)")
        
        // Check if it's a simulator
        #if targetEnvironment(simulator)
        print("🤖 Running on simulator - push notifications won't work")
        #else
        print("📱 Running on real device")
        #endif
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅✅✅ SUCCESS! Registered for remote notifications!")
        
        var readableToken = ""
        for index in 0 ..< deviceToken.count {
            readableToken += String(format: "%02.2hhx", deviceToken[index] as CVarArg)
        }
        print("🔑 APNs device token: \(readableToken)")
        
        // Give the token to Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
        print("🔥 Set APNs token to Firebase Messaging")
        
        // Now get the FCM token
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("🔥 FCM registration token: \(token)")
            }
        }
    }
}

extension AppDelegate: MessagingDelegate {
    @objc func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔥 Firebase token updated: \(String(describing: fcmToken))")
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        NotificationCenter.default.post(
            name: Notification.Name("didReceiveRemoteNotification"),
            object: nil,
            userInfo: userInfo
        )
        completionHandler()
    }
}

@main
struct CloudMessagingIosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}