//
//  ProfileViewController.swift
//  Proximity
//
//  Created by Kevin Zhou on 11/5/17.
//  Copyright © 2017 Kevin Zhou. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import FirebaseAuth
import CoreLocation
import GooglePlaces
import GoogleMaps
import GooglePlacePicker
class ProfileViewController:UIViewController,CLLocationManagerDelegate,GMSMapViewDelegate,GMSPlacePickerViewControllerDelegate,UITableViewDataSource,UITableViewDelegate{
    @IBOutlet weak var addFriendButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var logoutButton: UIButton!
    var inMapView:Bool!
    var regularProfileViewOrigin:CGPoint!
    var regularMapViewHeight:CGFloat!
    
    let locationManager = CLLocationManager()
    
    var regionProfileObserver:UInt = 0
    
    @IBOutlet var nearbyPlacesButton: UIButton!
    
    @IBOutlet var mapView: GMSMapView!
    var profile:Profile!
    var profiles:NSMutableArray = NSMutableArray()
    var markers:NSMutableArray = NSMutableArray()
    var chatTitle:UIButton!
    var tableView:UITableView!
    
    var placesClient: GMSPlacesClient!
    
    override func viewDidLoad() {
        inMapView = false
        
        tableView = UITableView(frame: CGRect(x: usernameLabel.frame.origin.x, y: usernameLabel.frame.origin.y+usernameLabel.frame.size.height, width: self.view.frame.size.width-(usernameLabel.frame.origin.x*2), height: profileView.frame.size.height*5/6))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        profileView.addSubview(tableView)

        
        regularProfileViewOrigin = profileView.frame.origin
        regularMapViewHeight = mapView.frame.size.height
        
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        mapView.animate(toLocation: CLLocationCoordinate2DMake((locationManager.location?.coordinate.latitude)!, (locationManager.location?.coordinate.longitude)!))
        mapView.animate(toZoom: 15)
        mapView.delegate = self
        mapView.isUserInteractionEnabled = true
        placesClient = GMSPlacesClient.shared()
        for var _profile in profiles{
            fetchLocations(user: _profile as! String)
        }
        updateMarkers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if profile != nil{
            if profile.username == FirebaseHelper.personal.username{
                logoutButton.alpha = 1
                addFriendButton.alpha = 0
            }else if !FirebaseHelper.personal.friendRequests.contains(profile){
                logoutButton.alpha = 0
                addFriendButton.alpha = 1
            }else{
                logoutButton.alpha = 0
                addFriendButton.alpha = 0
            }
            usernameLabel.text = profile.username
            tableView.reloadData()
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)

    }
    
    func setProfiles(profile:Profile,profiles:NSMutableArray) {
        self.profile = profile
        self.profiles = profiles
    }
    
    @IBAction func logoutTapped(_ sender: Any) {
        do{
            try Auth.auth().signOut()
            self.navigationController?.popToRootViewController(animated: true)
        }catch{}
    }
    @IBAction func addFriendTapped(_ sender: Any) {
        let button = UIButton()
        button.tag = -1
        if FirebaseHelper.personal.friendRequests.contains(profile){
            acceptRequest(sender: button)
        }else{
            sendRequest(sender: button)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first?.location(in: self.view)
        if (point?.y)! > mapView.frame.size.height{
            UIView.animate(withDuration: 0.5, animations: {
                self.profileView.frame.origin = self.regularProfileViewOrigin
                self.mapView.frame.size.height = self.regularMapViewHeight
                self.nearbyPlacesButton.frame.origin.y = self.mapView.frame.size.height-self.nearbyPlacesButton.frame.size.height
                self.mapView.animate(toLocation: CLLocationCoordinate2DMake((self.locationManager.location?.coordinate.latitude)!, (self.locationManager.location?.coordinate.longitude)!))
                self.mapView.animate(toZoom: 15)
            })
        }
    }
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    func fetchLocations(user:String) {
        FirebaseHelper.ref.child("users").child(user).observe(.childChanged) { (snapshot) in
            if let dictionary = snapshot.value as? [String:AnyObject]{
                let profile = Profile(username: dictionary["username"] as! String, userId: snapshot.value as! String, friends: dictionary["friends"] as! NSMutableArray, icon: dictionary["icon"] as! String, chats: dictionary["chats"] as! NSMutableArray, latitude: dictionary["latitude"] as! Double, longitude: dictionary["longitude"] as! Double)
                for var _profile in self.profiles{
                    if (_profile as! Profile).userId == profile.userId{
                        self.profiles.remove(_profile)
                    }
                }
                self.profiles.add(profile)
                self.updateMarkers()
            }
        }
    }
    
    
    
    func fetchFriendRequests(){
        var members = NSArray()
        FirebaseHelper.ref.child("users").child(FirebaseHelper.personal.userId).child("friendRequests").observe(.childAdded) { (snapshot) in
            var contains = false
            FirebaseHelper.ref.child("users").child(snapshot.value as! String).observe(.value, with: { (snapshot2) in
                if let dictionary = snapshot2.value as? [String:AnyObject]{
                    var friends = NSMutableArray()
                    var chats = NSMutableArray()
                    if dictionary.keys.contains("friends"){friends = dictionary["friends"] as! NSMutableArray}
                    if dictionary.keys.contains("chats"){chats = dictionary["chats"] as! NSMutableArray}
                    let profile = Profile(username: dictionary["username"] as! String, userId: snapshot.value as! String, friends: friends, icon: dictionary["icon"] as! String, chats: chats, latitude: dictionary["latitude"] as! Double, longitude: dictionary["longitude"] as! Double)
                    FirebaseHelper.personal.friendRequests.add(profile)
                }
            })
        }
    }
    
    func fetchRegionMembers() {
        regionProfileObserver =  FirebaseHelper.ref.child("locations").child("\(FirebaseHelper.personalRegion.x)").child("\(FirebaseHelper.personalRegion.y)").observe(.value) { (snapshot) in
            if let profiles = snapshot.value as? NSArray{
                    FirebaseHelper.nearbyProfiles.removeAllObjects()
                    FirebaseHelper.nearbyProfiles.addObjects(from: profiles as! [Any])
            }
        }

    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        for var _profile in profiles{
            FirebaseHelper.ref.child("users").child(_profile as! String).observe(.value, with: { (prof) in
                if let dictionary = prof.value as? [String:AnyObject]{
                    if dictionary["username"] as! String == marker.title!{
                        let newProf = Profile(username: dictionary["username"] as! String, userId: _profile as! String, friends: dictionary["friends"] as! NSArray, icon: dictionary["icon"] as! String, chats: dictionary["chats"] as! NSArray, latitude: dictionary["latitude"] as! Double, longitude: dictionary["longitude"] as! Double)
                        self.profile = newProf
                        if self.profile.username == FirebaseHelper.personal.username{
                            self.logoutButton.alpha = 1
                            self.addFriendButton.alpha = 0
                        }else{
                            self.logoutButton.alpha = 0
                            for var selfFriends in FirebaseHelper.personal.friends{
                                if (selfFriends as! Profile).userId == _profile as! String{
                                    self.addFriendButton.alpha = 1
                                }
                            }
                        }
                        self.usernameLabel.text = self.profile.username
                        self.tableView.reloadData()
                    }
                }
            })
        }
        return true
    }
    
    func updateMarkers() {
        mapView.clear()

        makeMarker(array: profiles)
        makeMarker(array: FirebaseHelper.nearbyProfiles)
        
        let marker = GMSMarker(position: CLLocationCoordinate2DMake(profile.latitude, profile.longitude))
        marker.title = profile.username
        let image = self.imageWithImage(image: UIImage(data: Data(base64Encoded: profile.icon, options: .ignoreUnknownCharacters)!)!, scaledToSize: CGSize(width: 30, height: 30))
        let markerView = UIImageView(image: image)
        markerView.layer.cornerRadius = 15
        markerView.layer.masksToBounds = true
        markerView.frame.size = CGSize(width: 30, height: 30)
        marker.iconView = markerView
        
        marker.map = self.mapView
    }
    
    func makeMarker(array:NSArray){
        for var _profile in array{
            FirebaseHelper.ref.child("users").child(_profile as! String).observe(.value, with: { (profile) in
                if let dictionary = profile.value as? [String:AnyObject]{
                    
                    let marker = GMSMarker(position: CLLocationCoordinate2DMake(dictionary["latitude"] as! Double, dictionary["longitude"] as! Double))
                    marker.title = dictionary["username"] as! String
                    let image = self.imageWithImage(image: UIImage(data: Data(base64Encoded: dictionary["icon"] as! String, options: .ignoreUnknownCharacters)!)!, scaledToSize: CGSize(width: 30, height: 30))
                    let markerView = UIImageView(image: image)
                    markerView.layer.cornerRadius = 15
                    markerView.layer.masksToBounds = true
                    markerView.frame.size = CGSize(width: 30, height: 30)
                    marker.iconView = markerView
                    
                    marker.map = self.mapView
                }
            })
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        UIView.animate(withDuration: 0.5, animations: {
            self.profileView.frame.origin = CGPoint(x: 0, y: self.view.frame.size.height-self.usernameLabel.frame.origin.y-self.usernameLabel.frame.size.height)
            self.mapView.frame.size = CGSize(width: self.view.frame.size.width, height: self.profileView.frame.origin.y)
            self.nearbyPlacesButton.frame.origin.y = self.mapView.frame.size.height-self.nearbyPlacesButton.frame.size.height
        })
    }
    
    
    @IBAction func findPlacesTapped(_ sender: Any) {
        let config = GMSPlacePickerConfig(viewport: nil)
        let placePicker = GMSPlacePickerViewController(config: config)
        placePicker.delegate = self
        present(placePicker, animated: true, completion: nil)
    }

    func placePickerDidCancel(_ viewController: GMSPlacePickerViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace) {
        viewController.dismiss(animated: true, completion: nil)
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlaceViewerViewController") as! PlaceViewerViewController
        vc.setPlace(place: place)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return profile.chats.count
        }else if section == 1{
            return profile.friends.count
        }else{
            return FirebaseHelper.personal.friendRequests.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        
        if indexPath.section == 0{
            let chatArray = NSMutableArray()
            for var chat in FirebaseHelper.personal.chats{
                chatArray.add((chat as! Chat).id)
            }
            if !chatArray.contains((profile.chats.object(at: indexPath.row) as! String)){
                let joinChatButton = UIButton(frame: CGRect(x: tableView.frame.size.width-70, y: 0, width: 70, height: 60))
                joinChatButton.setTitle("Add", for: .normal)
                joinChatButton.setTitleColor(.black, for: .normal)
                joinChatButton.tag = indexPath.row
                joinChatButton.addTarget(self, action: #selector(joinChat(sender:)), for: .touchUpInside)
                cell.contentView.addSubview(joinChatButton)
            }
            FirebaseHelper.ref.child("chats").child(profile.chats.object(at: indexPath.row) as! String).child("chatName").observe(.value, with: { (name) in
                cell.textLabel?.text = name.value as! String
            })
        }else if indexPath.section == 1{
            let friendArray = NSMutableArray()
            for var friend in FirebaseHelper.personal.friends{
                friendArray.add((friend as! Profile).userId)
            }
            var addFriendButton = UIButton()
            if FirebaseHelper.personal.userId == profile.userId && !friendArray.contains((profile.friends.object(at: indexPath.row) as! String)){
                addFriendButton = UIButton(frame: CGRect(x: tableView.frame.size.width-70, y: 0, width: 70, height: 60))
                addFriendButton.setTitle("Add", for: .normal)
                addFriendButton.setTitleColor(.black, for: .normal)
                addFriendButton.tag = indexPath.row
                for var i in 0..<FirebaseHelper.personal.friendRequests.count{
                    addFriendButton.addTarget(self, action: #selector(sendRequest(sender:)), for: .touchUpInside)
                    if profile.friends.object(at: indexPath.row) as! String == (FirebaseHelper.personal.friendRequests.object(at: i) as! Profile).userId{
                        addFriendButton.tag = i
                        addFriendButton.removeTarget(self, action: #selector(sendRequest(sender:)), for: .touchUpInside)
                        addFriendButton.addTarget(self, action: #selector(acceptRequest(sender:)), for: .touchUpInside)
                    }
                }
                
                cell.contentView.addSubview(addFriendButton)
            }
            FirebaseHelper.ref.child("users").child(profile.friends.object(at: indexPath.row) as! String).observe(.value, with: { (profile) in
                if let dictionary = profile.value as? [String:AnyObject]{
                    cell.textLabel?.text = "                    "+(dictionary["username"] as! String)
                    let imageData = NSData(base64Encoded: dictionary["icon"] as! String , options: .ignoreUnknownCharacters)
                    let imageView = UIImageView(image: UIImage(data: imageData! as Data))
                    imageView.frame = CGRect(x: 5, y: 5, width: 50, height: 50)
                    imageView.layer.cornerRadius = imageView.frame.size.width/2
                    imageView.layer.masksToBounds = true
                    cell.contentView.addSubview(imageView)
                    
                    if dictionary.keys.contains("friendRequests") && (dictionary["friendRequests"] as! NSArray).contains(FirebaseHelper.personal.userId){
                        addFriendButton.removeFromSuperview()
                    }
                }
            })
        }else{
            let profile = FirebaseHelper.personal.friendRequests.object(at: indexPath.row) as! Profile
            let addFriendButton = UIButton(frame: CGRect(x: tableView.frame.size.width-70, y: 0, width: 70, height: 60))
            addFriendButton.setTitle("Add", for: .normal)
            addFriendButton.setTitleColor(.black, for: .normal)
            addFriendButton.tag = indexPath.row
            addFriendButton.addTarget(self, action: #selector(acceptRequest(sender:)), for: .touchUpInside)
            cell.contentView.addSubview(addFriendButton)
            
            cell.textLabel?.text = "                    "+(profile.username)
            let imageData = NSData(base64Encoded: profile.icon , options: .ignoreUnknownCharacters)
            let imageView = UIImageView(image: UIImage(data: imageData! as Data))
            imageView.frame = CGRect(x: 5, y: 5, width: 50, height: 50)
            imageView.layer.cornerRadius = imageView.frame.size.width/2
            imageView.layer.masksToBounds = true
            cell.contentView.addSubview(imageView)

        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel(frame: CGRect(x: 5, y: 5, width: 60, height: 60))
        if section == 0{
            label.text = "Chats"
        }else if section == 1{
            label.text = "Friends"
        }else{
            label.text = "Friend Requests"
        }
        label.backgroundColor = .white
        return label
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if profile.userId == FirebaseHelper.personal.userId{
            return 3
        }else{
            return 2
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 1 && FirebaseHelper.personal.userId == profile.userId{
            return true
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            FirebaseHelper.personal.friends.removeObject(at: indexPath.row)
            FirebaseHelper.ref.child("users").child(FirebaseHelper.personal.userId).child("friends").child("\(indexPath.row)").removeValue()
            FirebaseHelper.ref.child("users").child(FirebaseHelper.personal.userId).child("friends").observe(.value, with: { (friends) in
                if let array = friends.value as? NSArray{
                    FirebaseHelper.ref.child("users").child(FirebaseHelper.personal.userId).child("friends").child("\(array.index(of: FirebaseHelper.personal.userId))").removeValue()
                }
            })
        }
    }
    
    func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        image.draw(in: CGRect(x:0, y:0, width:newSize.width, height:newSize.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    @objc func joinChat(sender:UIButton){
        FirebaseHelper.ref.child("chats").child("\(profile.chats.object(at: sender.tag))").observe(.value) { (snapshot) in
            if let chat = snapshot.value as? [AnyHashable:Any]{
                if chat["joinType"] as! Int == 0{
                    FirebaseHelper.ref.child("chats").child("\(self.profile.chats.object(at: sender.tag))").child("members").updateChildValues(["\((chat["members"] as! NSArray).count)":FirebaseHelper.personal.userId])
                    var posts = NSMutableArray()
                    if chat["posts"] != nil{
                        posts = chat["posts"] as! NSMutableArray
                    }
                    let addChat = Chat(id: chat["id"] as! String, chatName: chat["chatName"] as! String, joinType: chat["joinType"] as! Int, members: chat["members"] as! NSMutableArray, posts: posts)
                    FirebaseHelper.personal.chats.add(addChat)
                    sender.setTitle("Joined", for: .normal)
                }else{
                    sender.setTitle("Closed", for: .normal)
                }
            }
        }
    }
    
    @objc func sendRequest(sender:UIButton){
        var _profile:Profile
        if sender.tag == -1{
            _profile = profile.friends.object(at: sender.tag) as! Profile
            sender.removeFromSuperview()
        }else{
            _profile = self.profile
        }
        FirebaseHelper.ref.child("users").child(_profile.userId).observe(.value) { (snapshot) in
            if let dict = snapshot.value as? [String:AnyHashable]{
                var value = [AnyHashable:Any]()
                if dict.keys.contains("friendRequests"){
                    value = [(dict["friendRequests"] as! NSArray).count:FirebaseHelper.personal.userId]
                }else{
                    value = [0:FirebaseHelper.personal.userId]
                }
                FirebaseHelper.ref.child("users").child(_profile.userId).child("friendRequests").updateChildValues(value)
            }
        }
        
    }
    
    @objc func acceptRequest(sender:UIButton){
        var finished = false
        var _profile:Profile
        if sender.tag == -1{
            _profile = FirebaseHelper.personal.friendRequests.object(at: sender.tag) as! Profile
            sender.removeFromSuperview()
        }else{
            _profile = self.profile
        }
        FirebaseHelper.personal.friendRequests.remove(_profile)
        FirebaseHelper.personal.friends.add(_profile)
        FirebaseHelper.ref.child("users").child(FirebaseHelper.personal.userId).child("friendRequests").child("\(sender.tag)").removeValue()
        FirebaseHelper.updatePersonal()
        FirebaseHelper.ref.child("users").child((_profile as! Profile).userId).child("friends").observe(.value, with: { (snapshot) in
            var friends = NSMutableArray()
            if let array = snapshot.value as? NSArray{
                friends = array as! NSMutableArray
            }
            var values = NSMutableDictionary()
            friends.add(FirebaseHelper.personal.userId)
            if !finished{
                for var i in 0..<friends.count{
                    values.addEntries(from: ["\(i)":friends.object(at: i)])
                }
            }else{
                return
            }
            FirebaseHelper.ref.child("users").child((_profile as! Profile).userId).child("friends").updateChildValues(values as! [AnyHashable : Any])
            finished = true
            self.tableView.reloadData()
        })
    }
    
    func findSelfRegion(){
        let absLatitude = abs(FirebaseHelper.personal.latitude)
        let adjLatitude = FirebaseHelper.personal.latitude + 90
        let adjLongitude = FirebaseHelper.personal.longitude+180
        
        let roundedLatitude = round(adjLatitude/0.5)*0.5
        let latitudeRegion = roundedLatitude/0.5
        
        let lengthOfLatEquator = 69.172
        let distanceAroundLatLine = (cos(absLatitude*Double.pi/180)*lengthOfLatEquator)*180
        
        let amtLongRegions = round(distanceAroundLatLine/30)
        
        let longRegion = round(adjLongitude/(360/amtLongRegions))
        
        if Int(longRegion) != Int(FirebaseHelper.personalRegion.x) || Int(latitudeRegion) != Int(FirebaseHelper.personalRegion.y){
            if FirebaseHelper.personalRegion.x != -1{
                FirebaseHelper.ref.child("locations").child("\(FirebaseHelper.personalRegion.y)").child("\(FirebaseHelper.personalRegion.x)").observeSingleEvent(of:.value) { (snapshot) in
                    if let array = snapshot.value as? NSArray{
                        let index = array.index(of: FirebaseHelper.personal.userId)
                        FirebaseHelper.ref.child("locations").child("\(FirebaseHelper.personalRegion.y)").child("\(FirebaseHelper.personalRegion.x)").child("\(index)").removeValue()
                    }
                }
            }
            let stringLat = "\(Int(latitudeRegion))"
            let stringLong = "\(Int(longRegion))"
            FirebaseHelper.ref.child("locations").child(stringLat).child(stringLong).observeSingleEvent(of:.value) { (snapshot) in
                if let profiles = snapshot.value as? NSArray{
                    if !profiles.contains(FirebaseHelper.personal.userId){
                        FirebaseHelper.ref.child("locations").child(stringLat).child(stringLong).updateChildValues(["\(profiles.count)":FirebaseHelper.personal.userId])
                    }
                }else{
                   FirebaseHelper.ref.child("locations").child(stringLat).child(stringLong).updateChildValues(["0":FirebaseHelper.personal.userId])
                }
            }
            FirebaseHelper.personalRegion = CGPoint(x: longRegion, y: latitudeRegion)
        }
    }
    
}
