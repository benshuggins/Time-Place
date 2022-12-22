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
    
    var location: [Locations]?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
                let window = UIWindow(windowScene: windowScene)
                window.makeKeyAndVisible()
                let navVC = UINavigationController(rootViewController: MainMapVC())
                window.rootViewController = navVC
                self.window = window
        
        
//        let controller1 = navVC.viewControllers.first as! MainMapVC
//        controller1.managedObjectContext = managedObjectContext
//        
//        let controller2 = AddLocationVC()
//        controller2.managedObjectContext = managedObjectContext
        
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
    
    // How is this old identifier matching this new ideentifier HOW THE FUCK ARE YOU TRIGGERING REGIONS AND THEN GETTING THE CORRECT DATA FOR THIOSE REGIONS, TODAY I REALIZED ONE DATA MODEL WILL WORK!!!!!
    func note(from identifier: String) -> String? {
       
        do {
            let request = Locations.fetchRequest() as NSFetchRequest<Locations>
            let pred = NSPredicate(format: "identifier == %@", identifier)
            request.predicate = pred
            location = try managedObjectContext.fetch(request)
            print("Is this the name? : \(location?.first?.title)")
        } catch {
            print("Error: \(error)")
                
        }
        
        return location?.first?.title
        
    }
    
    func handleEvent(for region: CLRegion) {
        // If app is opoen show an alert... Do I need this ?
        if UIApplication.shared.applicationState == .active {
            guard let alertMessage = note(from: region.identifier) else { return }
            window?.rootViewController?.showAlert(withTitle: nil, message: alertMessage)
        } else {
            // Otherwise present a local notification
            guard let body = note(from: region.identifier) else { return }
            let notificationContent = UNMutableNotificationContent()
            notificationContent.body = body
            notificationContent.sound = .default
            notificationContent.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
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
extension SceneDelegate {
  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    if region is CLCircularRegion {
      handleEvent(for: region)
    }
  }

  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    if region is CLCircularRegion {
      handleEvent(for: region)
    }
  }


}


///WHEN AN EVENT HAPPENS WE NEED TO FIND THE NAME OF THE LOCATION THAT WAS TRIGGERED AND START A TIMER IF THEY JUST ENTERED

