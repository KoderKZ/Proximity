//
//  ProfileViewController.swift
//  Proximity
//

import Foundation
import UIKit
import MapKit
import FirebaseAuth
import CoreLocation
import GooglePlaces
import GoogleMaps
import GooglePlacePicker
class ProfileViewController:UIViewController,CLLocationManagerDelegate,GMSMapViewDelegate,GMSPlacePickerViewControllerDelegate,UITableViewDataSource,UITableViewDelegate,SelectionViewDelegate{
    @IBOutlet weak var addFriendButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var topView: UIView!
    var inMapView:Bool!
    var regularProfileViewOrigin:CGPoint!
    var regularMapViewHeight:CGFloat = 0.0
    var homeMenu:Bool = false
    var selectionView:SelectionView!
    
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
        //set up ui/preliminary info
        inMapView = false
        
        topView.backgroundColor = darkBgColor
        
        nearbyPlacesButton.backgroundColor = darkBgColor
        nearbyPlacesButton.setTitleColor(.white, for: .normal)
        
        tableView = UITableView(frame: CGRect(x: usernameLabel.frame.origin.x, y: topView.frame.origin.y+topView.frame.size.height+10, width: self.view.frame.size.width-(usernameLabel.frame.origin.x*2), height: profileView.frame.size.height*5/6))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        profileView.addSubview(tableView)
        
        tableView.allowsSelection = false
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        addFriendButton.tag = -1
        
        if profile.latitude != 0 && profile.longitude != 0{
            mapView.animate(toLocation: CLLocationCoordinate2DMake(profile.latitude, profile.longitude))
            mapView.animate(toZoom: 15)
        }
        mapView.delegate = self
        mapView.isUserInteractionEnabled = true
        placesClient = GMSPlacesClient.shared()
        for var _profile in profiles{
            if let string = _profile as? String{
                fetchLocations(user: string)
            }else if let prof = _profile as? Profile{
                fetchLocations(user: prof.userId)
            }
        }
        updateMarkers()
        
        if homeMenu{//set up selection view if from menu
            backButton.alpha = 0
            let height:CGFloat = 75
            let width = self.view.frame.size.width-30
            selectionView = SelectionView(frame: CGRect(x: 15, y: self.view.frame.size.height-15-height, width: width, height: height))
            selectionView.delegate = self
            selectionView.setTab(tab: 4)
            self.view.addSubview(selectionView)
            tableView.frame.size.height -= selectionView.frame.size.height+selectionView.margin*2
        }
    }
    
    override func viewDidLayoutSubviews() {
        if regularMapViewHeight == 0{//store locations for transitions
            regularProfileViewOrigin = profileView.frame.origin
            regularMapViewHeight = mapView.frame.size.height
        }
    }
    
    func selectionTapped(tag: Int) {//move to new vc based on which tab tapped
        let selectionVC = self.navigationController?.viewControllers[1] as! SelectionViewController
        
        if tag < 2{
            self.navigationController?.popViewController(animated: false)
            selectionVC.tab = tag
        }else if tag == 2{
            let addVC = self.storyboard?.instantiateViewController(withIdentifier: "AddViewController") as! AddViewController
            self.navigationController?.viewControllers = [(self.navigationController?.viewControllers[0])!, selectionVC, addVC]
        }else if tag == 3{
            let createVC = self.storyboard?.instantiateViewController(withIdentifier: "CreateChatViewController") as! CreateChatViewController
            self.navigationController?.viewControllers = [(self.navigationController?.viewControllers[0])!, selectionVC, createVC]
        }else if tag == 4{
            let chatArray = NSMutableArray()
            for var chat in FirebaseHelper.personal.chats{
                chatArray.add((chat as! Chat).id)
            }
            
            let friendArray = NSMutableArray()
            for var friend in FirebaseHelper.personal.friends{
                friendArray.add((friend as! Profile).userId)
            }
            let selfProfile = Profile(username: FirebaseHelper.personal.username, userId: FirebaseHelper.personal.userId, friends: friendArray, icon: FirebaseHelper.personal.icon, chats: chatArray, latitude: FirebaseHelper.personal.latitude, longitude: FirebaseHelper.personal.longitude)
            self.profile = selfProfile
                logoutButton.alpha = 1
                addFriendButton.alpha = 0
            usernameLabel.text = profile.username
            tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        findSelfRegion()
        
        fetchRegionMembers()
        fetchFriendRequests()
        
        //edit ui based on profile
        if profile != nil{
            let friendsArray = NSMutableArray()
            for var profile in FirebaseHelper.personal.friends{
                friendsArray.add((profile as! Profile).userId)
            }
            let friendRequestArray = NSMutableArray()
            for var profile in FirebaseHelper.personal.friendRequests{
                friendRequestArray.add((profile as! Profile).userId)
            }
            if profile.username == FirebaseHelper.personal.username{
                logoutButton.alpha = 1
                addFriendButton.alpha = 0
            }else if !friendsArray.contains(profile.userId) && !friendRequestArray.contains(profile.userId){
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
    
    func setProfiles(profile:Profile,profiles:NSMutableArray) {//set profiles used to display info
        self.profile = profile
        self.profiles = profiles

    }
    
    @IBAction func logoutTapped(_ sender: Any) {
        do{//will logout, bring to sign in vc
            try Auth.auth().signOut()
            
            if let vc = self.navigationController?.viewControllers[1] as? SignInViewController{
                self.navigationController?.popToViewController(vc, animated: true)
            }else{
                let vc2 = self.storyboard?.instantiateViewController(withIdentifier: "SignInViewController")
                let vc1 = self.storyboard?.instantiateViewController(withIdentifier: "StartingViewController")
                self.navigationController?.setViewControllers([vc1!,vc2!], animated: true)
            }
        }catch{}
    }
    @IBAction func addFriendTapped(_ sender: Any) {
        if FirebaseHelper.personal.friendRequests.contains(profile){
            acceptRequest(sender: sender as! UIButton)
        }else{
            sendRequest(sender: sender as! UIButton)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first?.location(in: self.view)//transition to profile viewing
        tableView.reloadData()
        if (point?.y)! > mapView.frame.size.height{
            UIView.animate(withDuration: 0.5, animations: {
                self.profileView.frame.origin = self.regularProfileViewOrigin
                self.mapView.frame.size.height = self.regularMapViewHeight
                self.nearbyPlacesButton.frame.origin.y = self.mapView.frame.size.height-self.nearbyPlacesButton.frame.size.height
                if self.profile.latitude != 0 && self.profile.longitude != 0{
                    self.mapView.animate(toLocation: CLLocationCoordinate2DMake(self.profile.latitude, self.profile.longitude))
                    self.mapView.animate(toZoom: 15)
                }
                if self.homeMenu{
                    self.selectionView.frame.origin.y = self.view.frame.size.height-90
                }
            })
        }
    }
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)//move to previous view controller
    }
    
    
    func fetchLocations(user:String) {
        FirebaseHelper.ref.child("users").child(user).observe(.childChanged) { (snapshot) in//get locations for friends, if changed can update
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
    
    
    
    func fetchFriendRequests(){//get friend requests, can show in own profile
        FirebaseHelper.ref.child("users").child(FirebaseHelper.personal.userId).child("friendRequests").observe(.childAdded) { (snapshot) in
            FirebaseHelper.ref.child("users").child(snapshot.value as! String).observeSingleEvent(of: .value, with: { (snapshot2) in
                if let dictionary = snapshot2.value as? [String:AnyObject]{
                    var friends = NSMutableArray()
                    var chats = NSMutableArray()
                    if dictionary.keys.contains("friends"){friends = dictionary["friends"] as! NSMutableArray}
                    if dictionary.keys.contains("chats"){chats = dictionary["chats"] as! NSMutableArray}
                    let profile = Profile(username: dictionary["username"] as! String, userId: snapshot.value as! String, friends: friends, icon: dictionary["icon"] as! String, chats: chats, latitude: dictionary["latitude"] as! Double, longitude: dictionary["longitude"] as! Double)
                    var contains = false
                    for var i in 0..<FirebaseHelper.personal.friendRequests.count{
                        if profile.userId == (FirebaseHelper.personal.friendRequests.object(at: i) as! Profile).userId{
                            contains = true
                        }
                    }
                    if !contains{
                        FirebaseHelper.personal.friendRequests.add(profile)
                    }
                    
                }
            })
        }
    }
    
    func fetchRegionMembers() {//get people within own region
        regionProfileObserver = FirebaseHelper.ref.child("locations").child("\(Int(FirebaseHelper.personalRegion.x))").child("\(Int(FirebaseHelper.personalRegion.y))").observe(.value) { (snapshot) in
            if let profiles = snapshot.value as? NSArray{
                    FirebaseHelper.nearbyProfiles.removeAllObjects()
                    FirebaseHelper.nearbyProfiles.addObjects(from: profiles as! [Any])
                FirebaseHelper.nearbyProfiles.remove(FirebaseHelper.personal.userId)
                self.updateMarkers()//update markers so can see nearby people
            }
        }

    }
    
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {//tap marker to view someone's profile
        let combinedArray = profiles as! NSMutableArray
        combinedArray.addObjects(from: FirebaseHelper.nearbyProfiles as! [Any])
        for var _profile in profiles{
            if marker.title! == FirebaseHelper.personal.username{
                _profile = FirebaseHelper.personal.userId
            }
            FirebaseHelper.ref.child("users").child(_profile as! String).observeSingleEvent(of: .value, with: { (prof) in
                if let dictionary = prof.value as? [String:AnyObject]{
                    if dictionary["username"] as! String == marker.title!{//check if is someone's profile
                        var chats = NSArray()//change profile view to reflect new profile
                        if let chatArr = dictionary["chats"] as? NSArray{
                            chats = chatArr
                        }
                        var friends = NSArray()
                        if let friendArr = dictionary["friends"] as? NSArray{
                            friends = friendArr
                        }
                        let newProf = Profile(username: dictionary["username"] as! String, userId: _profile as! String, friends: friends, icon: dictionary["icon"] as! String, chats: chats, latitude: dictionary["latitude"] as! Double, longitude: dictionary["longitude"] as! Double)
                        self.profile = newProf
                        if self.profile.username == FirebaseHelper.personal.username{
                            self.logoutButton.alpha = 1
                            self.addFriendButton.alpha = 0
                        }else{
                            self.logoutButton.alpha = 0
                            self.addFriendButton.alpha = 1
                            for var selfFriends in FirebaseHelper.personal.friends{
                                if (selfFriends as! Profile).userId == _profile as! String{
                                    self.addFriendButton.alpha = 0
                                }
                            }
                        }
                        self.usernameLabel.text = self.profile.username
                        if self.profileView.frame.origin.y < self.view.frame.size.height-self.topView.frame.size.height{
                        }else{
                        }
                        UIView.animate(withDuration: 0.2, animations: {
                            if self.homeMenu{
                                self.selectionView.frame.origin.y = self.view.frame.size.height-90
                            }
                            self.profileView.frame.origin.y = self.view.frame.size.height-self.topView.frame.size.height
                            self.tableView.reloadData()
                        })
                        

                    }
                }
            })
            if marker.title! == FirebaseHelper.personal.username{
                return true
            }
        }
        return true
    }
    
    func updateMarkers() {
        mapView.clear()//update marker positions

        makeMarker(array: profiles)
        makeMarker(array: FirebaseHelper.nearbyProfiles)
        
        if profile.latitude != 0 && profile.longitude != 0{
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
    }
    
    func makeMarker(array:NSArray){
        for var _profile in array{//make markers from array of uids
            FirebaseHelper.ref.child("users").child(_profile as! String).observeSingleEvent(of: .value, with: { (profile) in
                if let dictionary = profile.value as? [String:AnyObject]{
                    if dictionary["latitude"] as! Double != 0 && dictionary["longitude"] as! Double != 0{
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
                }
            })
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        UIView.animate(withDuration: 0.5, animations: {//turn into full map view
            self.profileView.frame.origin = CGPoint(x: 0, y: self.view.frame.size.height-self.topView.frame.size.height)
            self.mapView.frame.size = CGSize(width: self.view.frame.size.width, height: self.profileView.frame.origin.y)
            self.nearbyPlacesButton.frame.origin.y = self.mapView.frame.size.height-self.nearbyPlacesButton.frame.size.height
            if self.homeMenu{
                self.selectionView.frame.origin.y = self.view.frame.size.height
            }
        })

    }
    
    
    @IBAction func findPlacesTapped(_ sender: Any) {
        let config = GMSPlacePickerConfig(viewport: nil)//move to google place picker, can view different places
        let placePicker = GMSPlacePickerViewController(config: config)
        placePicker.delegate = self
        present(placePicker, animated: true, completion: nil)
    }

    func placePickerDidCancel(_ viewController: GMSPlacePickerViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace) {
        viewController.dismiss(animated: true, completion: nil)//move to place viewer, can view information and send to chats
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlaceViewerViewController") as! PlaceViewerViewController
        vc.setPlace(place: place)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{//will have chats, friends, friend requests
            return profile.chats.count
        }else if section == 1{
            return profile.friends.count
        }else{
            return FirebaseHelper.personal.friendRequests.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        //set up cells for chats, friends, friend requests
        //items not in own profile will have the option to be added through a button
        if indexPath.section == 0{
            let chatArray = NSMutableArray()
            for var chat in FirebaseHelper.personal.chats{
                chatArray.add((chat as! Chat).id)
            }

            FirebaseHelper.ref.child("chats").child(profile.chats.object(at: indexPath.row) as! String).child("chatName").observeSingleEvent(of: .value, with: { (name) in
                cell.textLabel?.text = name.value as! String
                if !chatArray.contains((self.profile.chats.object(at: indexPath.row) as! String)){
                    let joinChatButton = UIButton(frame: CGRect(x: tableView.frame.size.width-100, y: 0, width: 100, height: 60))
                    joinChatButton.setTitle("Add", for: .normal)
                    joinChatButton.setTitleColor(.black, for: .normal)
                    joinChatButton.tag = indexPath.row
                    joinChatButton.addTarget(self, action: #selector(self.joinChat(sender:)), for: .touchUpInside)
                    cell.contentView.addSubview(joinChatButton)
                }
            })
        }else if indexPath.section == 1{
            let friendArray = NSMutableArray()
            for var friend in FirebaseHelper.personal.friends{
                friendArray.add((friend as! Profile).userId)
            }
            var addFriendButton = UIButton()

            FirebaseHelper.ref.child("users").child(profile.friends.object(at: indexPath.row) as! String).observeSingleEvent(of: .value, with: { (profile) in
                if let dictionary = profile.value as? [String:AnyObject]{
                    cell.textLabel?.text = "                    "+(dictionary["username"] as! String)
                    let imageData = NSData(base64Encoded: dictionary["icon"] as! String , options: .ignoreUnknownCharacters)
                    let imageView = UIImageView(image: UIImage(data: imageData! as Data))
                    imageView.frame = CGRect(x: 5, y: 5, width: 50, height: 50)
                    imageView.layer.cornerRadius = imageView.frame.size.width/2
                    imageView.layer.masksToBounds = true
                    cell.contentView.addSubview(imageView)
                    
                    if FirebaseHelper.personal.userId != self.profile.userId && !friendArray.contains((self.profile.friends.object(at: indexPath.row) as! String)){
                        addFriendButton = UIButton(frame: CGRect(x: tableView.frame.size.width-100, y: 0, width: 100, height: 60))
                        addFriendButton.setTitle("Add", for: .normal)
                        addFriendButton.setTitleColor(.black, for: .normal)
                        addFriendButton.tag = indexPath.row
                        for var i in 0..<FirebaseHelper.personal.friendRequests.count{
                            addFriendButton.addTarget(self, action: #selector(self.sendRequest(sender:)), for: .touchUpInside)
                            if self.profile.friends.object(at: indexPath.row) as! String == (FirebaseHelper.personal.friendRequests.object(at: i) as! Profile).userId{
                                addFriendButton.tag = i
                                addFriendButton.removeTarget(self, action: #selector(self.sendRequest(sender:)), for: .touchUpInside)
                                addFriendButton.addTarget(self, action: #selector(self.acceptRequest(sender:)), for: .touchUpInside)
                            }
                        }
                        
                        cell.contentView.addSubview(addFriendButton)
                    }
                    
                    if dictionary.keys.contains("friendRequests") && (dictionary["friendRequests"] as! NSArray).contains(FirebaseHelper.personal.userId){
                        addFriendButton.setTitle("Requested", for: .normal)
                        addFriendButton.isEnabled = false
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1{
            
        }
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
    
    
    func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{//resize UIImage, conserve space used
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        image.draw(in: CGRect(x:0, y:0, width:newSize.width, height:newSize.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    @objc func joinChat(sender:UIButton){
        //join chat
        sender.setTitle("Waiting", for: .normal)
        FirebaseHelper.ref.child("chats").child("\(profile.chats.object(at: sender.tag))").observeSingleEvent(of: .value) { (snapshot) in
            if let chat = snapshot.value as? [AnyHashable:Any]{
                if chat["joinType"] as! Int == 0{//join if open
                    var members = NSMutableArray()
                    if let membersArr = chat["members"] as? NSMutableArray{
                        members = membersArr
                        for var j in membersArr{//add self to members
                            if profileIcons.object(forKey: j as! String) == nil{
                                FirebaseHelper.ref.child("users").child(j as! String).observeSingleEvent(of:.value, with: { (snapshot) in
                                    if let profile = snapshot.value as? [String:AnyObject] {
                                        profileIcons.addEntries(from: [(j as! String): profile["icon"]])
                                    }
                                })
                            }
                        }
                    }
                    FirebaseHelper.ref.child("chats").child("\(self.profile.chats.object(at: sender.tag))").child("members").updateChildValues(["\(members.count)":FirebaseHelper.personal.userId])
                    var posts = NSMutableArray()
                    let addChat = Chat(id: self.profile.chats.object(at: sender.tag) as! String, chatName: chat["chatName"] as! String, joinType: chat["joinType"] as! Int, members: members, posts: posts)
                    FirebaseHelper.personal.chats.add(addChat)
                    FirebaseHelper.updatePersonal()
                    sender.setTitle("Joined", for: .normal)
                    StoreViewed.sharedInstance.addObserver(chatId: addChat.id)
                }else{//denied access if chat is closed
                    sender.setTitle("Closed", for: .normal)
                }
                sender.isEnabled = false
            }
        }
    }
    
    @objc func sendRequest(sender:UIButton){
        //send friend request
        var _profile:String
        sender.isEnabled = false

        if sender.tag != -1{
            _profile = profile.friends.object(at: sender.tag) as! String
        }else{
            _profile = self.profile.userId
        }
        FirebaseHelper.ref.child("users").child(_profile).observeSingleEvent(of: .value) { (snapshot) in
            if let dict = snapshot.value as? [String:AnyHashable]{
                var value = [AnyHashable:Any]()
                if dict.keys.contains("friendRequests"){
                    let friendRequests = dict["friendRequests"] as! NSArray
                    if !friendRequests.contains(FirebaseHelper.personal.userId) {
                        value = [(dict["friendRequests"] as! NSArray).count:FirebaseHelper.personal.userId]
                    }
                }else{
                    value = ["0":FirebaseHelper.personal.userId]
                }
                FirebaseHelper.ref.child("users").child(_profile).child("friendRequests").updateChildValues(value)
                sender.setTitle("Requested", for: .normal)
            }
        }
        
    }
    
    @objc func acceptRequest(sender:UIButton){
        //accept friend request
        var finished = false
        var _profile:Profile
        if sender.tag != -1{
            _profile = FirebaseHelper.personal.friendRequests.object(at: sender.tag) as! Profile
        }else{
            _profile = self.profile
        }
        FirebaseHelper.personal.friendRequests.removeObject(at: sender.tag)
        FirebaseHelper.personal.friends.add(_profile)
        let tempArr:NSMutableArray = profile.friends as! NSMutableArray
        tempArr.add(_profile.userId)
        profile.friends = tempArr
        self.tableView.reloadData()
        FirebaseHelper.ref.child("users").child(FirebaseHelper.personal.userId).child("friendRequests").child("\(sender.tag)").removeValue()
        FirebaseHelper.updatePersonal()
        FirebaseHelper.ref.child("users").child((_profile).userId).child("friends").observeSingleEvent(of: .value, with: { (snapshot) in
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
            FirebaseHelper.ref.child("users").child(FirebaseHelper.personal.userId).child("friendRequests").observeSingleEvent(of: .value, with: { (snapshot) in
                if let array = snapshot.value as? NSArray{
                    snapshot.ref.child("\(array.index(of: (_profile as! Profile).userId))").removeValue()
                }
            })
        })
    }
    
    func findSelfRegion(){//find region in the world
        if FirebaseHelper.personal.latitude != 0 && FirebaseHelper.personal.longitude != 0{
            let absLatitude = abs(FirebaseHelper.personal.latitude)
            let adjLatitude = FirebaseHelper.personal.latitude + 90
            let adjLongitude = FirebaseHelper.personal.longitude+180
            
            let roundedLatitude = round(adjLatitude/0.5)*0.5
            let latitudeRegion = roundedLatitude/0.5
            
            let lengthOfLatEquator = 69.172
            let distanceAroundLatLine = (cos(absLatitude*Double.pi/180)*lengthOfLatEquator)*180
            
            let amtLongRegions = round(distanceAroundLatLine/30)
            
            let longRegion = round(adjLongitude/(360/amtLongRegions))
            if Int(latitudeRegion) != Int(FirebaseHelper.personalRegion.x) || Int(longRegion) != Int(FirebaseHelper.personalRegion.y){
                let savedPoint = FirebaseHelper.personalRegion//remove from Firebase if already in a region
                if FirebaseHelper.personalRegion.x != -500{
                    FirebaseHelper.ref.child("locations").child("\(Int(FirebaseHelper.personalRegion.x))").child("\(Int(FirebaseHelper.personalRegion.y))").observeSingleEvent(of:.value) { (snapshot) in
                        if let array = snapshot.value as? NSArray{
                            let index = array.index(of: FirebaseHelper.personal.userId)
                            FirebaseHelper.ref.child("locations").child("\(Int(savedPoint.x))").child("\(Int(savedPoint.y))").child("\(index)").removeValue()
                        }
                    }
                }
                let stringLat = "\(Int(latitudeRegion))"
                let stringLong = "\(Int(longRegion))"
                FirebaseHelper.ref.child("locations").child(stringLat).child(stringLong).observeSingleEvent(of:.value) { (snapshot) in
                    if let profiles = snapshot.value as? NSArray{//update in Firebase
                        if !profiles.contains(FirebaseHelper.personal.userId){
                            FirebaseHelper.ref.child("locations").child(stringLat).child(stringLong).updateChildValues(["\(profiles.count)":FirebaseHelper.personal.userId])
                        }
                    }else{
                        FirebaseHelper.ref.child("locations").child(stringLat).child(stringLong).updateChildValues(["0":FirebaseHelper.personal.userId])
                    }
                }
                FirebaseHelper.personalRegion = CGPoint(x: latitudeRegion, y: longRegion)//update local
                FirebaseHelper.ref.child("users").child(FirebaseHelper.personal.userId).updateChildValues(["latitudeRegion":Int(FirebaseHelper.personalRegion.x),"longitudeRegion":Int(FirebaseHelper.personalRegion.y)])

            }
        }
        
    }
    
}
