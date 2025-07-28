//
//  ContentView.swift
//  MyPushDemoUPDT
//
//  Created by Steven Hertz on 7/23/25.
//

//import SwiftUI
//import UserNotifications
//// Add this to your ContentView.swift for testing FCM programmatically

import SwiftUI
import FirebaseMessaging

struct ContentView: View {
    @State private var fcmToken: String = ""
    @State private var apnsToken: String = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            
            Button("Test Local Rich Notification") {
                sendLocalRichNotification()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Button("Force Check APNs Registration") {
                forceCheckAPNsRegistration()
            }
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            if !apnsToken.isEmpty {
                Text("APNs Token:")
                    .font(.headline)
                Text(apnsToken)
                    .font(.caption)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .textSelection(.enabled)
            }
            
            Button("Get FCM Token") {
                getFCMToken()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            if !fcmToken.isEmpty {
                Text("FCM Token:")
                    .font(.headline)
                Text(fcmToken)
                    .font(.caption)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .textSelection(.enabled)
            }
            
            Button("Send Test FCM with Image") {
                sendTestFCM()
            }
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(fcmToken.isEmpty)
            
            Button("Test Notification with Buttons") {
                sendNotificationWithButtons()
            }
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(10)

            Button("Debug App Icons") {
                debugAppIcons()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

        }
        .padding()
        .onAppear {
            getFCMToken()
        }
    }
    
    private func sendNotificationWithButtons() {
        let content = UNMutableNotificationContent()
        content.title = "Meeting Invitation"
        content.body = "You're invited to join the team meeting at 3 PM"
        content.userInfo = [
            "image": "https://picsum.photos/300/200.jpg",
            "meeting_id": "12345",
            "type": "invite"
        ]
        
        content.categoryIdentifier = "INVITE_CATEGORY"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: "test-buttons", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error: \(error)")
            } else {
                print("Test notification with buttons scheduled!")
            }
        }
    }
    
    private func sendLocalRichNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Rich Notification"
        content.body = "This should show an image!"
        content.userInfo = ["image": "https://picsum.photos/300/200.jpg"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "test", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error: \(error)")
            }
        }
    }
    
    private func forceCheckAPNsRegistration() {
        print("Checking APNs registration status...")
        
        UIApplication.shared.registerForRemoteNotifications()
        
        if let apnsToken = Messaging.messaging().apnsToken {
            let hexString = apnsToken.map { String(format: "%02.2hhx", $0) }.joined()
            print("Found APNs token in Firebase: \(hexString)")
            DispatchQueue.main.async {
                self.apnsToken = hexString
            }
        } else {
            print("No APNs token found in Firebase Messaging")
        }
    }
    
    private func getFCMToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM registration token: \(token)")
                DispatchQueue.main.async {
                    self.fcmToken = token
                }
                UIPasteboard.general.string = token
            }
        }
    }
    
    private func sendTestFCM() {
        guard !fcmToken.isEmpty else { return }
        
        let payload = """
        {
          "message": {
            "token": "\(fcmToken)",
            "notification": {
              "title": "Test Image Notification",
              "body": "This should show a beautiful image!"
            },
            "data": {
              "image": "https://picsum.photos/400/300.jpg"
            },
            "apns": {
              "payload": {
                "aps": {
                  "mutable-content": 1,
                  "alert": {
                    "title": "Test Image Notification",
                    "body": "This should show a beautiful image!"
                  }
                }
              }
            }
          }
        }
        """
        
        print("Use this payload to test FCM:")
        print(payload)
        
        let curlCommand = """
        curl -X POST https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send \\
        -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \\
        -H "Content-Type: application/json" \\
        -d '\(payload)'
        """
        
        print("Curl command (replace YOUR_PROJECT_ID and YOUR_ACCESS_TOKEN):")
        print(curlCommand)
    }
    
    private func debugAppIcons() {
        print("DEBUGGING APP ICONS")
        
        if let bundlePath = Bundle.main.path(forResource: "AppIcon60x60", ofType: "png") {
            print("Found AppIcon60x60.png at: \(bundlePath)")
        } else {
            print("AppIcon60x60.png not found in bundle")
        }
        
        let iconSizes = ["20", "29", "40", "58", "60", "80", "87", "120", "180"]
        for size in iconSizes {
            if let image = UIImage(named: "AppIcon\(size)x\(size)") {
                print("Found AppIcon\(size)x\(size): \(image.size)")
            } else {
                print("AppIcon\(size)x\(size) not found")
            }
        }
        
        if let infoDictionary = Bundle.main.infoDictionary {
            print("Bundle identifier: \(infoDictionary["CFBundleIdentifier"] ?? "unknown")")
            print("Bundle name: \(infoDictionary["CFBundleName"] ?? "unknown")")
            if let iconFiles = infoDictionary["CFBundleIcons"] as? [String: Any] {
                print("Icon files in Info.plist: \(iconFiles)")
            }
        }
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("Notification authorization: \(settings.authorizationStatus.rawValue)")
                print("Alert setting: \(settings.alertSetting.rawValue)")
            }
        }
    }

}

#Preview {
    ContentView()
}