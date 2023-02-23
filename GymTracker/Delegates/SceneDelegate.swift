//
//  SceneDelegate.swift
//  GymTracker
//
//  Created by Ben Huggins on 11/19/22.
//

import UIKit
import CoreData
import CoreLocation

let dateFormatterSections: DateFormatter = {
   let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
    }()

class SceneDelegate: UIResponder, UIWindowSceneDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    let locationManager = CLLocationManager()
    var enterT: Date!
    var regionEvents: [RegionEvent]?
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var seconds: Int = 0
    var timerIsRunning: Bool = false
  
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
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }

    // MARK: - Helper methods
    func listenForFatalCoreDataNotifications() { NotificationCenter.default.addObserver(forName: CoreDataSaveFailedNotification, object: nil, queue: OperationQueue.main) { _ in
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
        tabController.present(alert,animated: true, completion: nil)
      }
    }

    func format(date: Date) -> String {
        return dateFormatter.string(from: date)
    }
      }

// MARK: - Location Manager Delegate
extension SceneDelegate {
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        ///Get the name of the location by passing it the regions identifier that will match the location identiffer 
         guard let currentLocation = DataManager.shared.matchLocation(from: region.identifier) else {return}
     
        /// Here we have entered the region
        if state == CLRegionState.inside {
            enterT = Date()
            let enterTimeFormat = format(date: enterT)
            ///If the app is open (Looking at the map inside iPhone) then show an alert view informing users of entrance, exit, and total time inside region
            if UIApplication.shared.applicationState == .active {
                //            let nc = NotificationCenter.default
                //            nc.post(name: Notification.Name("UserLoggedIn"), object: nil)
              //  window?.rootViewController?.showAlert(withTitle: currentLocation.title, message: "Entering at: \(enterTimeFormat)")
            
            } else {
                let notificationContent = UNMutableNotificationContent()
                notificationContent.title = "Entering: \(currentLocation.title ?? "")"
                notificationContent.body = "At: \(enterTimeFormat)"
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
            ///Exit the region
        } else if state == CLRegionState.outside {
            let exitTime = Date()
            let exitTimeFormat = format(date: exitTime)
            let sectionDateS = Date()
            let sectionDate = dateFormatterSections.string(from: sectionDateS)
            var totalTimeString = ""
            var totalRegionSeconds: Double = 0
          
            if enterT != nil {
                let deltaT = exitTime.timeIntervalSince(enterT)
                totalRegionSeconds = Double(deltaT)
                // saving a different total time of type time interval may help
                totalTimeString = deltaT.stringTime
            } else {
                totalTimeString = "No Entrance Time"
            }
            
            /// Create Core data regionEvent object  and save
            let regionEvent = RegionEvent(context: context) // CD init
            regionEvent.enterRegionTime = enterT  //Core Data Enter
            regionEvent.exitRegionTime = exitTime // Core Data Exit
            regionEvent.totalRegionTime = totalTimeString //Core Data Total
            regionEvent.sectionDate = sectionDate // String for section Date
            regionEvent.totalRegionSeconds = totalRegionSeconds
            regionEvent.regionIdentifier = currentLocation.identifier
            currentLocation.addToRegionEvent(regionEvent) // Core Data add entire regionEvent object to CD
            try! context.save()
            
            if UIApplication.shared.applicationState == .active {
                //            let nc = NotificationCenter.default
                //            nc.post(name: Notification.Name("UserLoggedOut"), object: nil)
              //  window?.rootViewController?.showAlert(withTitle: currentLocation.title, message: "E: \(exitTimeFormat), T: \(totalTimeString)")
            } else {
                let notificationContent = UNMutableNotificationContent()
                notificationContent.title = "Leaving: \(currentLocation.title ?? "")"
                notificationContent.body = "Left: \(exitTimeFormat) Total: \(totalTimeString)"
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
        } else if state == CLRegionState.unknown {
            window?.rootViewController?.showAlert(withTitle: "There was an error entering region", message: "Region State is .unknown")
        }
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("This region has an error: \(String(describing: region?.identifier))")
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

