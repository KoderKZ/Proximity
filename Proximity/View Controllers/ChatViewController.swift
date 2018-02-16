//
//  ChatViewController.swift
//  Proximity
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
    var displayImageView:DisplayImageView!
    let members:NSMutableArray = NSMutableArray()
    var postAmount = 0
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
        
        
        let tapDown: SingleTouchDownGestureRecognizer = SingleTouchDownGestureRecognizer(target: self, action: #selector(tableViewTappedDown))
        tapDown.cancelsTouchesInView = false
        chatView.addGestureRecognizer(tapDown)
    
        
        //set up side bar for selecting chats
        
        displayImageView = DisplayImageView(frame: self.view.frame)
        self.view.addSubview(displayImageView)
        

        menuButton.adjustsImageWhenHighlighted = false
        settingsButton.adjustsImageWhenHighlighted = false
        
        chatView.backgroundColor = .white
        
        textView.backgroundColor = .white
        textView.textColor = .black
        textView.delegate = self
        textView.centerVertically()
        sendButton.backgroundColor = .white
        sendButton.setTitleColor(darkBgColor, for: .normal)
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
        
        
        imageButton.imageView?.image = imageButton.imageView?.image!.withRenderingMode(.alwaysTemplate)
        imageButton.imageView?.tintColor = darkBgColor
//        theImageView.image = theImageView.image!.withRenderingMode(.alwaysTemplate)
//        theImageView.tintColor = UIColor.red
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        textView.isEditable = true
        self.chatView.reloadData()
    }


    override func viewDidLayoutSubviews() {
        textView.frame.origin.y = 0
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

            textView.frame.size.width = self.view.frame.size.width-imageButton.frame.size.width-sendButton.frame.size.width

            let border = CALayer()
            border.frame = CGRect(x: textView.frame.size.width-1, y: 0, width: 1, height: 1000)
            border.backgroundColor = UIColor.black.cgColor
            textView.layer.addSublayer(border)
            
            let border2 = CALayer()
            border2.frame = CGRect(x: 0, y: 0, width: 1, height: 1000)
            border2.backgroundColor = UIColor.black.cgColor
            textView.layer.addSublayer(border2)
            
            let border3 = CALayer()
            border3.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 1)
            border3.backgroundColor = UIColor.black.cgColor
            sendingView?.layer.addSublayer(border3)
            
            let border4 = CALayer()
            border4.frame = CGRect(x: 0, y: menuBar.frame.size.height, width: self.view.frame.size.width, height: 1)
            border4.backgroundColor = UIColor.black.cgColor
            menuBar.layer.addSublayer(border4)
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
                self.settingsButton.isEnabled = false
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
                        if self.members.count == self.chat.members.count{
                            self.settingsButton.isEnabled = true
                        }
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
        let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! CGRect
        let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double
        self.chatView.frame.size.height = self.chatView.frame.size.height-keyboardFrame.size.height
        if sections.count > 0{
            let lastIndex = IndexPath(row: (sections[sections.count-1] as! section).amt-1, section: sections.count-1)
            self.chatView.scrollToRow(at: lastIndex, at: .bottom, animated: false)
        }
        UIView.animate(withDuration: keyboardDuration, animations: {
            self.sendingView.frame.origin.y = keyboardFrame.origin.y-self.sendingView.frame.size.height
        })
        self.textView.isEditable = true
    }
    
    @objc func keyboardWillHide(notification:NSNotification){
            let keyboardDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double
            let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! CGRect
            self.chatView.frame.size.height = self.chatView.frame.size.height+keyboardFrame.size.height
            UIView.animate(withDuration: keyboardDuration, animations: {
                self.sendingView.frame.origin.y = self.view.frame.size.height-self.sendingView.frame.size.height
            }, completion: { (true) in
                self.textView.isEditable = true
            })
    }
    
    //MARK: Button Actions
    
    
    //enlarge image
    @objc func imageTapped(sender:UIButton){
        let post = self.chat.posts.object(at: sender.tag) as! Post
        loadImageUsingUrlString(post.image) { (image) in
            self.displayImageView.imageView.image = image
        }
        displayImageView.setImage(image: displayImageView.imageView.image!)
        displayImageView.appear()
    }
    
    //image picker helper
    @IBAction func sendImageTapped(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
            imageButton.imageView?.image = imageButton.imageView?.image!.withRenderingMode(.alwaysTemplate)
            self.imageButton.tintColor = darkBgColor
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
        imageButton.imageView?.image = imageButton.imageView?.image!.withRenderingMode(.alwaysTemplate)
        self.imageButton.tintColor = darkBgColor

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
            imageButton.imageView?.image = imageButton.imageView?.image!.withRenderingMode(.alwaysTemplate)
            self.imageButton.tintColor = darkBgColor
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

    
    @IBAction func sendTapped(_ sender: Any) {//send message
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
        vc.setChat(chat: self.chat, memberProfs: self.members)
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
    
    func dismissSettings(chat: Chat) {//put settings in effect
        let usersRef = FirebaseHelper.ref.child("chats").child(chat.id)
        if self.chat!.members != chat.members{
            let membersIds = NSMutableArray()
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
                        if !(dict["chats"] as! NSArray).contains(chat.id){
                            user.ref.child("chats").updateChildValues(["\(index)":chat.id])
                        }
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
    
    func textViewDidChange(_ textView: UITextView) {//resize textview
        let numLines = floor(textView.contentSize.height/(textView.font?.lineHeight)!)
        let prevLines = floor(textView.frame.size.height/(textView.font?.lineHeight)!)
        if numLines > prevLines{
            let size = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat(MAXFLOAT)))
            sendingView.frame.origin.y += sendingView.frame.size.height-size.height
            sendingView.frame.size.height = size.height
            let rect = CGRect(origin: CGPoint(x:self.textView.frame.origin.x, y:0), size: size)
            self.textView.frame.size.height = rect.size.height
            self.textView.contentSize.height = rect.size.height
            textView.centerVertically()
            self.chatView.frame.size.height += sendingView.frame.size.height-size.height
        }else if numLines < prevLines{
            let size = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat(MAXFLOAT)))
            sendingView.frame.origin.y += sendingView.frame.size.height-size.height
            sendingView.frame.size.height = size.height
            let rect = CGRect(origin: CGPoint(x:self.textView.frame.origin.x, y:0), size: size)
            self.textView.frame.size.height = rect.size.height
            self.textView.contentSize.height = rect.size.height
            textView.centerVertically()
            self.chatView.frame.size.height += sendingView.frame.size.height-size.height

        }

    }
    
    
    
    @objc func tableViewTappedDown(){
        dismissKeyboard()//will dismiss keyboard when tap inside chat view
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (sections.object(at: section) as! section).amt
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //set up post bubble
        let cell = ChatMessageCell(style: .default, reuseIdentifier: "cell")
        var startIndex = 0
        cell.backgroundColor = .clear
        for var i in 0..<indexPath.section{
            startIndex += (sections.object(at: i) as! section).amt!
        }
        if chat.posts.count > startIndex+indexPath.item{
            //set up text or content based on what type of post
            let post = chat.posts[startIndex+indexPath.item] as! Post
            if let place = post.place as? String{
                cell.textView.text = post.text
                setupCell(cell, post: post, hasPlace: false, index: startIndex+indexPath.item)
            }else{
                cell.textView.text = (post.place as! GMSPlace).name
                setupCell(cell, post: post, hasPlace: true, index: startIndex+indexPath.item)
            }
            //set up width according to content
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
        //set up height according to content
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
        //set up header for each individual date, posts within that date will be under it
        let text = (sections.object(at: section) as! section).date!
        let separatedDate = text.split(separator: "-")
        let month = months[Int(separatedDate[1])!-1]
        
        let label = UILabel()
        
        label.backgroundColor = .clear
        label.textColor = .black
        label.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 50)
        label.textColor = .black
        label.font = UIFont(name: "Arial", size: 10)
        label.textColor = lightGray
        label.text = "\(month) \(separatedDate[2]), \(separatedDate[0])"
        label.textAlignment = .center
        return label
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    
    fileprivate func setupCell(_ cell: ChatMessageCell, post: Post, hasPlace:Bool, index:Int) {
        //set up profile picture
        if post.profileId != FirebaseHelper.personal.userId {
            if let iconString = profileIcons.object(forKey: post.profileId) as? String{
                let data = Data(base64Encoded: iconString, options: .ignoreUnknownCharacters)
                cell.profileImageView.image = UIImage(data:data!)
            }
        }
        
        //set up image if there is one
        if post.image != ""{
            loadImageUsingUrlString(post.image, image: { (image) in
                cell.messageImageView.image = image
                
            })
            cell.button.frame.size = (cell.imageView?.frame.size)!
            cell.button.tag = index
            cell.button.addTarget(self, action: #selector(imageTapped(sender:)), for: .touchUpInside)
        }
        //change location and color based on who sent, modify to a "link" if place is contained
        if post.profileId == FirebaseHelper.personal.userId {
            //outgoing green
            cell.bubbleView.backgroundColor = darkBgColor
            cell.textView.textColor = UIColor.white
            if let place = post.place as? GMSPlace{
                
                let string = NSAttributedString(string: cell.textView.text!, attributes: [NSAttributedStringKey.underlineStyle:NSUnderlineStyle.styleSingle.rawValue, NSAttributedStringKey.strokeColor:darkGray,NSAttributedStringKey.font:cell.textView.font])
                cell.textView.attributedText = string
                
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
                let string = NSAttributedString(string: cell.textView.text!, attributes: [NSAttributedStringKey.underlineStyle:NSUnderlineStyle.styleSingle.rawValue, NSAttributedStringKey.strokeColor:blue,NSAttributedStringKey.font:cell.textView.font])
                
                cell.textView.attributedText = string
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


