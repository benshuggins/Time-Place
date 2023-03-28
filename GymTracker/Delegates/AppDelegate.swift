//
//  AppDelegate.swift
//  GymTracker
//
//  Created by Ben Huggins on 11/19/22.
//

import UIKit
import CoreData
import CoreLocation
import UserNotifications

 @main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var orientationLock = UIInterfaceOrientationMask.all

    // MARK: - LOCK SCREEN ORIENTATION
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }
    
    struct AppUtility {
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.orientationLock = orientation
            }
        }
            
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
            self.lockOrientation(orientation)
            UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("Here is documents directory: ", applicationsDocumentsDirectory)
        ///THIS METHOD REQUESTS AUTHORIZATION TO USE PUSH NOTIFICATIONS
        let options: UNAuthorizationOptions = [.badge, .sound, .alert]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { _, error in
          if let error = error {
              ///NEED TO HANDLE THE ERROR!!!
            print("Error: \(error)")
          }
        }
        return true
    }
    
    ///PERFORMS HOUSEKEEPING CLEARING OLDER NOTIFICATIONS 
    func applicationDidBecomeActive(_ application: UIApplication) {
      application.applicationIconBadgeNumber = 0
      UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
      UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

    // MARK: - Core Data stack
    lazy var managedObjectContext: NSManagedObjectContext = self.persistentContainer.viewContext
    lazy var persistentContainer: NSPersistentContainer = {
     
      let container = NSPersistentContainer(name: "DataModel")
      container.loadPersistentStores(completionHandler: { (storeDescription, error) in
        if let error = error as NSError? {
          fatalError("Unresolved error \(error), \(error.userInfo)")
        }
      })
      return container
    }()
    
    // MARK: - Core Data Saving support
    func save () {
      let context = persistentContainer.viewContext
      if context.hasChanges {
        do {
          try context.save()
        } catch {
			assert(false, "There was a Core Data Save error")
			///precondition(true, "There was a Core Data Save Error")
			let alertController = UIAlertController(title: "Core Data Save Error!", message: "Please Contact the Developer", preferredStyle: .actionSheet)
			let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { UIAlertAction in
					NSLog("OK Pressed")
				}
			alertController.addAction(okAction)
			self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
			abort() /// full app kill
        }
      }
    }
  }
