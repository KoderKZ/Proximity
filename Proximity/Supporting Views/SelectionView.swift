//
//  SelectionView.swift
//  Proximity
//
//  Created by Kevin Zhou on 11/5/17.
//  Copyright © 2017 Kevin Zhou. All rights reserved.
//

import Foundation
import UIKit
class SelectionView:UIView,UITableViewDataSource,UITableViewDelegate{
    var background:UIImageView!
    var selfButton:UIButton!
    var tableView:UITableView!
    var joinChatButton:UIButton!
    var addFriendButton:UIButton!
    override init(frame:CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setUpLabels(cellHeight:CGFloat) {
        //set up all of the labels/buttons
        background = UIImageView(image: UIImage(named: "menubackground"))
        background.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        let border = CALayer()
        border.frame = CGRect(x: background.frame.size.width, y: 0, width: 1, height: self.frame.size.height)
        border.backgroundColor = UIColor.black.cgColor
        background.layer.addSublayer(border)
        background.isUserInteractionEnabled = true
        addSubview(background)
        
        tableView = UITableView(frame: CGRect(x: 0, y: 0, width: background.frame.size.width, height: background.frame.size.height))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.reloadData()
        background.addSubview(tableView)
        
        selfButton = UIButton(frame: CGRect(x: 0, y: background.frame.size.height-cellHeight, width: background.frame.size.width, height: cellHeight))
        selfButton.setTitle("                    "+FirebaseHelper.personal.username, for: .normal)
        selfButton.setTitleColor(.black, for: .normal)
        selfButton.contentHorizontalAlignment = .left
        selfButton.titleLabel?.font = UIFont(name: "Raleway", size: UIFont.systemFontSize)
        background.addSubview(selfButton)
        
        let data = Data(base64Encoded: FirebaseHelper.personal.icon, options: .ignoreUnknownCharacters)
        let image = UIImage(data: data!)
        let imageView = UIImageView(image: image)
        imageView.frame.size = CGSize(width: selfButton.frame.size.height*3/4, height: selfButton.frame.size.height*3/4)
        imageView.layer.cornerRadius = imageView.frame.size.width/2
        imageView.layer.borderColor = UIColor.black.cgColor
        imageView.layer.borderWidth = 1
        imageView.layer.masksToBounds = true
        imageView.frame.origin = CGPoint(x: selfButton.frame.size.height/8, y: selfButton.frame.size.height/2-imageView.frame.size.height/2)
        
        selfButton.addSubview(imageView)
        
        let border2 = CALayer()
        border2.frame = CGRect(x: 0, y: 0, width: selfButton.frame.size.width, height: 1)
        border2.backgroundColor = UIColor.black.cgColor
        selfButton.layer.addSublayer(border2)
    }
    
    
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return FirebaseHelper.personal.chats.count+1
        }else{
            return FirebaseHelper.personal.friends.count+1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "selectionCell")
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: background.frame.size.width, height: 60))
        button.backgroundColor = .clear
        button.tag = indexPath.row
        if indexPath.section == 0{
            if indexPath.row == FirebaseHelper.personal.chats.count{
                cell.textLabel?.text = "Join Chat"
                joinChatButton = button
                joinChatButton.backgroundColor = .clear
                cell.contentView.addSubview(joinChatButton)
            }else{
                cell.textLabel?.text = (FirebaseHelper.personal.chats.object(at: indexPath.row) as! Chat).chatName
                cell.contentView.addSubview(button)
            }
            
        }else{
            if indexPath.row == FirebaseHelper.personal.friends.count{
                cell.textLabel?.text = "Add Friends"
                addFriendButton = UIButton(frame: CGRect(x: 0, y: 0, width: background.frame.size.width, height: 60))
                addFriendButton.backgroundColor = .clear
                cell.contentView.addSubview(addFriendButton)
            }else{
                button.setTitle("                    "+(FirebaseHelper.personal.friends.object(at: indexPath.row) as! Profile).username, for: .normal)
                button.contentHorizontalAlignment = .left
                button.contentVerticalAlignment = .center
                button.backgroundColor = .white
                button.setTitleColor(.black, for: .normal)
                cell.contentView.addSubview(button)
                
                let imageData = NSData(base64Encoded: (FirebaseHelper.personal.friends.object(at: indexPath.row) as! Profile).icon , options: .ignoreUnknownCharacters)
                let imageView = UIImageView(image: UIImage(data: imageData! as Data))
                imageView.frame = CGRect(x: 5, y: 5, width: 50, height: 50)
                imageView.layer.cornerRadius = imageView.frame.size.width/2
                imageView.layer.masksToBounds = true
                cell.contentView.addSubview(imageView)
            }
        }
        
        return cell
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
        }else{
            label.text = "Friends"
        }
        label.backgroundColor = .white
        return label
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
}
