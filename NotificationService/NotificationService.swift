import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        print("🔔 NotificationService: didReceive called")
        print("🔔 Request identifier: \(request.identifier)")
        
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            print("🔔 NotificationService: Processing notification")
            print("🔔 Full UserInfo: \(bestAttemptContent.userInfo)")
            print("🔔 Notification title: \(bestAttemptContent.title)")
            print("🔔 Notification body: \(bestAttemptContent.body)")
            
            // Check for images in multiple possible locations
            var imageURLString: String?
            
            // Method 1: Direct image key in data
            if let directImage = bestAttemptContent.userInfo["image"] as? String {
                imageURLString = directImage
                print("🔔 Found image in direct 'image' key: \(directImage)")
            }
            // Method 2: FCM options format
            else if let fcmOptions = bestAttemptContent.userInfo["fcm_options"] as? [String: Any],
                    let fcmImage = fcmOptions["image"] as? String {
                imageURLString = fcmImage
                print("🔔 Found image in fcm_options: \(fcmImage)")
            }
            // Method 3: Check APS payload for custom data
            else if let aps = bestAttemptContent.userInfo["aps"] as? [String: Any],
                    let alert = aps["alert"] as? [String: Any],
                    let imageUrl = alert["image"] as? String {
                imageURLString = imageUrl
                print("🔔 Found image in aps.alert: \(imageUrl)")
            }
            // Method 4: Check for image in any custom data
            else {
                print("🔔 Checking all userInfo keys for image URLs...")
                for (key, value) in bestAttemptContent.userInfo {
                    print("🔔 Key: \(key), Value: \(value), Type: \(type(of: value))")
                    if let stringValue = value as? String,
                       (stringValue.hasPrefix("http://") || stringValue.hasPrefix("https://")) &&
                       (stringValue.contains(".jpg") || stringValue.contains(".jpeg") || stringValue.contains(".png") || stringValue.contains(".gif")) {
                        imageURLString = stringValue
                        print("🔔 Found potential image URL in key '\(key)': \(stringValue)")
                        break
                    }
                }
            }
            
            if let imageURLString = imageURLString, let imageURL = URL(string: imageURLString) {
                print("🔔 Attempting to download image from: \(imageURLString)")
                downloadImage(from: imageURL) { [weak self] attachment in
                    if let attachment = attachment {
                        print("🔔 Image downloaded successfully, adding attachment")
                        bestAttemptContent.attachments = [attachment]
                        
                        // Optionally modify the notification text to indicate image was added
                        bestAttemptContent.body = "\(bestAttemptContent.body) 📸"
                    } else {
                        print("🔔 Failed to download or attach image")
                    }
                    contentHandler(bestAttemptContent)
                }
            } else {
                print("🔔 No valid image URL found in notification payload")
                print("🔔 Available keys in userInfo: \(Array(bestAttemptContent.userInfo.keys))")
                contentHandler(bestAttemptContent)
            }
        } else {
            print("🔔 Failed to create mutable content")
            contentHandler(request.content)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        print("🔔 NotificationService: serviceExtensionTimeWillExpire - timeout reached")
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            print("🔔 Delivering notification without image due to timeout")
            contentHandler(bestAttemptContent)
        }
    }
    
    private func downloadImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        print("🔔 Starting image download from: \(url)")
        
        let task = URLSession.shared.downloadTask(with: url) { (downloadedURL, response, error) in
            if let error = error {
                print("🔔 Download failed with error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let downloadedURL = downloadedURL else {
                print("🔔 Download failed: no downloaded URL")
                completion(nil)
                return
            }
            
            print("🔔 Image downloaded to temporary location: \(downloadedURL)")
            
            // Create a unique filename in temp directory
            var urlPath = URL(fileURLWithPath: NSTemporaryDirectory())
            let uniqueURLEnding = ProcessInfo.processInfo.globallyUniqueString + ".jpg"
            urlPath = urlPath.appendingPathComponent(uniqueURLEnding)
            
            do {
                // Move the downloaded file to our temp location
                try FileManager.default.moveItem(at: downloadedURL, to: urlPath)
                print("🔔 Moved image to: \(urlPath)")
                
                // Create the notification attachment
                let attachment = try UNNotificationAttachment(identifier: "image", url: urlPath, options: nil)
                print("🔔 Successfully created notification attachment")
                completion(attachment)
            } catch {
                print("🔔 Failed to create attachment: \(error.localizedDescription)")
                completion(nil)
            }
        }
        
        task.resume()
    }
}

//import UserNotifications
//
//class NotificationService: UNNotificationServiceExtension {
//
//    var contentHandler: ((UNNotificationContent) -> Void)?
//    var bestAttemptContent: UNMutableNotificationContent?
//
//    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
//        print("🔔 NotificationService: didReceive called")
//        
//        self.contentHandler = contentHandler
//        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
//        
//        if let bestAttemptContent = bestAttemptContent {
//            print("🔔 NotificationService: Processing notification")
//            print("🔔 UserInfo: \(bestAttemptContent.userInfo)")
//            
//            // Handle image attachment
//            if let imageURLString = bestAttemptContent.userInfo["image"] as? String,
//               let imageURL = URL(string: imageURLString) {
//                print("🔔 Found image URL: \(imageURLString)")
//                downloadImage(from: imageURL) { [weak self] attachment in
//                    if let attachment = attachment {
//                        print("🔔 Image downloaded successfully")
//                        bestAttemptContent.attachments = [attachment]
//                    } else {
//                        print("🔔 Failed to download image")
//                    }
//                    contentHandler(bestAttemptContent)
//                }
//            } else if let fcmImageURLString = bestAttemptContent.userInfo["fcm_options"] as? [String: Any],
//                      let imageURLString = fcmImageURLString["image"] as? String,
//                      let imageURL = URL(string: imageURLString) {
//                print("🔔 Found FCM image URL: \(imageURLString)")
//                downloadImage(from: imageURL) { [weak self] attachment in
//                    if let attachment = attachment {
//                        print("🔔 FCM Image downloaded successfully")
//                        bestAttemptContent.attachments = [attachment]
//                    } else {
//                        print("🔔 Failed to download FCM image")
//                    }
//                    contentHandler(bestAttemptContent)
//                }
//            } else {
//                print("🔔 No image found in notification")
//                contentHandler(bestAttemptContent)
//            }
//        }
//    }
//    
//    override func serviceExtensionTimeWillExpire() {
//        print("🔔 NotificationService: serviceExtensionTimeWillExpire")
//        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
//            contentHandler(bestAttemptContent)
//        }
//    }
//    
//    private func downloadImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
//        print("🔔 Starting image download from: \(url)")
//        let task = URLSession.shared.downloadTask(with: url) { (downloadedURL, response, error) in
//            guard let downloadedURL = downloadedURL else {
//                print("🔔 Download failed: \(error?.localizedDescription ?? "Unknown error")")
//                completion(nil)
//                return
//            }
//            
//            var urlPath = URL(fileURLWithPath: NSTemporaryDirectory())
//            let uniqueURLEnding = ProcessInfo.processInfo.globallyUniqueString + ".jpg"
//            urlPath = urlPath.appendingPathComponent(uniqueURLEnding)
//            
//            try? FileManager.default.moveItem(at: downloadedURL, to: urlPath)
//            
//            do {
//                let attachment = try UNNotificationAttachment(identifier: "image", url: urlPath, options: nil)
//                print("🔔 Created attachment successfully")
//                completion(attachment)
//            } catch {
//                print("🔔 Failed to create attachment: \(error)")
//                completion(nil)
//            }
//        }
//        task.resume()
//    }
//}
