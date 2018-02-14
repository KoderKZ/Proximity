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
    @IBOutlet weak var leaveChatButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleBar: UIView!
    var membersTable:UITableView!
    var members:NSMutableArray!
    var chat:Chat!
    var addArray = NSMutableArray()
    var delegate:SettingsViewControllerDelegate!
    
    @IBOutlet var joinSwitch: UISwitch!
    @IBOutlet var membersTitle: UILabel!
    func setChat(chat:Chat){
        //sync to saved settings of chat
        self.chat = chat
        if chat.joinType == 1{
            joinSwitch.isOn = false
        }
        members = chat.members
        chatNameTextField.isEnabled = false
        //set up views
        
        for var i in 0..<FirebaseHelper.personal.friends.count{
            var isIn = false
            for var j in 0..<members.count{
                if (members[j] as! String) == (FirebaseHelper.personal.friends[i] as! Profile).userId{
                    isIn = true
                }
            }
            if !isIn{
                addArray.add((FirebaseHelper.personal.friends[i] as! Profile).userId)
            }
        }
        
        backButton.adjustsImageWhenHighlighted = false
        
        
        chatNameTextField.text = chat.chatName
        
        chatNameTextField.delegate = self
        
        membersTable = UITableView(frame: CGRect(x: membersTitle.frame.origin.x, y: membersTitle.frame.origin.y+membersTitle.frame.size.height+10, width: self.view.frame.size.width-(membersTitle.frame.origin.x*2), height: self.view.frame.size.height-50-membersTitle.frame.origin.y))
        membersTable.backgroundColor = .clear
        membersTable.bounces = false
        membersTable.dataSource = self
        membersTable.delegate = self
        self.view.addSubview(membersTable)
        
        self.hideKeyboardWhenTappedAround()
        

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
    
    @IBAction func backButtonTapped(_ sender: Any) {
        //go back to chat view controller
        let membersArray = NSMutableArray()
        for var i in members{
            membersArray.add(i as! String)
        }
        var joinType = 1
        if joinSwitch.isOn{
            joinType = 0
        }
        let newchat = Chat(id: chat.id, chatName: chatNameTextField.text!, joinType: joinType, members: membersArray, posts:chat.posts)
        delegate.dismissSettings(chat: newchat)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == membersTable{
            return members.count
        }else{
            return addArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        var array = NSMutableArray()
        if indexPath.section == 0{
            array = members
        }else{
            array = addArray
        }
        
        FirebaseHelper.ref.child("users").child(array.object(at: indexPath.row) as! String).observeSingleEvent(of: .value) { (snapshot) in
            if let user = (snapshot.value as? NSDictionary){
                cell.textLabel?.text = "                    "+(user["username"] as! String)

                let imageData = NSData(base64Encoded: user["icon"] as! String , options: .ignoreUnknownCharacters)
                let imageView = UIImageView(image: UIImage(data: imageData! as Data))
                imageView.frame = CGRect(x: 5, y: 5, width: 50, height: 50)
                imageView.layer.cornerRadius = imageView.frame.size.width/2
                imageView.layer.masksToBounds = true
                cell.contentView.addSubview(imageView)
                
                if indexPath.section == 1{
                    if !self.members.contains(FirebaseHelper.personal.friends.object(at: indexPath.row)){
                        let button = UIButton(frame: cell.frame)
                        button.backgroundColor = .clear
                        button.tag = indexPath.row
                        button.addTarget(self, action: #selector(self.buttonTapped(sender:)), for: .touchUpInside)
                        cell.contentView.addSubview(button)
                        
                        let width = cell.frame.size.height/3*2
                        let addCircle = UIImageView(frame: CGRect(x: cell.frame.size.width-width*2, y: 30-width/2, width: width, height: width))
                        addCircle.image = UIImage(named:"addButton")
                        cell.contentView.addSubview(addCircle)
                    }
                }
            }
        }
        if indexPath.section == 0 && indexPath.row == members.count-1{
            let border = CALayer()
            border.frame = CGRect(x: 0, y: 60, width: cell.frame.size.width, height: 2)
            border.backgroundColor = UIColor.black.cgColor
            cell.layer.addSublayer(border)
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    @objc func buttonTapped(sender:UIButton) {

        if !self.members.contains(FirebaseHelper.personal.friends.object(at: sender.tag)){
            self.members.add(FirebaseHelper.personal.friends.object(at: sender.tag))
            addArray.removeObject(at: sender.tag)
        }
        self.membersTable.reloadData()
    }

    
}

protocol SettingsViewControllerDelegate {
    func dismissSettings(chat:Chat)
    func leftChat()
}
