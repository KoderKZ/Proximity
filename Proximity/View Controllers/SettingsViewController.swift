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
    var chatViewController:ChatViewController!
    override func viewDidLoad() {
        chatViewController = self.navigationController?.viewControllers[(navigationController?.viewControllers.count)!-2] as! ChatViewController
        //sync to saved settings of chat
        joinTypeSegment.selectedSegmentIndex = chatViewController.chat.joinType
        members = chatViewController.members
        //set up views

        
        
        backButton.adjustsImageWhenHighlighted = false
        
        let border = CALayer()
        border.frame = CGRect(x: self.view.frame.size.width/6, y: titleBar.frame.size.height, width: self.view.frame.size.width*2/3, height: 1)
        border.backgroundColor = UIColor.black.cgColor
        titleBar.layer.addSublayer(border)
        
        chatNameTextField.text = chatViewController.chat.chatName
        let border2 = CALayer()
        border2.frame = CGRect(x: 0, y: chatNameTextField.frame.size.height, width: self.view.frame.size.width-(chatNameTextField.frame.origin.x*2), height: 1)
        border2.backgroundColor = UIColor.black.cgColor
        chatNameTextField.layer.addSublayer(border2)
        
        chatNameTextField.delegate = self
        
        membersTable = UITableView(frame: CGRect(x: joinTypeSegment.frame.origin.x, y: joinTypeSegment.frame.origin.y+joinTypeSegment.frame.size.height*1.5, width: self.view.frame.size.width-(joinTypeSegment.frame.origin.x*2), height: addMembersButton.frame.origin.y-joinTypeSegment.frame.origin.y))
        membersTable.dataSource = self
        membersTable.delegate = self
        self.view.addSubview(membersTable)
        
        addTable = UITableView(frame: CGRect(x: joinTypeSegment.frame.origin.x, y: joinTypeSegment.frame.origin.y+joinTypeSegment.frame.size.height*1.5, width: self.view.frame.size.width-(joinTypeSegment.frame.origin.x*2), height: addMembersButton.frame.origin.y-joinTypeSegment.frame.origin.y))
        addTable.dataSource = self
        addTable.delegate = self
        self.view.addSubview(addTable)
        addTable.alpha = 0
        self.hideKeyboardWhenTappedAround()
    }
    
    @IBAction func leaveTapped(_ sender: Any) {
        FirebaseHelper.personal.chats.remove(chatViewController.chat)
        let chatArray = NSMutableArray()
        for var chat in FirebaseHelper.personal.chats{
            chatArray.add((chat as! Chat).id)
        }
        
        let friendArray = NSMutableArray()
        for var friend in FirebaseHelper.personal.friends{
            friendArray.add((friend as! Profile).userId)
        }
        let selfProfile = Profile(username: FirebaseHelper.personal.username, userId: FirebaseHelper.personal.userId, friends: friendArray, icon: FirebaseHelper.personal.icon, chats: chatArray, latitude: FirebaseHelper.personal.latitude, longitude: FirebaseHelper.personal.longitude)
        FirebaseHelper.ref.child("chats").child("members").child("\(chatViewController.chat.members.index(of: selfProfile))").removeValue()
        FirebaseHelper.ref.child("users").child(FirebaseHelper.personal.userId).child("chats").child("\(FirebaseHelper.personal.chats.index(of: chatViewController.chat))").removeValue()
        self.navigationController?.popViewController(animated: true)
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
        chatViewController.chat = Chat(id: chatViewController.chat.id, chatName: chatNameTextField.text!, joinType: joinTypeSegment.selectedSegmentIndex, members: members, posts:chatViewController.chat.posts)
        self.navigationController?.popViewController(animated: true)
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
        var array:NSArray
        if tableView == membersTable{
            array = members
        }else{
            array = FirebaseHelper.personal.friends
        }
        cell.textLabel?.text = "                    "+(array.object(at: indexPath.row) as! Profile).username
        let imageData = NSData(base64Encoded: (array.object(at: indexPath.row) as! Profile).icon , options: .ignoreUnknownCharacters)
        let imageView = UIImageView(image: UIImage(data: imageData! as Data))
        imageView.frame = CGRect(x: 5, y: 5, width: 50, height: 50)
        imageView.layer.cornerRadius = imageView.frame.size.width/2
        imageView.layer.masksToBounds = true
        cell.contentView.addSubview(imageView)
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
