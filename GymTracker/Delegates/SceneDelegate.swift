//
//  SceneDelegate.swift
//  GymTracker
//
//  Created by Ben Huggins on 11/19/22.
//

import UIKit
import CoreData
import CoreLocation

class SceneDelegate: UIResponder, UIWindowSceneDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    let locationManager = CLLocationManager()
   // var location: [Location]?
    var enterT: Date!
    var regionEvents: [RegionEvent]?
    
   // var regionEvent: RegionEvent?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
                let window = UIWindow(windowScene: windowScene)
                window.makeKeyAndVisible()
                let navVC = UINavigationController(rootViewController: MainMapVC())
                window.rootViewController = navVC
                self.window = window
        
        listenForFatalCoreDataNotifications()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        // Save changes in the application's managed object context when the application transitions to the background.
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
    func saveContext () {
    let context = persistentContainer.viewContext
      if context.hasChanges {
        do {
          try context.save()
        } catch {
          // Replace this implementation with code to handle the error appropriately.
          // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
          let nserror = error as NSError
          fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
      }
    }
    
    // MARK: - Helper methods
    func listenForFatalCoreDataNotifications() { NotificationCenter.default.addObserver(forName: CoreDataSaveFailedNotification, object: nil, queue: OperationQueue.main
      ) { _ in
        let message = """
        There was a fatal error in the app and it cannot continue.
        Press OK to terminate the app. Sorry for the inconvenience.
        """
        let alert = UIAlertController(title: "Internal Error", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { _ in
          let exception = NSException(name: NSExceptionName.internalInconsistencyException, reason: "Fatal Core Data error", userInfo: nil)
          exception.raise()
        }
        alert.addAction(action)
        let tabController = self.window!.rootViewController!
        tabController.present(
          alert,
          animated: true,
          completion: nil)
      }
    }

    func format(date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    // A regionEvent is only added when the app is closed right now
    
    // Solve the problem as if the app was open
    
    
    // should I hold the time in an instance variable and then save all at once once I get an exit time or should I

    
    // I have to go get the location object off of the phones harddrive
    
    func handleEvent(for region: CLRegion, travel: String) {
        if UIApplication.shared.applicationState == .active {
            
            guard let location = DataManager.shared.matchLocation(from: region.identifier) else {return}
            
            // add the location.identifier to the region
            
            let regionEvent = RegionEvent(context: managedObjectContext)
            if travel == "Entering" {
             
             enterT = Date()
              let enterTimeFormat = format(date: enterT)
             
                // Instantiate the object
                
                //1 can this function not save exitREGIONTIME AT ALL?
                
                // save the regions identifier to this model and then fetch it below
                
//                var regionEvent = DataManager.shared.regionEvent(enterRegionTime: enterT, exitRegionTime: nil, totalRegionTime: "", regionIdentifer: location.identifier, location: location)
                
               // regionEvents.append(regionEvent)
                DataManager.shared.save()
                window?.rootViewController?.showAlert(withTitle: location.title, message: "Entering at: \(enterTimeFormat)")
                
            } else if travel == "Exiting" {
                
               // get the location.regionEvent from the identifer
                
                let exitT = Date()
                let exitTimeFormat = format(date: exitT)
                let deltaT = exitT.timeIntervalSince(enterT ?? Date())
                
               // let updateRegionModel = DataManager.sh
                
                // updating all exitRegionTimes
                location.regionEvent?.setValue(exitT, forKey: "exitRegionTime")      // This is updating an existing model
                
                location.regionEvent?.setValue("\(deltaT.stringTime)", forKey: "totalRegionTime")
                
                DataManager.shared.save()
                window?.rootViewController?.showAlert(withTitle: location.title, message: "E: \(exitTimeFormat), T: \(deltaT.stringTime)")
                
            }
        } else {
            // get currect location object that matches
           // guard let thisLocation = matchLocation(from: region.identifier) else { return }
            guard let thisLocation = DataManager.shared.matchLocation(from: region.identifier) else {return}
            
            let notificationContent = UNMutableNotificationContent()
            let regionEvent = RegionEvent(context: managedObjectContext)
            if travel == "Entering" {
                enterT = Date()
                regionEvent.enterRegionTime = enterT
                notificationContent.title = "Entering: \(thisLocation.title ?? "")"
                let enterTimeFormatted = format(date: enterT)
                notificationContent.body = enterTimeFormatted
                // Add the enterTime
                thisLocation.addToRegionEvent(regionEvent)
                try! managedObjectContext.save()
            } else if travel == "Exiting" {
                // I am not fetching the entrance time aI am just saving it locally 
                
                // need to fetch the current time from the correct region that is triggered
                let regionExitTime = Date()
                regionEvent.exitRegionTime = regionExitTime
                let regionExitTimeFormatted = format(date: regionExitTime)
                let delta = regionExitTime.timeIntervalSince(enterT)
                notificationContent.title = "Leaving: \(thisLocation.title ?? "")"
                notificationContent.body = "Left: \(regionExitTimeFormatted) Total: \(delta.stringTime)"
                regionEvent.totalRegionTime = delta.stringTime
                try! managedObjectContext.save()
            }
            notificationContent.sound = .default
            notificationContent.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)             // trigger after 1 second
            let request = UNNotificationRequest(
              identifier: "location_change",
              content: notificationContent,
              trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
              if let error = error {
                print("Error: \(error)")
              }
            }
          }
        }
      }

// MARK: - Location Manager Delegate


// HOW DO I GET THE CORRECT NOTE AND THEN ADD AN ENTRY TIME TO IT?
extension SceneDelegate {
    
  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    if region is CLCircularRegion {
        // If handle func is called from here just give use the time we arrived, send time from here
        handleEvent(for: region, travel: "Entering")
        // deal with time
    }
  }

  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    if region is CLCircularRegion {
        // If handle event is called from here then subtract this time from the last time
        handleEvent(for: region, travel: "Exiting")
        
        // deal with time
    }
  }
}

extension TimeInterval {
    private var milliseconds: Int {
        return Int((truncatingRemainder(dividingBy: 1)) * 1000)
    }
    private var seconds: Int {
        return Int(self) % 60
    }
    private var minutes: Int {
        return (Int(self) / 60 ) % 60
    }
    private var hours: Int {
        return Int(self) / 3600
    }
    var stringTime: String {
        if hours != 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else if minutes != 0 {
            return "\(minutes)m \(seconds)s"
        } else if milliseconds != 0 {
            return "\(seconds)s \(milliseconds)ms"
        } else {
            return "\(seconds)s"
        }
    }
}
