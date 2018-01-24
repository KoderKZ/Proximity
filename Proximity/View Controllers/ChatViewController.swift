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
import GuillotineMenu
class ChatViewController:UIViewController,UITableViewDelegate,UITableViewDataSource,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITextViewDelegate,UIScrollViewDelegate,SelectionViewControllerDelegate{

    
    fileprivate lazy var presentationAnimator = GuillotineTransitionAnimation()

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
    var changingLines = false
    var displayImageView:DisplayImageView!
    let profileIcons = NSMutableDictionary()
    let members:NSMutableArray = NSMutableArray()
    var postAmount = 0
    var canDismiss = true
    var keyboardUp = false
    var postsObserver:UInt!
    var membersObserver:UInt!
    var selectionView = SelectionView()
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
        
//        menuBar.backgroundColor = darkBgColor

        menuButton.adjustsImageWhenHighlighted = false
        settingsButton.adjustsImageWhenHighlighted = false
        
        chatView.backgroundColor = lightBgColor
        
        textView.backgroundColor = .white
        textView.textColor = .black
        textView.delegate = self
        textView.centerVertically()
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.black.cgColor
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
        
        selectionView = storyboard?.instantiateViewController(withIdentifier: "SelectionViewController") as! SelectionView
        selectionView.modalPresentationStyle = .custom
        selectionView.transitioningDelegate = self
        selectionView.delegate = self
        presentationAnimator.animationDelegate = selectionView as? GuillotineAnimationDelegate
        presentationAnimator.supportView = self.navigationController?.navigationBar
        presentationAnimator.presentButton = menuButton
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        textView.isEditable = true
        canDismiss = true
    }



    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.view.isUserInteractionEnabled = true
        if chat != nil{
            chatNameLabel.text = chat.chatName
            FirebaseHelper.ref.removeObserver(withHandle: postsObserver)
            FirebaseHelper.ref.removeObserver(withHandle: membersObserver)
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
            StoreViewed.sharedInstance.addViewed(id: chat.id)
        }else if FirebaseHelper.personal.chats.count == 0{
            settingsButton.alpha = 0
            chatNameLabel.alpha = 0
            joinChatLabel.alpha = 1
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
                        //                                                    var poll:Poll
                        if postValues.keys.contains("text"){text = postValues["text"] as! String}
                        if postValues.keys.contains("image"){
                            image = postValues["image"] as! String
                            

                        }
                        
                        if postValues.keys.contains("place"){
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
                        self.chatView.reloadData(){
                            self.menuButton.isEnabled = true
                        }
                        let indexPath = IndexPath(row: (self.sections.object(at: self.sections.count-1) as! section).amt-1, section: self.sections.count-1)
                        self.chatView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                    }
                }
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
            if sections.count > 0{
                let indexPath = IndexPath(row: (self.sections.object(at: self.sections.count-1) as! section).amt-1, section: self.sections.count-1)
                self.chatView.scrollToRow(at: indexPath, at: .bottom, animated: false)
            }
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
        displayImageView.imageView.loadImageUsingCacheWithUrlString(post.image)
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
                
//                self.chat.posts.removeAllObjects()
//                self.sections.removeAllObjects()
                
                let ref = FirebaseHelper.ref.child("chats").child(self.chat.id).child("posts")
                let childRef = ref.childByAutoId()
                let values = ["image":id, "profileId":FirebaseHelper.personal.userId, "timestamp":timeString, "datestamp":dateString] as [String : Any]
                childRef.updateChildValues(values)
            })
        }
    }
    
    func moveChatViews() {
        self.menuBar.frame.origin = CGPoint(x: self.view.frame.size.width/4*3, y: 0)
        self.joinChatLabel.frame.origin.x = self.view.frame.size.width/4*3
        self.textView.frame.origin.x = self.view.frame.size.width/4*3
        self.chatView.frame.origin.x = self.view.frame.size.width/4*3
        self.sendingView.frame.origin.x = self.view.frame.size.width/4*3
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    func didDismiss() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func chatTapped(_chat:Chat) {
        self.chat = _chat
        self.chat.posts.removeAllObjects()
        self.chatNameLabel.text = _chat.chatName
        self.sections = NSMutableArray()
        FirebaseHelper.ref.removeObserver(withHandle: self.postsObserver!)
        FirebaseHelper.ref.removeObserver(withHandle: self.membersObserver!)
        self.fetchPosts(chatId: _chat.id)
        self.fetchMembers(chatId: _chat.id)
        self.chatView.reloadData()
        StoreViewed.sharedInstance.addViewed(id: _chat.id)
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func menuButtonTapped(_ sender: Any) {
        //display/hide side bar
        self.textView.endEditing(true)
        selectionView.transitioningDelegate = self
        self.navigationController?.present(selectionView, animated: true, completion: nil)
        
        
//        let menuViewController = storyboard!.instantiateViewController(withIdentifier: "MenuViewController")
//        menuViewController.modalPresentationStyle = .custom
//        menuViewController.transitioningDelegate = self
//
//        presentationAnimator.animationDelegate = menuViewController as? GuillotineAnimationDelegate
//        presentationAnimator.supportView = navigationController!.navigationBar
//        presentationAnimator.presentButton = sender
//        present(menuViewController, animated: true, completion: nil)
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
            
//            sections.removeAllObjects()
//            self.chat.posts.removeAllObjects()
            
            let ref = FirebaseHelper.ref.child("chats").child(chat.id).child("posts")
            let childRef = ref.childByAutoId()
            let values = ["text":textView.text!, "profileId":FirebaseHelper.personal.userId, "timestamp":timeString, "datestamp":dateString] as [String : Any]
            childRef.updateChildValues(values)
            
            textView.text = ""
            textView.endEditing(true)
        }
    }
    
    
    
    //MARK: Move to new vc
    
    
    
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
        if canDismiss && !changingLines && round(textView.frame.size.height) == round(textView.contentSize.height){
            if keyboardUp == false{
                textView.isEditable = false
                return
            }
            
            self.dismissKeyboard()
            textView.isEditable = true
        }else{
//            canDismiss = false
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
            }else{
                loadImageUsingUrlString(post.image, image: { (success) in
                    cell.bubbleWidthAnchor?.constant = self.sizeForImage(image: success).width+32
                })
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var startIndex = 0
        var returnAmt:CGFloat = 0
        for var i in 0..<indexPath.section{
            startIndex += (sections.object(at: i) as! section).amt!
        }
        let post = chat.posts[startIndex+indexPath.item] as! Post
        if post.image == ""{
            return estimateFrameForText(post.text).height+26
        }else{
            loadImageUsingUrlString(post.image, image: { (success) in
                returnAmt = (self.sizeForImage(image: success).height)+26
            })
        }
        return returnAmt
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
//            let data = Data(base64Encoded: post.image, options: .ignoreUnknownCharacters)!
//            let image = UIImage(data: data)!
            
            cell.messageImageView.loadImageUsingCacheWithUrlString(post.image)
            cell.button.frame.size = (cell.imageView?.frame.size)!
            cell.button.tag = index
            cell.button.addTarget(self, action: #selector(imageTapped(sender:)), for: .touchUpInside)
        }
        
        if post.profileId == FirebaseHelper.personal.userId {
            //outgoing blue
            cell.bubbleView.backgroundColor = darkBgColor
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

extension ChatViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationAnimator.mode = .presentation
        return presentationAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationAnimator.mode = .dismissal
        return presentationAnimator
    }
}
