//
//  ContentView.swift
//  MyPushDemoUPDT
//
//  Created by Steven Hertz on 7/23/25.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
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
        }
        .padding()
    }
    
    private func sendLocalRichNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Rich Notification"
        content.body = "This should show an image!"
        content.userInfo = ["image": "https://picsum.photos/200/200.jpg"]
        
        // This triggers the Notification Service Extension
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "test", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
}