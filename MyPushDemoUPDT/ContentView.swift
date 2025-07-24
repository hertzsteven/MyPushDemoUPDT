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
        }
        .padding()
        .onAppear {
            getFCMToken()
        }
    }
    
    private func sendLocalRichNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Rich Notification"
        content.body = "This should show an image!"
        content.userInfo = ["image": "https://picsum.photos/300/200.jpg"]
        
        // This triggers the Notification Service Extension
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "test", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error: \(error)")
            }
        }
    }
    
    private func forceCheckAPNsRegistration() {
        print("🔍 Checking APNs registration status...")
        
        UIApplication.shared.registerForRemoteNotifications()
        
        // Check if we can get the APNs token from Firebase Messaging
        if let apnsToken = Messaging.messaging().apnsToken {
            let hexString = apnsToken.map { String(format: "%02.2hhx", $0) }.joined()
            print("📱 Found APNs token in Firebase: \(hexString)")
            DispatchQueue.main.async {
                self.apnsToken = hexString
            }
        } else {
            print("❌ No APNs token found in Firebase Messaging")
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
                // Copy to clipboard for easy testing
                UIPasteboard.general.string = token
            }
        }
    }
    
    private func sendTestFCM() {
        guard !fcmToken.isEmpty else { return }
        
        // This is just for demonstration - in a real app, you'd send this from your server
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
        
        // You can use this payload with curl or Postman to test:
        let curlCommand = """
        curl -X POST https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send \\
        -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \\
        -H "Content-Type: application/json" \\
        -d '\(payload)'
        """
        
        print("Curl command (replace YOUR_PROJECT_ID and YOUR_ACCESS_TOKEN):")
        print(curlCommand)
    }
}

#Preview {
    ContentView()
}