//
//  AppDelegate.swift
//  Proximity
//
//  Created by Kevin Zhou on 11/3/17.
//  Copyright © 2017 Kevin Zhou. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import GooglePlaces
import GoogleMaps
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,CLLocationManagerDelegate {
    
    var window: UIWindow?
    let locationManager = CLLocationManager()
    var navigationController:UINavigationController!
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?)
        -> Bool {
            FirebaseApp.configure()
            
            
            
            self.locationManager.requestAlwaysAuthorization()
            
            self.locationManager.requestWhenInUseAuthorization()
            
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.delegate = self
                self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                self.locationManager.startUpdatingLocation()
            }
            
            GMSPlacesClient.provideAPIKey("AIzaSyCTdmNzeRAKvhuQzjxmeo_kvsTpWvMjTrE")
            GMSServices.provideAPIKey("AIzaSyCTdmNzeRAKvhuQzjxmeo_kvsTpWvMjTrE")
            
            UIApplication.shared.statusBarStyle = .lightContent
            
            navigationController = application.windows[0].rootViewController as! UINavigationController
            return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if FirebaseHelper.personal != nil{
            let locValue:CLLocationCoordinate2D = manager.location!.coordinate

            
            if FirebaseHelper.personal.latitude == 0 || FirebaseHelper.personal.longitude == 0{
                FirebaseHelper.personal.latitude = locValue.latitude
                FirebaseHelper.personal.longitude = locValue.longitude
                FirebaseHelper.updatePersonal()
                return
            }
            
            if (FirebaseHelper.personal.latitude+0.005<locValue.latitude ||
            FirebaseHelper.personal.latitude-0.005>locValue.latitude) &&
            (FirebaseHelper.personal.longitude+0.005<locValue.longitude &&
            FirebaseHelper.personal.longitude-0.005>locValue.longitude){
                
                FirebaseHelper.personal.latitude = locValue.latitude
                FirebaseHelper.personal.longitude = locValue.longitude
                
                FirebaseHelper.updatePersonal()
                

                return
            }
        }
        if let profileVC = navigationController?.topViewController as? ProfileViewController{
            profileVC.findSelfRegion()
        }
        
    }

}

