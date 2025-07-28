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
        
        // Set up notification categories with interactive actions
        setupNotificationCategories()

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
    private func setupNotificationCategories() {
        // Define individual actions (buttons)
        let acceptAction = UNNotificationAction(
            identifier: "ACCEPT_ACTION",
            title: "Accept",
            options: [.foreground] // Opens the app when tapped
        )
        
        let declineAction = UNNotificationAction(
            identifier: "DECLINE_ACTION",
            title: "Decline",
            options: [] // Doesn't open the app
        )
        
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View Details",
            options: [.foreground]
        )
        
        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            options: [.foreground],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type your reply..."
        )

        // NEW: Add donation action buttons
        let donate25Action = UNNotificationAction(
            identifier: "DONATE_25",
            title: "Donate $25",
            options: [.foreground]
        )

        let donate50Action = UNNotificationAction(
            identifier: "DONATE_50",
            title: "Donate $50",
            options: [.foreground]
        )
        
        let learnMoreAction = UNNotificationAction(
            identifier: "LEARN_MORE",
            title: "Learn More",
            options: [.foreground]
        )

        // Create categories (groups of actions)
        let inviteCategory = UNNotificationCategory(
            identifier: "INVITE_CATEGORY",
            actions: [acceptAction, declineAction],
            intentIdentifiers: [],
            options: []
        )
        
        let messageCategory = UNNotificationCategory(
            identifier: "MESSAGE_CATEGORY",
            actions: [replyAction, viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        let alertCategory = UNNotificationCategory(
            identifier: "ALERT_CATEGORY",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )

        // NEW: Create donation category
        let donationCategory = UNNotificationCategory(
            identifier: "DONATION_CATEGORY",
            actions: [donate25Action, donate50Action, learnMoreAction],
            intentIdentifiers: [],
            options: []
        )

        // Register all categories (including the new donation category)
        let categories: Set<UNNotificationCategory> = [
            inviteCategory,
            messageCategory,
            alertCategory,
            donationCategory  // Add this line
        ]
        
        UNUserNotificationCenter.current().setNotificationCategories(categories)
        print("📱 Notification categories registered successfully")
    }
//    private func setupNotificationCategories() {
//        // Define individual actions (buttons)
//        let acceptAction = UNNotificationAction(
//            identifier: "ACCEPT_ACTION",
//            title: "Accept",
//            options: [.foreground] // Opens the app when tapped
//        )
//        
//        let declineAction = UNNotificationAction(
//            identifier: "DECLINE_ACTION",
//            title: "Decline",
//            options: [] // Doesn't open the app
//        )
//        
//        let viewAction = UNNotificationAction(
//            identifier: "VIEW_ACTION",
//            title: "View Details",
//            options: [.foreground]
//        )
//        
//        let replyAction = UNTextInputNotificationAction(
//            identifier: "REPLY_ACTION",
//            title: "Reply",
//            options: [.foreground],
//            textInputButtonTitle: "Send",
//            textInputPlaceholder: "Type your reply..."
//        )
//
//        // Create categories (groups of actions)
//        let inviteCategory = UNNotificationCategory(
//            identifier: "INVITE_CATEGORY",
//            actions: [acceptAction, declineAction],
//            intentIdentifiers: [],
//            options: []
//        )
//        
//        let messageCategory = UNNotificationCategory(
//            identifier: "MESSAGE_CATEGORY",
//            actions: [replyAction, viewAction],
//            intentIdentifiers: [],
//            options: []
//        )
//        
//        let alertCategory = UNNotificationCategory(
//            identifier: "ALERT_CATEGORY",
//            actions: [viewAction],
//            intentIdentifiers: [],
//            options: []
//        )
//
//        // Register all categories
//        let categories: Set<UNNotificationCategory> = [
//            inviteCategory,
//            messageCategory,
//            alertCategory
//        ]
//        
//        UNUserNotificationCenter.current().setNotificationCategories(categories)
//        print("📱 Notification categories registered successfully")
//    }

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

// Update your UNUserNotificationCenterDelegate extension in AppDelegate.swift

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([[.banner, .list, .sound]])
    }

    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        print("🔔 Notification action tapped: \(actionIdentifier)")
        
        // Handle different button actions
        switch actionIdentifier {
        case "ACCEPT_ACTION":
            print("✅ User accepted the invite")
            handleAcceptAction(userInfo: userInfo)
            
        case "DECLINE_ACTION":
            print("❌ User declined the invite")
            handleDeclineAction(userInfo: userInfo)
            
        case "VIEW_ACTION":
            print("👀 User wants to view details")
            handleViewAction(userInfo: userInfo)
            
        case "REPLY_ACTION":
            if let textResponse = response as? UNTextInputNotificationResponse {
                print("💬 User replied: \(textResponse.userText)")
                handleReplyAction(userInfo: userInfo, replyText: textResponse.userText)
            }
            // Add these cases to your existing switch statement in userNotificationCenter didReceive response
            
        case "DONATE_25":
            print("💰 User wants to donate $25")
            handleDonateAction(userInfo: userInfo, amount: 25)
            
        case "DONATE_50":
            print("💰 User wants to donate $50")
            handleDonateAction(userInfo: userInfo, amount: 50)
            
        case "LEARN_MORE":
            print("📖 User wants to learn more")
            handleLearnMoreAction(userInfo: userInfo)
            
        case UNNotificationDefaultActionIdentifier:
            print("📱 User tapped the notification (not a button)")
            handleDefaultAction(userInfo: userInfo)
            
        default:
            print("🤷‍♂️ Unknown action: \(actionIdentifier)")
        }
        
        // Post notification for app to handle
        NotificationCenter.default.post(
            name: Notification.Name("didReceiveRemoteNotification"),
            object: nil,
            userInfo: userInfo
        )
        
        completionHandler()
    }
    
    // Handle specific actions
    private func handleAcceptAction(userInfo: [AnyHashable: Any]) {
        // Do something when user accepts
        // Maybe call an API, update UI, etc.
        print("Processing accept action...")
    }
    
    private func handleDeclineAction(userInfo: [AnyHashable: Any]) {
        // Do something when user declines
        print("Processing decline action...")
    }
    
    private func handleViewAction(userInfo: [AnyHashable: Any]) {
        // Navigate to specific screen
        print("Opening details view...")
    }
    
    private func handleReplyAction(userInfo: [AnyHashable: Any], replyText: String) {
        // Send the reply somewhere
        print("Sending reply: \(replyText)")
    }
    
    private func handleDefaultAction(userInfo: [AnyHashable: Any]) {
        // Handle normal notification tap
        print("Opening app from notification tap...")
    }
    // Add these functions after your existing handler functions in the AppDelegate extension

    private func handleDonateAction(userInfo: [AnyHashable: Any], amount: Int) {
        print("Processing donation of $\(amount)...")
        
        // Extract campaign info from the notification
        if let campaignId = userInfo["campaign_id"] as? String {
            print("Campaign ID: \(campaignId)")
        }
        
        if let donationUrl = userInfo["donation_url"] as? String {
            print("Donation URL: \(donationUrl)")
            // Here you could open the donation URL or trigger in-app donation flow
        }
        
        // Post notification for the app to handle
        NotificationCenter.default.post(
            name: Notification.Name("donateButtonTapped"),
            object: nil,
            userInfo: [
                "amount": amount,
                "originalNotification": userInfo
            ]
        )
        
        // You could also trigger immediate donation flow here
        // For example: triggerDonationFlow(amount: amount, campaignId: campaignId)
    }

    private func handleLearnMoreAction(userInfo: [AnyHashable: Any]) {
        print("Processing learn more action...")
        
        // Post notification for the app to handle
        NotificationCenter.default.post(
            name: Notification.Name("learnMoreButtonTapped"),
            object: nil,
            userInfo: userInfo
        )
        
        // You could navigate to specific content here
    }
}

//extension AppDelegate: UNUserNotificationCenterDelegate {
//    func userNotificationCenter(
//        _: UNUserNotificationCenter,
//        willPresent _: UNNotification,
//        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
//    ) {
//        completionHandler([.banner, .list, .sound])
//    }
//
//    func userNotificationCenter(
//        _: UNUserNotificationCenter,
//        didReceive response: UNNotificationResponse,
//        withCompletionHandler completionHandler: @escaping () -> Void
//    ) {
//        let userInfo = response.notification.request.content.userInfo
//        
//        // Handle the interactive button actions
//        switch response.actionIdentifier {
//        case "ACCEPT_ACTION":
//            print("✅ Accept button tapped!")
//            // Handle accept action - maybe update some data or navigate somewhere
//            NotificationCenter.default.post(
//                name: Notification.Name("acceptButtonTapped"),
//                object: nil,
//                userInfo: userInfo
//            )
//            
//        case "DECLINE_ACTION":
//            print("❌ Decline button tapped!")
//            // Handle decline action
//            NotificationCenter.default.post(
//                name: Notification.Name("declineButtonTapped"),
//                object: nil,
//                userInfo: userInfo
//            )
//            
//        case "VIEW_ACTION":
//            print("👀 View Details button tapped!")
//            // Handle view action - maybe navigate to a specific screen
//            NotificationCenter.default.post(
//                name: Notification.Name("viewDetailsButtonTapped"),
//                object: nil,
//                userInfo: userInfo
//            )
//            
//        case "DELETE_ACTION":
//            print("🗑️ Delete button tapped!")
//            // Handle delete action
//            NotificationCenter.default.post(
//                name: Notification.Name("deleteButtonTapped"),
//                object: nil,
//                userInfo: userInfo
//            )
//            
//        default:
//            print("📱 Default notification tap")
//            // Handle regular notification tap
//            NotificationCenter.default.post(
//                name: Notification.Name("didReceiveRemoteNotification"),
//                object: nil,
//                userInfo: userInfo
//            )
//        }
//        
//        completionHandler()
//    }
//}

@main
struct CloudMessagingIosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
