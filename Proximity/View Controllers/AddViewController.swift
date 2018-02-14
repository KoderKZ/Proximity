//
//  AddViewController.swift
//  Proximity
//
//  Created by Kevin Zhou on 11/5/17.
//  Copyright © 2017 Kevin Zhou. All rights reserved.
//

import Foundation
import UIKit
import Fuse
class AddViewController:UIViewController,UITableViewDelegate,UITableViewDataSource,SelectionViewDelegate{
    @IBOutlet weak var chatNameTextField: UITextField!
    @IBOutlet weak var titleLabel: UILabel!
    var isFriends:Bool = false
    var tableView:UITableView!
    var names = NSMutableDictionary()
    var chats = NSMutableDictionary()
    var sortedNames = NSMutableArray()
    var images = NSMutableArray()
    var sentRequests = NSMutableArray()
    let fuse = Fuse()
    var observer:UInt!
    var selectionView:SelectionView!
    var indicator:UIView!
    @IBOutlet var titleBar: UIView!
    
    @IBOutlet var chatsButton: UIButton!
    @IBOutlet var peopleButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        let border = CALayer()
        border.frame = CGRect(x: 0, y: titleBar.frame.size.height, width: view.frame.size.width, height: 2)
        border.backgroundColor = UIColor.black.cgColor
        titleBar.layer.addSublayer(border)
        
        chatAdded()
        userAdded()
        
        tableView = UITableView(frame: CGRect(x: 0, y: chatsButton.frame.origin.y+chatsButton.frame.size.height, width: self.view.frame.size.width, height: self.view.frame.size.height-(chatsButton.frame.origin.y+chatsButton.frame.size.height*1.5)), style:.grouped)
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        
        chatNameTextField.addTarget(self, action: #selector(updateSortedNames), for: .editingChanged)
        chatNameTextField.delegate = self
//        self.hideKeyboardWhenTappedAround()
        
        indicator = UIView(frame: CGRect(x: chatsButton.frame.origin.x, y: chatsButton.frame.origin.y+chatsButton.frame.size.height, width: chatsButton.frame.size.width, height: 1))
        indicator.backgroundColor = darkBgColor
        self.view.addSubview(indicator)
        
        chatsButton.setTitleColor(darkBgColor, for: .normal)
        peopleButton.setTitleColor(darkBgColor, for: .normal)
        
        let height:CGFloat = 75
        let width = self.view.frame.size.width-30
        selectionView = SelectionView(frame: CGRect(x: 15, y: self.view.frame.size.height-15-height, width: width, height: height))
        selectionView.delegate = self
        selectionView.setTab(tab: 2)
        
        self.view.addSubview(selectionView)
        
        tableView.allowsSelection = true
    }
    
    func selectionTapped(tag: Int) {
        let selectionVC = self.navigationController?.viewControllers[1] as! SelectionViewController
        
        if tag < 2{
        self.navigationController?.popViewController(animated: false)
            selectionVC.tab = tag
        }else if tag == 3{
            let createVC = self.storyboard?.instantiateViewController(withIdentifier: "CreateChatViewController") as! CreateChatViewController
            self.navigationController?.viewControllers = [(self.navigationController?.viewControllers[0])!, selectionVC, createVC]
        }else if tag == 4{
            let profileVC = self.storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
            profileVC.homeMenu = true
            let chatArray = NSMutableArray()
            for var chat in FirebaseHelper.personal.chats{
                chatArray.add((chat as! Chat).id)
            }
            
            let friendArray = NSMutableArray()
            for var friend in FirebaseHelper.personal.friends{
                friendArray.add((friend as! Profile).userId)
            }
            let selfProfile = Profile(username: FirebaseHelper.personal.username, userId: FirebaseHelper.personal.userId, friends: friendArray, icon: FirebaseHelper.personal.icon, chats: chatArray, latitude: FirebaseHelper.personal.latitude, longitude: FirebaseHelper.personal.longitude)
            profileVC.setProfiles(profile: selfProfile, profiles: friendArray)
            self.navigationController?.viewControllers = [(self.navigationController?.viewControllers[0])!, selectionVC, profileVC]
        }
    }


    func chatAdded(){
        FirebaseHelper.ref.child("chatNames").observe(.childAdded) { (snapshot) in
            if let value = snapshot.value as? String{
                if let key = snapshot.key as? String{
                    let modifiedKey = key.substring(to: key.index(key.endIndex, offsetBy: -4))+"#"+key.substring(from: key.index(key.endIndex, offsetBy: -4))
                    self.chats.addEntries(from: [modifiedKey:value])
                }
            }
        }
    }
    
    func userAdded(){
        observer = FirebaseHelper.ref.child("names").observe(.childAdded) { (snapshot) in
            if let value = snapshot.value as? String{
                if let key = snapshot.key as? String{
                    self.names.addEntries(from: [key:value])
                    for var i in 0..<self.names.count{
                        let id = self.names.object(forKey: self.names.allKeys[i]) as! String
                        FirebaseHelper.ref.child("users").child(id).observeSingleEvent(of: .value, with: { (user) in
                            if let dict = user.value as? NSDictionary{
                                let image = UIImage(data: Data(base64Encoded: dict["icon"] as! String, options: .ignoreUnknownCharacters)!)
                                    self.images.add(image!)

                                self.updateSortedNames()

                                if let requests = dict["friendRequests"] as? NSArray{
                                    if requests.contains(FirebaseHelper.personal.userId){
                                        self.sentRequests.add(value)
                                    }
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismissKeyboard()
    }
    
    func changedType() {
        isFriends = !isFriends
        sortedNames.removeAllObjects()
        if !isFriends{
            if let ob = observer as? UInt{
                FirebaseHelper.ref.removeObserver(withHandle: ob)
            }
        }
        updateSortedNames()
        
    }
    
    @IBAction func chatsTapped(_ sender: Any) {
        changedType()
        UIView.animate(withDuration: 0.25) {
            self.indicator.frame.origin.x = self.chatsButton.frame.origin.x
            self.indicator.frame.size.width = self.chatsButton.frame.size.width
        }
    }
    
    
    @IBAction func peopleTapped(_ sender: Any) {
        changedType()
        UIView.animate(withDuration: 0.25) {
            self.indicator.frame.origin.x = self.peopleButton.frame.origin.x
            self.indicator.frame.size.width = self.peopleButton.frame.size.width
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        dismissKeyboard()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        dismissKeyboard()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")

        if !isFriends{
            let chatArray = NSMutableArray()
            for var chat in FirebaseHelper.personal.chats{
                chatArray.add((chat as! Chat).id)
            }
            cell.textLabel?.text = sortedNames.object(at: indexPath.row) as? String
            cell.backgroundColor = .clear
            if !chatArray.contains(chats.object(forKey: sortedNames.object(at: indexPath.row))){
                let joinChatButton = UIButton(frame: CGRect(x: tableView.frame.size.width-70, y: 0, width: 70, height: 60))
                joinChatButton.setTitle("Add", for: .normal)
                joinChatButton.setTitleColor(.black, for: .normal)
                joinChatButton.tag = indexPath.row
                joinChatButton.addTarget(self, action: #selector(joinChat(sender:)), for: .touchUpInside)
                cell.addSubview(joinChatButton)
            }
        }else{
            let friendArray = NSMutableArray()
            for var friend in FirebaseHelper.personal.friends{
                friendArray.add((friend as! Profile).userId)
            }
            var addFriendButton = UIButton()
            let id = names.object(forKey: names.allKeys[indexPath.row])
            if !friendArray.contains(id) && !sentRequests.contains(id) && id as! String != FirebaseHelper.personal.userId{
                addFriendButton = UIButton(frame: CGRect(x: tableView.frame.size.width-70, y: 0, width: 70, height: 60))
                addFriendButton.setTitle("Add", for: .normal)
                addFriendButton.setTitleColor(.black, for: .normal)
                addFriendButton.tag = indexPath.row
                addFriendButton.addTarget(self, action: #selector(sendRequest(sender:)), for: .touchUpInside)
                if FirebaseHelper.personal.friendRequests.contains(names.object(forKey: sortedNames.object(at: indexPath.row))){
                    addFriendButton.tag = FirebaseHelper.personal.friendRequests.index(of: names.object(forKey: sortedNames.object(at: indexPath.row)))
                    addFriendButton.removeTarget(self, action: #selector(sendRequest(sender:)), for: .touchUpInside)
                    addFriendButton.addTarget(self, action: #selector(acceptRequest(sender:)), for: .touchUpInside)
                }

                cell.contentView.addSubview(addFriendButton)
            }
            cell.textLabel?.text = "                    "+(sortedNames.object(at: indexPath.row) as! String)
            let imageView = UIImageView(image: images.object(at: indexPath.row) as! UIImage)
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
    
    @objc func sendRequest(sender:UIButton){
        let _profile = FirebaseHelper.personal.friends.object(at: sender.tag) as! Profile
        sender.removeFromSuperview()
        FirebaseHelper.ref.child("users").child(_profile.userId).observeSingleEvent(of:.value) { (snapshot) in
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
        sender.removeFromSuperview()
        let _profile = FirebaseHelper.personal.friendRequests.object(at: sender.tag)
        FirebaseHelper.personal.friendRequests.remove(_profile)
        FirebaseHelper.personal.friends.add(_profile)
        FirebaseHelper.ref.child("users").child(FirebaseHelper.personal.userId).child("friendRequests").child("\(sender.tag)").removeValue()
        FirebaseHelper.updatePersonal()
        FirebaseHelper.ref.child("users").child((_profile as! Profile).userId).child("friends").observeSingleEvent(of:.value, with: { (snapshot) in
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
    
    @objc func joinChat(sender:UIButton){
        var nameIndex = 0
        for var i in 0..<chats.count{
            if sender.title(for: .normal) == chats.allKeys[i] as! String{
                nameIndex == i
            }
        }
        sender.setTitle("Wating...", for: .normal)
        let id = (chats.object(forKey: sortedNames.object(at: nameIndex) as! String) as! String)
        let ref = FirebaseHelper.ref.child("chats").child(id)
        ref.observeSingleEvent(of:.value) { (snapshot) in
            if let chat = snapshot.value as? [AnyHashable:Any]{
                if chat["joinType"] as! Int == 0{
                    var membersCount = "0"
                    var members = NSMutableArray()
                    if let membersArr = chat["members"] as? NSMutableArray{
                        membersCount = "\(members.count)"
                        members = membersArr
                    }
                    ref.child("members").updateChildValues([membersCount:FirebaseHelper.personal.userId])
                    var posts = NSMutableArray()
                    let addChat = Chat(id: id, chatName: chat["chatName"] as! String, joinType: chat["joinType"] as! Int, members: members, posts: NSMutableArray())
                    FirebaseHelper.personal.chats.add(addChat)
                    FirebaseHelper.updatePersonal()
                    sender.setTitle("Joined", for: .normal)
                    StoreViewed.sharedInstance.addObserver(chatId: id)
                }else{
                    sender.setTitle("Closed", for: .normal)
                }
            }
        }
    }
    
    @objc func updateSortedNames(){
        if chatNameTextField.text != ""{
            var dict = NSMutableDictionary()
            if isFriends{
                dict = names
            }else{
                dict = chats
            }
            let pattern = fuse.createPattern(from: chatNameTextField.text!)
            let scores = NSMutableDictionary()
            let scoreArray = NSMutableArray()
            sortedNames.removeAllObjects()
            for var i in 0..<dict.allKeys.count{
                let key = dict.allKeys[i]
                let value = dict.object(forKey: key)
                let result = fuse.search(pattern, in: key as! String)
                if let score = (result?.score){
                    scores.addEntries(from: [key as! String:"\(score)"])
                    if !scoreArray.contains("\(score)"){
                        scoreArray.add("\(score)")
                    }
                }
            }
            for var i in 0..<scoreArray.count{
                let score = scoreArray[i]
                if Double(score as! String)! < 0.4{
                    for var i in 0..<scores.allKeys(for: score).count{
                        sortedNames.add(scores.allKeys(for: score)[i] as! String)
                    }
                }
            }
            tableView.reloadData()
        }else{
            sortedNames.removeAllObjects()
        }
        tableView.reloadData()

    }
    
    
    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        textField.resignFirstResponder()
        
        tableView.reloadData()
        return false
    }
    
    
}
