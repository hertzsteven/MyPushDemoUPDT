import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        print("🔔 NotificationService: didReceive called")
        
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            print("🔔 NotificationService: Processing notification")
            print("🔔 UserInfo: \(bestAttemptContent.userInfo)")
            
            // Handle image attachment
            if let imageURLString = bestAttemptContent.userInfo["image"] as? String,
               let imageURL = URL(string: imageURLString) {
                print("🔔 Found image URL: \(imageURLString)")
                downloadImage(from: imageURL) { [weak self] attachment in
                    if let attachment = attachment {
                        print("🔔 Image downloaded successfully")
                        bestAttemptContent.attachments = [attachment]
                    } else {
                        print("🔔 Failed to download image")
                    }
                    contentHandler(bestAttemptContent)
                }
            } else if let fcmImageURLString = bestAttemptContent.userInfo["fcm_options"] as? [String: Any],
                      let imageURLString = fcmImageURLString["image"] as? String,
                      let imageURL = URL(string: imageURLString) {
                print("🔔 Found FCM image URL: \(imageURLString)")
                downloadImage(from: imageURL) { [weak self] attachment in
                    if let attachment = attachment {
                        print("🔔 FCM Image downloaded successfully")
                        bestAttemptContent.attachments = [attachment]
                    } else {
                        print("🔔 Failed to download FCM image")
                    }
                    contentHandler(bestAttemptContent)
                }
            } else {
                print("🔔 No image found in notification")
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        print("🔔 NotificationService: serviceExtensionTimeWillExpire")
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    private func downloadImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        print("🔔 Starting image download from: \(url)")
        let task = URLSession.shared.downloadTask(with: url) { (downloadedURL, response, error) in
            guard let downloadedURL = downloadedURL else {
                print("🔔 Download failed: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            var urlPath = URL(fileURLWithPath: NSTemporaryDirectory())
            let uniqueURLEnding = ProcessInfo.processInfo.globallyUniqueString + ".jpg"
            urlPath = urlPath.appendingPathComponent(uniqueURLEnding)
            
            try? FileManager.default.moveItem(at: downloadedURL, to: urlPath)
            
            do {
                let attachment = try UNNotificationAttachment(identifier: "image", url: urlPath, options: nil)
                print("🔔 Created attachment successfully")
                completion(attachment)
            } catch {
                print("🔔 Failed to create attachment: \(error)")
                completion(nil)
            }
        }
        task.resume()
    }
}