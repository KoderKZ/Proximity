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
class AddViewController:UIViewController,UITableViewDelegate,UITableViewDataSource{
    @IBOutlet weak var chatNameTextField: UITextField!
    @IBOutlet weak var createChatButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    var isFriends:Bool!
    var tableView:UITableView!
    var names = NSMutableDictionary()
    var sortedNames = NSMutableArray()
    var images = NSMutableArray()
    var sentRequests = NSMutableArray()
    let fuse = Fuse()
    override func viewDidLoad() {
        super.viewDidLoad()
        createChatButton.layer.borderColor = UIColor.black.cgColor
        createChatButton.layer.borderWidth = 1
        createChatButton.layer.cornerRadius = 5
        createChatButton.addTarget(self, action: #selector(createChatTapped), for: .touchUpInside)
        createChatButton.isUserInteractionEnabled = true
        
        let border = CALayer()
        border.frame = CGRect(x: 0, y: chatNameTextField.frame.size.height, width: self.view.frame.size.width-(chatNameTextField.frame.origin.x*2), height: 1)
        border.backgroundColor = UIColor.black.cgColor
        chatNameTextField.layer.addSublayer(border)
        
        tableView = UITableView(frame: CGRect(x: self.view.frame.size.width/14, y: chatNameTextField.frame.origin.y+chatNameTextField.frame.size.height*1.5, width: self.view.frame.size.width/7*6, height: self.view.frame.size.height/3*2))
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        
        chatNameTextField.addTarget(self, action: #selector(updateSortedNames), for: .editingChanged)
        chatNameTextField.delegate = self
        self.hideKeyboardWhenTappedAround()
        
        if isFriends{
            createChatButton.alpha = 0
            titleLabel.text = "Add Friends"
            userAdded()
        }else{
            chatAdded()
        }
    }

    func chatAdded(){
        FirebaseHelper.ref.child("chatNames").observeSingleEvent(of: .value) { (snapshot) in
            if let dict = snapshot.value as? NSDictionary{
                self.names = dict as! NSMutableDictionary

            }
        }
    }
    
    func userAdded(){
        FirebaseHelper.ref.child("names").observe(.childAdded) { (snapshot) in
            if let value = snapshot.value as? String{
                if let key = snapshot.key as? String{
                    self.names.addEntries(from: [key:value])
                    for var i in 0..<self.names.count{
                        let id = self.names.object(forKey: self.names.allKeys[i]) as! String
                        FirebaseHelper.ref.child("users").child(id).observeSingleEvent(of: .value, with: { (user) in
                            if let dict = user.value as? NSDictionary{
                                let image = UIImage(data: Data(base64Encoded: dict["icon"] as! String, options: .ignoreUnknownCharacters)!)
                                self.images.add(image!)
                                
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
    
    @objc func createChatTapped() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "CreateChatViewController")
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if !isFriends{
            return sortedNames.count
        }else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !isFriends{
            return (names[sortedNames[section]] as! NSArray).count
        }else{
            return sortedNames.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")

        if !isFriends{
            let chatArray = NSMutableArray()
            for var chat in FirebaseHelper.personal.chats{
                chatArray.add((chat as! Chat).id)
            }
            cell.textLabel?.text = sortedNames.object(at: indexPath.section) as? String
            cell.backgroundColor = .clear
            if !chatArray.contains(((names[sortedNames[indexPath.section]] as! NSArray).object(at: indexPath.row) as! String)){
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
    
    @objc func acceptRequest(sender:UIButton){
        var finished = false
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
        for var i in 0..<names.count{
            if sender.title(for: .normal) == names.allKeys[i] as! String{
                nameIndex == i
            }
        }
        let id = (names.object(forKey: sortedNames.object(at: nameIndex) as! String) as! NSArray)[sender.tag] as! String
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
                }else{
                    sender.setTitle("Closed", for: .normal)
                }
            }
        }
    }
    
    @objc func updateSortedNames(){
        if chatNameTextField.text != ""{
            let pattern = fuse.createPattern(from: chatNameTextField.text!)
            let scores = NSMutableDictionary()
            sortedNames.removeAllObjects()
            for var i in 0..<names.allKeys.count{
                let key = names.allKeys[i]
                let value = names.object(forKey: key)
                let result = fuse.search(pattern, in: key as! String)
                if let score = (result?.score){
                    scores.addEntries(from: ["\(score)":key as! String])
                }
            }
            let sortedScores = Array(scores.allKeys).sorted(by: ascending)
            for var score in sortedScores{
                if Double(score as! String)! < 0.4{
                    sortedNames.add(scores.object(forKey: score)!)
                }
            }
            
        }else{
            sortedNames.removeAllObjects()
        }
        tableView.reloadData()
    }
    
    func ascending(value1: Any, value2: Any) -> Bool {
        return Double(value1 as! String)! < Double(value2 as! String)!
    }
    
    
    
    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        textField.resignFirstResponder()
        
        tableView.reloadData()
        return false
    }
    
    
}
