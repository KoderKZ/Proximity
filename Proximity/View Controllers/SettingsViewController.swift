//
//  SettingsViewController.swift
//  Proximity
//
//  Created by Kevin Zhou on 11/5/17.
//  Copyright © 2017 Kevin Zhou. All rights reserved.
//

import Foundation
import UIKit
class SettingsViewController: UIViewController,UITableViewDelegate,UITableViewDataSource{
    @IBOutlet weak var chatNameTextField: UITextField!
    @IBOutlet weak var addMembersButton: UIButton!
    @IBOutlet weak var leaveChatButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var joinTypeSegment: UISegmentedControl!
    @IBOutlet weak var titleBar: UIView!
    var membersTable:UITableView!
    var addTable:UITableView!
    var members:NSMutableArray!
    var chat:Chat!
    var addArray = NSMutableArray()
    var delegate:SettingsViewControllerDelegate!
    
    func setChat(chat:Chat){
        //sync to saved settings of chat
        self.chat = chat
        joinTypeSegment.selectedSegmentIndex = chat.joinType
        members = chat.members
        chatNameTextField.isEnabled = false
        //set up views
        
        for var i in 0..<members.count{
            var isIn = false
            for var j in 0..<FirebaseHelper.personal.friends.count{
                if (members[i] as! String) == (FirebaseHelper.personal.friends[j] as! Profile).userId{
                    isIn = true
                }
            }
            if !isIn{
                addArray.add(members[i])
            }
        }
        
        backButton.adjustsImageWhenHighlighted = false
        
        
        chatNameTextField.text = chat.chatName
        let border2 = CALayer()
        border2.frame = CGRect(x: 0, y: chatNameTextField.frame.size.height, width: self.view.frame.size.width-(chatNameTextField.frame.origin.x*2), height: 1)
        border2.backgroundColor = UIColor.black.cgColor
        chatNameTextField.layer.addSublayer(border2)
        
        chatNameTextField.delegate = self
        
        membersTable = UITableView(frame: CGRect(x: joinTypeSegment.frame.origin.x, y: joinTypeSegment.frame.origin.y+joinTypeSegment.frame.size.height*2, width: self.view.frame.size.width-(joinTypeSegment.frame.origin.x*2), height: addMembersButton.frame.origin.y-joinTypeSegment.frame.origin.y-25), style: .grouped)
        membersTable.backgroundColor = .clear
        membersTable.bounces = false
        membersTable.dataSource = self
        membersTable.delegate = self
        self.view.addSubview(membersTable)
        
        addTable = UITableView(frame: CGRect(x: joinTypeSegment.frame.origin.x, y: joinTypeSegment.frame.origin.y+joinTypeSegment.frame.size.height*2, width: self.view.frame.size.width-(joinTypeSegment.frame.origin.x*2), height: addMembersButton.frame.origin.y-joinTypeSegment.frame.origin.y-25), style: .grouped)
        addTable.backgroundColor = .clear
        addTable.bounces = false
        addTable.dataSource = self
        addTable.delegate = self
        self.view.addSubview(addTable)
        addTable.alpha = 0
        self.hideKeyboardWhenTappedAround()
        
        joinTypeSegment.tintColor = darkBgColor

    }
    
    @IBAction func leaveTapped(_ sender: Any) {
        var indexChat:Int = 0
        for var i in 0..<FirebaseHelper.personal.chats.count{
            if (FirebaseHelper.personal.chats[i] as! Chat).id == chat.id{
                indexChat = i
            }
        }
        var indexMember:Int = 0
        for var i in 0..<chat.members.count{
            if FirebaseHelper.personal.userId == chat.members[i] as! String{
                indexMember = i
            }
        }
        FirebaseHelper.personal.chats.removeObject(at: indexChat)
        
        FirebaseHelper.ref.child("users").child(FirebaseHelper.personal.userId).child("chats").removeValue()
        FirebaseHelper.ref.child("chats").child("\(chat.id)").child("members").removeValue()
        
        FirebaseHelper.ref.child("users").child(FirebaseHelper.personal.userId).child("chats").observeSingleEvent(of: .value) { (snapshot1) in
            if let array = snapshot1.value as? NSMutableArray{
                array.removeObject(at: indexChat)
                let dict = NSMutableDictionary()
                for var i in 0..<array.count{
                    dict.addEntries(from: ["\(i)":array[i]])
                }
                snapshot1.ref.updateChildValues(dict as! [AnyHashable:Any])
                
            }
            FirebaseHelper.ref.child("chats").child("\(self.chat.id)").child("members").observeSingleEvent(of: .value) { (snapshot2) in
                if let array = snapshot2.value as? NSMutableArray{
                    array.removeObject(at: indexMember)
                    let dict = NSMutableDictionary()
                    for var i in 0..<array.count{
                        dict.addEntries(from: ["\(i)":array[i]])
                    }
                    snapshot2.ref.updateChildValues(dict as! [AnyHashable:Any])
                    self.chat = nil
                    self.delegate.leftChat()
                }else{
                    self.delegate.leftChat()
                }
            }
        }
        
    }
    
    @IBAction func addMembersTapped(_ sender: Any) {
        if addMembersButton.titleLabel?.text == "Add Members"{
            UIView.animate(withDuration: 0.5) {
                self.addTable.alpha = 1
            }
            addMembersButton.setTitle("Cancel", for: .normal)
            addMembersButton.setTitleColor(.red, for: .normal)
        }else{
            UIView.animate(withDuration: 0.5) {
                self.addTable.alpha = 0
            }
            addMembersButton.setTitle("Add Members", for: .normal)
            addMembersButton.setTitleColor(.black, for: .normal)
        }
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        //go back to chat view controller
        let membersArray = NSMutableArray()
        for var i in members{
            membersArray.add(i as! String)
        }
        
        let newchat = Chat(id: chat.id, chatName: chatNameTextField.text!, joinType: joinTypeSegment.selectedSegmentIndex, members: membersArray, posts:chat.posts)
        delegate.dismissSettings(chat: newchat)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == membersTable{
            return members.count
        }else{
            return FirebaseHelper.personal.friends.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        var array = NSMutableArray()
        if tableView == membersTable{
            array = members
        }else{
            for var i in FirebaseHelper.personal.friends{
                array.add((i as! Profile).userId)
            }
        }
        
        FirebaseHelper.ref.child("users").child(members.object(at: indexPath.row) as! String).observeSingleEvent(of: .value) { (snapshot) in
            if let user = (snapshot.value as? NSDictionary){
                cell.textLabel?.text = "                    "+(user["username"] as! String)

                let imageData = NSData(base64Encoded: user["icon"] as! String , options: .ignoreUnknownCharacters)
                let imageView = UIImageView(image: UIImage(data: imageData! as Data))
                imageView.frame = CGRect(x: 5, y: 5, width: 50, height: 50)
                imageView.layer.cornerRadius = imageView.frame.size.width/2
                imageView.layer.masksToBounds = true
                cell.contentView.addSubview(imageView)
            }
        }

        if tableView == addTable{
            if !members.contains(FirebaseHelper.personal.friends.object(at: indexPath.row)){
                let button = UIButton(frame: cell.frame)
                button.backgroundColor = .clear
                button.tag = indexPath.row
                button.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
                cell.contentView.addSubview(button)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel(frame: CGRect(x: 5, y: 5, width: 60, height: 60))
        label.backgroundColor = .white
        if tableView == membersTable{
            label.text = "Members"
        }else{
            label.text = "Add Members"
        }
        return label
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    @objc func buttonTapped(sender:UIButton) {
        UIView.animate(withDuration: 0.5) {
            self.addTable.alpha = 0
        }
        addMembersButton.setTitleColor(.black, for: .normal)
        addMembersButton.setTitle("Add Members", for: .normal)
        if !self.members.contains(FirebaseHelper.personal.friends.object(at: sender.tag)){
            self.members.add(FirebaseHelper.personal.friends.object(at: sender.tag))
        }
        self.membersTable.reloadData()
    }

    
}

protocol SettingsViewControllerDelegate {
    func dismissSettings(chat:Chat)
    func leftChat()
}
