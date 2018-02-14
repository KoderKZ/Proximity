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
class ChatViewController:UIViewController,UITableViewDelegate,UITableViewDataSource,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITextViewDelegate,UIScrollViewDelegate,PlaceViewerViewControllerDelegate,SettingsViewControllerDelegate{
    
    
    @IBOutlet weak var sendingView: UIView!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var menuBar: UIView!
    @IBOutlet weak var chatNameLabel: UILabel!
    @IBOutlet weak var chatView: UITableView!
    @IBOutlet var imageButton: UIButton!
    var chat:Chat!
    var changingLines = false
    var displayImageView:DisplayImageView!
    let members:NSMutableArray = NSMutableArray()
    var postAmount = 0
    var canDismiss = true
    var keyboardUp = false
    var postsObserver:UInt!
    var membersObserver:UInt!
    var statusBarHidden:Bool = false{
        didSet{
            if statusBarHidden == false{
                delay(0.25){
                    UIView.animate(withDuration: 0.5) {
                        self.setNeedsStatusBarAppearanceUpdate()
                    }
                }
            }else{
                UIView.animate(withDuration: 0.5) {
                    self.setNeedsStatusBarAppearanceUpdate()
                }
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
        
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tableViewTapped))
        tap.cancelsTouchesInView = false
        chatView.addGestureRecognizer(tap)

    
        
        //set up side bar for selecting chats
        
        displayImageView = DisplayImageView(frame: self.view.frame)
        self.view.addSubview(displayImageView)
        

        menuButton.adjustsImageWhenHighlighted = false
        settingsButton.adjustsImageWhenHighlighted = false
        
        chatView.backgroundColor = lightBgColor
        
        textView.backgroundColor = .white
        textView.textColor = .black
        textView.delegate = self
        textView.centerVertically()
        sendButton.backgroundColor = .white
        sendButton.setTitleColor(blackBgColor, for: .normal)
        imageButton.backgroundColor = .white
        sendingView.backgroundColor = .white
        

        
        sendButton.frame.size.height = (textView.font?.lineHeight)!
        imageButton.frame.size = CGSize(width: (textView.font?.lineHeight)!, height: (textView.font?.lineHeight)!)
        
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        let profile = Profile(username: FirebaseHelper.personal.username, userId: FirebaseHelper.personal.userId, friends: FirebaseHelper.personal.friends, icon: FirebaseHelper.personal.icon, chats: FirebaseHelper.personal.chats, latitude: FirebaseHelper.personal.latitude, longitude: FirebaseHelper.personal.longitude)
        
        chatView.separatorColor = .clear
        chatView.allowsSelection = false
        
        
        let _textView = UITextView()
        _textView.text = " "
        textView.frame.size.height = sendingView.frame.size.height
        textView.frame.origin.y = sendingView.frame.size.height/2-textView.frame.size.height/2
        self.textView.contentSize = textView.frame.size
        textView.frame.size.width = sendingView.frame.size.width-imageButton.frame.size.width-sendButton.frame.size.width
        

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        textView.isEditable = true
        canDismiss = true
        self.chatView.reloadData()

    }



    override func viewWillAppear(_ animated: Bool) {

        
//        delay(1.5){
//            self.chatView.reloadData()
//        }
        if postsObserver == nil{
            chat.posts.removeAllObjects()
            sections.removeAllObjects()
            super.viewWillAppear(true)
            
            fetchMembers(chatId: chat.id)
            fetchPosts(chatId: chat.id)
            self.view.isUserInteractionEnabled = true
            chatNameLabel.text = chat.chatName

            textView.frame.origin.y = 0

            let border = CALayer()
            border.frame = CGRect(x: textView.frame.size.width-1, y: 0, width: 1, height: 1000)
            border.backgroundColor = UIColor.black.cgColor
            textView.layer.addSublayer(border)
            
            let border2 = CALayer()
            border2.frame = CGRect(x: 0, y: 0, width: 1, height: 1000)
            border2.backgroundColor = UIColor.black.cgColor
            textView.layer.addSublayer(border2)
        }
    }

    

    
    //MARK: Observers for data
    
    
    
    func fetchMembers(chatId:String){
        var members = NSArray()
        membersObserver = FirebaseHelper.ref.child("chats").child(chatId).child("members").observe(.childAdded) { (snapshot) in
            var contains = false
            for var i in self.chat.members{
                if (i as! String) == snapshot.value as! String{
                    contains = true
                }
            }
            if !contains{
                self.chat.members.add(snapshot.value)
            }
            if self.members.count < self.chat.members.count{
                contains = false
            }
            if !contains{
                FirebaseHelper.ref.child("users").child(snapshot.value as! String).observeSingleEvent(of:.value, with: { (snapshot2) in
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
    }
    
    func fetchPosts(chatId:String) {
        postsObserver = FirebaseHelper.ref.child("chats").child(chatId).child("posts").observe(.childAdded) { (snapshot) in
            FirebaseHelper.ref.child("chats").child(chatId).child("posts").observeSingleEvent(of:.value, with: { (postsCount) in
                if let posts = postsCount.value as? NSDictionary{
                    self.postAmount = posts.allKeys.count
                }
                if self.postAmount > self.chat.posts.count{
                    self.menuButton.isEnabled = false
                    if let postValues = snapshot.value as? [String:AnyObject]{
                        var text = ""
                        var image = ""
                        var place:AnyObject! 
                        var foundPlace = false
                        var increasedBool = false
                        var post:Post!
                        if postValues.keys.contains("text"){text = postValues["text"] as! String}
                        if postValues.keys.contains("image"){
                            image = postValues["image"] as! String
                            loadImageUsingUrlString(image) { success in}
                        }
                        
                        if postValues.keys.contains("place"){
                            foundPlace = true
                            let index = self.chat.posts.count
                            post = Post(chatId: self.chat.id, text: "" , image: "", profileId: postValues["profileId"] as! String, timestamp: postValues["timestamp"] as! String, datestamp: postValues["datestamp"] as! String, place: "" as AnyObject)
                            self.chat.posts.add(post)
                            let placeId = postValues["place"] as! String
                            FirebaseHelper.placesClient.lookUpPlaceID(placeId, callback: { (placeSnap, err) in
                                place = placeSnap!
                                post = Post(chatId: self.chat.id, text: text , image: image, profileId: postValues["profileId"] as! String, timestamp: postValues["timestamp"] as! String, datestamp: postValues["datestamp"] as! String, place: place)
                                if !self.chat.posts.contains(post){
                                    self.chat.posts.removeObject(at: index)
                                    self.chat.posts.insert(post, at: index)
                                    self.chatView.reloadData()
                                }
                            })
                            
                        }else{
                            place = "none" as AnyObject
                        }
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
                        self.chatView.reloadData(){
                            self.menuButton.isEnabled = true
                            self.canDismiss = true
                        }
                        let indexPath = IndexPath(row: (self.sections.object(at: self.sections.count-1) as! section).amt-1, section: self.sections.count-1)
                        self.chatView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                    }
                }
                self.chatView.reloadData()
            })
            
        }
        
    }
    
    
    
    
    //MARK: Keyboard Updaters
    
    @objc func keyboardWillShow(notification:NSNotification){
        if let viewController = self.navigationController?.topViewController as? ChatViewController{
            canDismiss = false
            let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! CGRect
            let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double
            self.chatView.frame.size.height = self.chatView.frame.size.height-keyboardFrame.size.height
            UIView.animate(withDuration: keyboardDuration, animations: {
                self.sendingView.frame.origin.y = keyboardFrame.origin.y-self.sendingView.frame.size.height
            }, completion: { (true) in
                delay(0.5){
                    self.canDismiss = true
                    self.keyboardUp = true
                }
            })
            self.textView.isEditable = true
        }
    }
    
    @objc func keyboardWillHide(notification:NSNotification){
        if let viewController =  self.navigationController?.topViewController as? ChatViewController{
            if canDismiss{
                keyboardUp = false
                let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double
                let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! CGRect
                self.chatView.frame.size.height = self.chatView.frame.size.height+keyboardFrame.size.height
                UIView.animate(withDuration: keyboardDuration, animations: {
                    self.sendingView.frame.origin.y = self.view.frame.size.height-self.sendingView.frame.size.height
                }, completion: { (true) in
                    self.canDismiss = true
                    self.textView.isEditable = true
                })
            }
        }
    }
    
    //MARK: Button Actions
    
    @objc func imageTapped(sender:UIButton){
        let post = self.chat.posts.object(at: sender.tag) as! Post
        loadImageUsingUrlString(post.image) { (image) in
            self.displayImageView.imageView.image = image
        }
        displayImageView.setImage(image: displayImageView.imageView.image!)
        displayImageView.appear()
    }
    
    @IBAction func sendImageTapped(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated:true, completion: nil)
        
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        if let data = UIImageJPEGRepresentation(image, 0.8){
            let imageString = data.base64EncodedString()
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "HH:mm:ss"
            let timeString = formatter.string(from: now)

            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: now)

            let ref = FirebaseHelper.ref.child("chats").child(self.chat.id).child("posts")
            let childRef = ref.childByAutoId()
            let values = ["image":imageString, "profileId":FirebaseHelper.personal.userId, "timestamp":timeString, "datestamp":dateString] as [String : Any]
            childRef.updateChildValues(values)
        }
    }
    
    @IBAction func menuButtonTapped(_ sender: Any) {
        //display/hide side bar
        self.textView.endEditing(true)
        StoreViewed.sharedInstance.addViewed(id: chat.id)
        self.navigationController?.popViewController(animated: true)
    }
    
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        return .slide
    }
    
    override var prefersStatusBarHidden: Bool{
        return statusBarHidden
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
        }
    }
    
    
    
    //MARK: Move to new vc
    
    
    @IBAction func settingsTapped(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
        vc.delegate = self
        self.navigationController?.present(vc, animated: true, completion: nil)
        vc.setChat(chat: self.chat)
    }
    
    @objc func moveToPlaceViewer(sender:UIButton){
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PlaceViewerViewController") as! PlaceViewerViewController
        let post = chat.posts.object(at: sender.tag) as! Post
        vc.setPlace(place: post.place as! GMSPlace)
        vc.delegate = self
        self.navigationController?.present(vc, animated: true, completion: nil)
    }
    
    func dismissPlace() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func dismissSettings(chat: Chat) {
        let usersRef = FirebaseHelper.ref.child("chats").child(chat.id)
        if self.chat!.members != chat.members{
            let membersIds = NSMutableArray()
            membersIds.add(FirebaseHelper.personal.userId)
            for var member in self.members{
                membersIds.add((member as! Profile).userId)
            }//add members
            usersRef.updateChildValues(["members":membersIds])//update Firebase
            for var i in membersIds{
                FirebaseHelper.ref.child("users").child(i as! String).observeSingleEvent(of: .value, with: { (user) in
                    if let dict = user.value as? NSDictionary{
                        var index = 0
                        if (dict.allKeys as NSArray).contains("chats"){
                            index = (dict["chats"] as! NSArray).count
                        }
                        user.ref.child("chats").updateChildValues(["\(index)":chat.id])
                    }
                })
            }
        }
        if self.chat!.joinType != chat.joinType{
            let values = ["joinType":chat.joinType] as [String : Any]//update join type
            usersRef.updateChildValues(values, withCompletionBlock: { (err, ref) in
                if err != nil{
                    print(err)
                    return
                }
            })
        }
        self.chat = chat
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func leftChat() {
        self.navigationController?.dismiss(animated: false, completion: {
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let numLines = floor(textView.contentSize.height/(textView.font?.lineHeight)!)
        let prevLines = floor(textView.frame.size.height/(textView.font?.lineHeight)!)
        if numLines > prevLines{
            changingLines = true
            let size = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat(MAXFLOAT)))
            sendingView.frame.origin.y += sendingView.frame.size.height-size.height
            sendingView.frame.size.height = size.height
            let rect = CGRect(origin: CGPoint(x:self.textView.frame.origin.x, y:0), size: size)
            self.textView.frame.size.height = rect.size.height
            self.textView.contentSize.height = rect.size.height
            textView.centerVertically()
            canDismiss = false
            self.chatView.frame.size.height += sendingView.frame.size.height-size.height
            self.canDismiss = true
            delay(1){
                self.changingLines = false
            }
        }else if numLines < prevLines{
            changingLines = true
            let size = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat(MAXFLOAT)))
            sendingView.frame.origin.y += sendingView.frame.size.height-size.height
            sendingView.frame.size.height = size.height
            let rect = CGRect(origin: CGPoint(x:self.textView.frame.origin.x, y:0), size: size)
            self.textView.frame.size.height = rect.size.height
            self.textView.contentSize.height = rect.size.height
            textView.centerVertically()
            canDismiss = false
            self.chatView.frame.size.height += sendingView.frame.size.height-size.height
            self.canDismiss = true
            delay(1){
                self.changingLines = false
            }
        }

    }
    
    
    //MARK: TableView methods
    
    @objc func tableViewTapped(){
        if canDismiss && keyboardUp{
            dismissKeyboard()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if canDismiss && !changingLines{
            self.dismissKeyboard()
            textView.isEditable = true
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        textView.isEditable = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        textView.isEditable = true
    }
    
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
                return cell
            }else{
                loadImageUsingUrlString(post.image, image: { (success) in
                    cell.bubbleWidthAnchor?.constant = self.sizeForImage(image: success).width+32
                })
            }
        }
        return cell

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if chat.posts.count > 0{
            var startIndex = 0
            var returnAmt:CGFloat = 0
            for var i in 0..<indexPath.section{
                startIndex += (sections.object(at: i) as! section).amt!
            }
            let post = chat.posts[startIndex+indexPath.row] as! Post
            if let place = post.place as? GMSPlace{
                return estimateFrameForText(place.name).height+26
            }else if post.image == ""{
                return estimateFrameForText(post.text).height+26
            }else{
                loadImageUsingUrlString(post.image, image: { (success) in
                    returnAmt = (self.sizeForImage(image: success).height)+26
                })
            }
            return returnAmt
        }else{
            return 0
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
        label.textColor = .black
        label.font = UIFont(name: "Raleway", size: 12)
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
            loadImageUsingUrlString(post.image, image: { (image) in
                cell.messageImageView.image = image
                
            })
            cell.button.frame.size = (cell.imageView?.frame.size)!
            cell.button.tag = index
            cell.button.addTarget(self, action: #selector(imageTapped(sender:)), for: .touchUpInside)
        }
        
        if post.profileId == FirebaseHelper.personal.userId {
            //outgoing green
            cell.bubbleView.backgroundColor = darkBgColor
            cell.textView.textColor = UIColor.white
            if let place = post.place as? GMSPlace{
                
//                let string = NSAttributedString(string: post.text, attributes: [NSAttributedStringKey.underlineStyle:NSUnderlineStyle.styleSingle.rawValue, NSAttributedStringKey.strokeColor:darkGray])
//                cell.textView.attributedText = string
                cell.textView.textColor = darkGray
                
            }
            cell.profileImageView.isHidden = true

            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false

        } else {
            //incoming gray
            cell.bubbleView.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            cell.profileImageView.frame.origin.y = cell.bubbleView.frame.origin.y
            if let place = post.place as? GMSPlace{
                
//                let string = NSAttributedString(string: post.text, attributes: [NSAttributedStringKey.underlineStyle:NSUnderlineStyle.styleSingle.rawValue, NSAttributedStringKey.strokeColor:blue])
//                cell.textView.attributedText = string
                
                cell.textView.textColor = blue
            }
            
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


