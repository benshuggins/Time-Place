//
//  Functions.swift
//  GymTracker
//
//  Created by Ben Huggins on 12/9/22.
//

import Foundation
import NotificationCenter


// Returns file locations of Core Data DataBase
let applicationsDocumentsDirectory: URL = {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
   return paths[0]
}()

let CoreDataSaveFailedNotification = Notification.Name(rawValue: "CoreDataSaveFailedNotification")

func fatalCoreDataError(_ error: Error) {
    print("Fatal Error: ", error)
    NotificationCenter.default.post(name: CoreDataSaveFailedNotification, object: nil)
}
