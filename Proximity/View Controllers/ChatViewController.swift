//
//  ChatViewController.swift
//  Proximity
//
//  Created by Kevin Zhou on 11/5/17.
//  Copyright © 2017 Kevin Zhou. All rights reserved.
//

import Foundation
import UIKit
import GooglePlaces
import FirebaseStorage
class ChatViewController:UIViewController,UITableViewDelegate,UITableViewDataSource,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITextViewDelegate{
    
    @IBOutlet weak var sendingView: UIView!
    @IBOutlet weak var joinChatLabel: UILabel!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var menuBar: UIView!
    @IBOutlet weak var chatNameLabel: UILabel!
    @IBOutlet weak var chatView: UITableView!
    @IBOutlet var imageButton: UIButton!
    var chat:Chat!
    var selectionView:SelectionView!
    var displayImageView:DisplayImageView!
    let profileIcons = NSMutableDictionary()
    let members:NSMutableArray = NSMutableArray()
    var postAmount = 0
    var statusBarHidden:Bool = false{
        didSet{
            UIView.animate(withDuration: 0.5) {
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    struct section {
        var amt:Int!
        var date:String!
    }
    var sections = NSMutableArray()
    //MARK: View Loading
    override func viewDidLoad() {
        
        chatView.register(ChatMessageCell.self, forCellReuseIdentifier: "cell")
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        chatView.addGestureRecognizer(tap)
        chatView.backgroundColor = bgColor
        
        
        //set up side bar for selecting chats
        selectionView = SelectionView(frame: CGRect(x: -self.view.frame.size.width/2, y: 0, width: self.view.frame.size.width/2, height: self.view.frame.size.height))
        selectionView.setUpLabels(cellHeight: menuBar.frame.size.height)//pass in menu bar height
        selectionView.alpha = 0
        for var i in 0..<FirebaseHelper.personal.chats.count{
            let cell = selectionView.tableView.cellForRow(at: IndexPath(item: i, section: 0))
            (cell?.contentView.subviews[1] as! UIButton).addTarget(self, action: #selector(chatTapped(sender:)), for: .touchUpInside)//set tap chat gesture
        }
        for var i in 0..<FirebaseHelper.personal.friends.count{
            let cell = selectionView.tableView.cellForRow(at: IndexPath(item: i, section: 1))
            (cell?.contentView.subviews[0] as! UIButton).addTarget(self, action: #selector(moveToProfileViewController(sender:)), for: .touchUpInside)//set tap chat gesture
        }
        self.view.addSubview(selectionView)
        
        displayImageView = DisplayImageView(frame: self.view.frame)
        self.view.addSubview(displayImageView)
        
        menuBar.backgroundColor = darkBgColor
        menuButton.adjustsImageWhenHighlighted = false
        settingsButton.adjustsImageWhenHighlighted = false
        
        let border1 = CALayer()
        border1.frame = CGRect(x: 0, y: 0, width: 1, height: textView.frame.size.height)
        border1.backgroundColor = UIColor.white.cgColor
        let border2 = CALayer()
        border2.frame = CGRect(x: textView.frame.size.width+textView.frame.size.height, y: 0, width: 1, height: textView.frame.size.height)
        border2.backgroundColor = UIColor.white.cgColor
        textView.layer.addSublayer(border1)
        textView.layer.addSublayer(border2)
        
        textView.backgroundColor = darkBgColor
        textView.textColor = .white
        textView.delegate = self
        sendButton.backgroundColor = darkBgColor
        imageButton.backgroundColor = darkBgColor
        sendingView.backgroundColor = darkBgColor
        
        textView.layer.borderColor = UIColor.white.cgColor
        textView.layer.borderWidth = 2
        
        sendingView.frame.size.height = (textView.font?.lineHeight)!
        
        sendButton.frame.size.height = (textView.font?.lineHeight)!
        imageButton.frame.size = CGSize(width: (textView.font?.lineHeight)!, height: (textView.font?.lineHeight)!)
        
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        let profile = Profile(username: FirebaseHelper.personal.username, userId: FirebaseHelper.personal.userId, friends: FirebaseHelper.personal.friends, icon: FirebaseHelper.personal.icon, chats: FirebaseHelper.personal.chats, latitude: FirebaseHelper.personal.latitude, longitude: FirebaseHelper.personal.longitude)
        
        chatView.separatorColor = .clear
        chatView.allowsSelection = false
        
        if chat != nil{
            chatNameLabel.text = chat.chatName
            fetchMembers(chatId: chat.id)
            fetchPosts(chatId: chat.id)
        }
        if chat == nil && FirebaseHelper.personal.chats.count > 0{
            settingsButton.alpha = 1
            chatNameLabel.alpha = 1
            joinChatLabel.alpha = 0
            chat = FirebaseHelper.personal.chats[0] as! Chat
            chatNameLabel.text = chat.chatName
            fetchMembers(chatId: chat.id)
            fetchPosts(chatId: chat.id)
        }else if FirebaseHelper.personal.chats.count == 0{
            settingsButton.alpha = 0
            chatNameLabel.alpha = 0
            joinChatLabel.alpha = 1
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        selectionView.alpha = 1
        textView.frame.size.height = sendingView.frame.size.height

        selectionView.joinChatButton.addTarget(self, action: #selector(moveToAddViewController), for: .touchUpInside)
//        selectionView.addFriendButton.addTarget(self, action: #selector(moveToProfileViewController), for: .touchUpInside)
        selectionView.selfButton.addTarget(self, action: #selector(moveToSelfProfile), for: .touchUpInside)
//        selectionView.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    

    
    //MARK: Observers for data
    
    func fetchMembers(chatId:String){
        var members = NSArray()
        FirebaseHelper.ref.child("chats").child(chatId).child("members").observe(.childAdded) { (snapshot) in
            var contains = false
            for var i in self.chat.members{
                if (i as! String) == snapshot.value as! String{
                    contains = true
                }
            }
            if !contains{
                self.chat.members.add(snapshot.value)
            }
            FirebaseHelper.ref.child("users").child(snapshot.value as! String).observe(.value, with: { (snapshot2) in
                if let dictionary = snapshot2.value as? [String:AnyObject]{
                    var friends = NSMutableArray()
                    var chats = NSMutableArray()
                    if dictionary.keys.contains("friends"){friends = dictionary["friends"] as! NSMutableArray}
                    if dictionary.keys.contains("chats"){chats = dictionary["chats"] as! NSMutableArray}
                    let profile = Profile(username: dictionary["username"] as! String, userId: snapshot.value as! String, friends: friends, icon: dictionary["icon"] as! String, chats: chats, latitude: dictionary["latitude"] as! Double, longitude: dictionary["longitude"] as! Double)
                    self.members.add(profile)
                }
            })
        }
    }
    
    func fetchPosts(chatId:String) {
        FirebaseHelper.ref.child("chats").child(chatId).child("posts").observe(.childAdded) { (snapshot) in
            FirebaseHelper.ref.child("chats").child(chatId).child("posts").observe(.value, with: { (postsCount) in
                if let posts = postsCount.value as? NSDictionary{
                    self.postAmount = posts.allKeys.count
                }
//                if self.postAmount > self.chat.posts.count{
                    if let postValues = snapshot.value as? [String:AnyObject]{
                        var text = ""
                        var image = ""
                        var place:AnyObject!
                        var foundPlace = false
                        var foundImage = false
                        var increasedBool = false
                        var post:Post!
                        //                                                    var poll:Poll
                        if postValues.keys.contains("text"){text = postValues["text"] as! String}
                        if postValues.keys.contains("image"){
                            let index = self.chat.posts.count
                            foundImage = true
                            FirebaseHelper.storageRef.child("images/\(postValues["image"] as! String).jpeg").getData(maxSize: 50*(1024*1024), completion: { (data, err) in
                                if let error = err{
                                    print("couldn't download image")
                                    return
                                }
                                image = (data?.base64EncodedString())!
                                post = Post(chatId: self.chat.id, text: text, image: image, profileId: postValues["profileId"] as! String, timestamp: postValues["timestamp"] as! String, datestamp: postValues["datestamp"] as! String, place: place)
                                if !self.chat.posts.contains(post){
                                    self.chat.posts.remove(index)
                                    self.chat.posts.insert(post, at: index+1)
                                    self.chatView.reloadData()
                                }

                            })
                        }
                        
                        if postValues.keys.contains("place"){
                            foundPlace = true
                            let placeId = postValues["place"] as! String
                            let index = self.chat.posts.count
                            FirebaseHelper.placesClient.lookUpPlaceID(placeId, callback: { (placeSnap, err) in
                                place = placeSnap!
                                post = Post(chatId: self.chat.id, text: text , image: image, profileId: postValues["profileId"] as! String, timestamp: postValues["timestamp"] as! String, datestamp: postValues["datestamp"] as! String, place: place)
                                if !self.chat.posts.contains(post){
                                    self.chat.posts.insert(post, at: index)
                                    self.chatView.reloadData()
                                }
                            })
                            
                        }else{
                            place = "none" as AnyObject
                        }
                        //                                                    if postValues.keys.contains("poll"){}
                        if !foundPlace{
                            post = Post(chatId: self.chat.id, text: text , image: image, profileId: postValues["profileId"] as! String, timestamp: postValues["timestamp"] as! String, datestamp: postValues["datestamp"] as! String, place: place)
                            if !self.chat.posts.contains(post){
                                self.chat.posts.add(post)
                            }
                        }
                        
                        
                        for var i in self.sections{
                            if (i as! section).date == postValues["datestamp"] as! String{
                                let dateSection = section(amt: (i as! section).amt+1, date: postValues["datestamp"] as! String)
                                let index = self.sections.index(of: i)
                                self.sections.remove(i)
                                self.sections.insert(dateSection, at: index)
                                increasedBool = true
                            }
                        }
                        if !increasedBool{
                            let dateSection = section(amt: 1, date: postValues["datestamp"] as! String)
                            self.sections.add(dateSection)
                        }
                    }
                    if self.postAmount == self.chat.posts.count{
                        self.chatView.reloadData()
                    }
//                }
            })
            
        }
        
    }
    
    //MARK: Keyboard Updaters
    
    @objc func keyboardWillShow(notification:NSNotification){
        let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! CGRect
        let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double
        UIView.animate(withDuration: keyboardDuration, animations: {
            self.sendingView.frame.origin.y = keyboardFrame.origin.y-self.sendingView.frame.size.height
        })
    }
    
    @objc func keyboardWillHide(notification:NSNotification){
        let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double
        
        UIView.animate(withDuration: keyboardDuration) {
            self.sendingView.frame.origin.y = self.view.frame.size.height-self.sendingView.frame.size.height
        }
    }
    
    //MARK: Button Actions
    
    @objc func imageTapped(sender:UIButton){
        let post = self.chat.posts.object(at: sender.tag) as! Post
        let data = Data(base64Encoded: post.image, options: .ignoreUnknownCharacters)!
        let image = UIImage(data: data)!
        displayImageView.setImage(image: image)
        displayImageView.appear()
    }
    
    @IBAction func sendImageTapped(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated:true, completion: nil)
        
        let image = info[UIImagePickerControllerEditedImage] as! UIImage
        if let data = UIImageJPEGRepresentation(image, 0.8){
            let id = NSUUID().uuidString
            FirebaseHelper.storageRef.child("images/\(id).jpeg").putData(data, metadata: nil, completion: { (metadata, err) in
                if let error = err{
                    print(error)
                    return
                }
                let now = Date()
                let formatter = DateFormatter()
                formatter.timeZone = TimeZone.current
                formatter.dateFormat = "HH:mm:ss"
                let timeString = formatter.string(from: now)
                
                formatter.dateFormat = "yyyy-MM-dd"
                let dateString = formatter.string(from: now)
                
                
                let ref = FirebaseHelper.ref.child("chats").child(self.chat.id).child("posts")
                let childRef = ref.childByAutoId()
                let values = ["image":id, "profileId":FirebaseHelper.personal.userId, "timestamp":timeString, "datestamp":dateString] as [String : Any]
                childRef.updateChildValues(values)
            })
        }
    }
    
    @IBAction func menuButtonTapped(_ sender: Any) {
        //display/hide side bar
        UIView.animate(withDuration: 0.25) {
            if self.selectionView.frame.origin == CGPoint(x: 0, y: 0){
                self.statusBarHidden = false
                self.selectionView.frame.origin = CGPoint(x: -self.view.frame.size.width/2, y: 0)
                self.menuBar.frame.origin = CGPoint(x: 0, y: 0)
                self.joinChatLabel.frame.origin.x -= self.view.frame.size.width/2
                self.sendButton.frame.origin.x -= self.view.frame.size.width/2
                self.textView.frame.origin.x -= self.view.frame.size.width/2
                self.chatView.frame.origin.x -= self.view.frame.size.width/2
                self.imageButton.frame.origin.x -= self.view.frame.size.width/2
            }else{
                self.statusBarHidden = true
                self.selectionView.frame.origin = CGPoint(x: 0, y: 0)
                self.menuBar.frame.origin = CGPoint(x: self.view.frame.size.width/2, y: 0)
                self.joinChatLabel.frame.origin.x += self.view.frame.size.width/2
                self.sendButton.frame.origin.x += self.view.frame.size.width/2
                self.textView.frame.origin.x += self.view.frame.size.width/2
                self.chatView.frame.origin.x += self.view.frame.size.width/2
                self.imageButton.frame.origin.x += self.view.frame.size.width/2
            }
        }
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        return .fade
    }
    
    override var prefersStatusBarHidden: Bool{
        return statusBarHidden
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    @objc func chatTapped(sender:UIButton){
        //change chats
        settingsButton.alpha = 1
        chatNameLabel.alpha = 1
        if self.chat.id != (FirebaseHelper.personal.chats[sender.tag] as! Chat).id{
            self.chat = FirebaseHelper.personal.chats[sender.tag] as! Chat
            (FirebaseHelper.personal.chats[sender.tag] as! Chat).posts.removeAllObjects()
            self.chat.posts.removeAllObjects()
            self.chatNameLabel.text = selectionView.tableView.cellForRow(at: IndexPath(item: sender.tag, section: 0))?.textLabel?.text!
            sections = NSMutableArray()
            fetchPosts(chatId: chat.id)
            chatView.reloadData()
        }
        UIView.animate(withDuration: 0.25) {
            if self.selectionView.frame.origin == CGPoint(x: 0, y: 0){
                self.statusBarHidden = false
                self.selectionView.frame.origin = CGPoint(x: -self.view.frame.size.width/2, y: 0)
                self.menuBar.frame.origin = CGPoint(x: 0, y: 0)
                self.joinChatLabel.frame.origin.x -= self.view.frame.size.width/2
                self.sendButton.frame.origin.x -= self.view.frame.size.width/2
                self.textView.frame.origin.x -= self.view.frame.size.width/2
                self.chatView.frame.origin.x -= self.view.frame.size.width/2
            }
        }
    }
    
    @IBAction func sendTapped(_ sender: Any) {
        if textView.text! != ""{
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "HH:mm:ss"
            let timeString = formatter.string(from: now)
            
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: now)
            
            
            let ref = FirebaseHelper.ref.child("chats").child(chat.id).child("posts")
            let childRef = ref.childByAutoId()
            let values = ["text":textView.text!, "profileId":FirebaseHelper.personal.userId, "timestamp":timeString, "datestamp":dateString] as [String : Any]
            childRef.updateChildValues(values)
            
            textView.text = ""
            textView.endEditing(true)
            textView.frame.size.height = (textView.font?.lineHeight)!
            sendingView.frame.size.height = (textView.font?.lineHeight)!
        }
    }
    
    
    
    //MARK: Move to new vc
    
    @objc func moveToSelfProfile(){
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        let chatArray = NSMutableArray()
        for var chat in FirebaseHelper.personal.chats{
            chatArray.add((chat as! Chat).id)
        }
        
        let friendArray = NSMutableArray()
        for var friend in FirebaseHelper.personal.friends{
            friendArray.add((friend as! Profile).userId)
        }
        let selfProfile = Profile(username: FirebaseHelper.personal.username, userId: FirebaseHelper.personal.userId, friends: friendArray, icon: FirebaseHelper.personal.icon, chats: chatArray, latitude: FirebaseHelper.personal.latitude, longitude: FirebaseHelper.personal.longitude)
        vc.setProfiles(profile: selfProfile, profiles: friendArray)
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    @objc func moveToAddViewController(){
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "AddViewController") as! AddViewController
        vc.isFriends = false
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func moveToProfileViewController(sender:UIButton){
        for var i in FirebaseHelper.personal.friends{
            if (i as! Profile).username == sender.currentTitle!.replacingOccurrences(of: " ", with: "") {
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController

                let array = NSMutableArray()
                for var j in (i as! Profile).friends{
                    array.add(j)
                }
                array.add(FirebaseHelper.personal.userId)
                vc.setProfiles(profile: (i as! Profile), profiles: array)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    
    
    @objc func moveToPlaceViewer(sender:UIButton){
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlaceViewerViewController") as! PlaceViewerViewController
        let post = chat.posts.object(at: sender.tag) as! Post
        vc.setPlace(place: post.place as! GMSPlace)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    
    func textViewDidChange(_ textView: UITextView) {
        let numLines = floor(textView.contentSize.height/(textView.font?.lineHeight)!)
        let prevLines = floor(textView.frame.size.height/(textView.font?.lineHeight)!)
        if numLines > prevLines{
            sendingView.frame.size.height += (textView.font?.lineHeight)!*CGFloat(numLines-prevLines)
            sendingView.frame.origin.y -= (textView.font?.lineHeight)!*CGFloat(numLines-prevLines)
            imageButton.frame.origin.y += (textView.font?.lineHeight)!*CGFloat(numLines-prevLines)
            sendButton.frame.origin.y += (textView.font?.lineHeight)!*CGFloat(numLines-prevLines)
            let rect = CGRect(origin: self.textView.frame.origin, size: CGSize(width: self.textView.frame.size.width, height: sendingView.frame.size.height))
            self.textView.frame = rect
        }else if numLines < prevLines{
            sendingView.frame.size.height -= (textView.font?.lineHeight)!*CGFloat(numLines-prevLines)
            sendingView.frame.origin.y += (textView.font?.lineHeight)!*CGFloat(numLines-prevLines)
            imageButton.frame.origin.y -= (textView.font?.lineHeight)!*CGFloat(numLines-prevLines)
            sendButton.frame.origin.y -= (textView.font?.lineHeight)!*CGFloat(numLines-prevLines)
            let rect = CGRect(origin: self.textView.frame.origin, size: CGSize(width: self.textView.frame.size.width, height: sendingView.frame.size.height))
            self.textView.frame = rect
        }
    }
    
    
    //MARK: TableView methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (sections.object(at: section) as! section).amt
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ChatMessageCell(style: .default, reuseIdentifier: "cell")
        var startIndex = 0
        cell.backgroundColor = .clear
        for var i in 0..<indexPath.section{
            startIndex += (sections.object(at: i) as! section).amt!
        }
        if chat.posts.count > startIndex+indexPath.item{
            let post = chat.posts[startIndex+indexPath.item] as! Post
            if let place = post.place as? String{
                cell.textView.text = post.text
                setupCell(cell, post: post, hasPlace: false, index: startIndex+indexPath.item)
            }else{
                cell.textView.text = (post.place as! GMSPlace).name
                setupCell(cell, post: post, hasPlace: true, index: startIndex+indexPath.item)
            }
            if post.image == ""{
                cell.bubbleWidthAnchor?.constant = estimateFrameForText(cell.textView.text!).width + 32
            }else{
                let data = Data(base64Encoded: post.image, options: .ignoreUnknownCharacters)!
                let image = UIImage(data: data)!
                cell.bubbleWidthAnchor?.constant = sizeForImage(image: image).width+32
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var startIndex = 0
        for var i in 0..<indexPath.section{
            startIndex += (sections.object(at: i) as! section).amt!
        }
        let post = chat.posts[startIndex+indexPath.item] as! Post
        if post.image == ""{
            return estimateFrameForText(post.text).height+26
        }else{
            let data = Data(base64Encoded: post.image, options: .ignoreUnknownCharacters)!
            let image = UIImage(data: data)!
            return sizeForImage(image: image).width+26
        }
    }
    

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let text = (sections.object(at: section) as! section).date!
        let separatedDate = text.split(separator: "-")
        let month = months[Int(separatedDate[1])!-1]
        
        let label = UILabel()
        
        label.backgroundColor = .clear
        label.textColor = .black
        label.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 50)
        label.textColor = lightGray
        label.font = UIFont(name: "Raleway-Thin", size: 12)
        label.text = "\(month) \(separatedDate[2]), \(separatedDate[0])"
        label.textAlignment = .center
        return label
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    
    fileprivate func setupCell(_ cell: ChatMessageCell, post: Post, hasPlace:Bool, index:Int) {
        if post.profileId != FirebaseHelper.personal.userId {
            let iconString = profileIcons.object(forKey: post.profileId) as! String
            let data = Data(base64Encoded: iconString, options: .ignoreUnknownCharacters)
            cell.profileImageView.image = UIImage(data:data!)
        }

        if post.image != ""{
            let data = Data(base64Encoded: post.image, options: .ignoreUnknownCharacters)!
            let image = UIImage(data: data)!
            cell.messageImageView.image = image
            cell.button.frame.size = (cell.imageView?.frame.size)!
            cell.button.tag = index
            cell.button.addTarget(self, action: #selector(imageTapped(sender:)), for: .touchUpInside)
        }
        
        if post.profileId == FirebaseHelper.personal.userId {
            //outgoing blue
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white
            cell.profileImageView.isHidden = true

            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false

        } else {
            //incoming gray
            cell.bubbleView.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            cell.profileImageView.frame.origin.y = cell.bubbleView.frame.origin.y

            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
        }
        
        if hasPlace{
            cell.button.tag = index
            cell.button.addTarget(self, action: #selector(moveToPlaceViewer(sender:)), for: .touchUpInside)
        }
    }
    
    fileprivate func estimateFrameForText(_ text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    fileprivate func sizeForImage(image:UIImage) -> CGSize{
        let scale = chatView.frame.size.width/3/image.size.width
        return CGSize(width: image.size.width*scale, height: image.size.height*scale)
    }
}
