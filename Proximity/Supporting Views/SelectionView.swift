//
//  SelectionView.swift
//  Proximity
//
//  Created by Kevin Zhou on 11/5/17.
//  Copyright © 2017 Kevin Zhou. All rights reserved.
//

import Foundation
import UIKit
import GuillotineMenu
class SelectionView:UIViewController,UITableViewDataSource,UITableViewDelegate{
    
    var selfButton:UIButton!
    var tableView:UITableView!
    var joinChatButton:UIButton!
    var addFriendButton:UIButton!
    fileprivate lazy var presentationAnimator = GuillotineTransitionAnimation()
    @IBOutlet weak var menuButton: UIButton!
    
    var delegate:SelectionViewControllerDelegate?
    
    override func viewWillLayoutSubviews() {
        self.view.backgroundColor = .white
    }
    
    override func viewDidLoad() {
        setUpLabels(cellHeight: 60)
        
        self.tableView.reloadData()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.resetSelectionViewButtons()

    }
    
    func resetSelectionViewButtons(){
        for var i in 0..<FirebaseHelper.personal.chats.count{
            let cell = self.tableView.cellForRow(at: IndexPath(item: i, section: 0))
            (cell?.contentView.subviews[1] as! UIButton).addTarget(self, action: #selector(chatTapped(sender:)), for: .touchUpInside)//set tap chat gesture
        }
        for var i in 0..<FirebaseHelper.personal.friends.count{
            let cell = self.tableView.cellForRow(at: IndexPath(item: i, section: 1))
            (cell?.contentView.subviews[1] as! UIButton).addTarget(self, action: #selector(moveToProfileViewController(sender:)), for: .touchUpInside)//set tap chat gesture
        }
        self.joinChatButton.tag = 0
        self.addFriendButton.tag = 1
        self.joinChatButton.addTarget(self, action: #selector(moveToAddViewController(sender:)), for: .touchUpInside)
        self.addFriendButton.addTarget(self, action: #selector(moveToAddViewController(sender:)), for: .touchUpInside)
        self.selfButton.addTarget(self, action: #selector(moveToSelfProfile), for: .touchUpInside)
    }
    
    func setUpLabels(cellHeight:CGFloat) {
        //set up all of the labels/buttons
        
        
        tableView = UITableView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height), style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.backgroundColor = .clear
        tableView.bounces = false
        tableView.reloadData()
        self.view.insertSubview(tableView, at: 0)
        
        selfButton = UIButton(frame: CGRect(x: 0, y: self.view.frame.size.height-cellHeight, width: self.view.frame.size.width, height: cellHeight))
        selfButton.setTitle("                    "+FirebaseHelper.personal.username, for: .normal)
        selfButton.backgroundColor = .white
        selfButton.setTitleColor(.black, for: .normal)
        selfButton.contentHorizontalAlignment = .left
        selfButton.titleLabel?.font = UIFont(name: "Raleway", size: UIFont.systemFontSize)
        self.view.insertSubview(selfButton, at: 1)
        
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
    
    @IBAction func menuButtonTapped(_ sender: Any) {
        delegate?.didDismiss()
    }
    
    
    @objc func chatTapped(sender:UIButton){
        //change chats

        let chat = FirebaseHelper.personal.chats.object(at: sender.tag) as! Chat
//        let chatVc = presentingViewController as! ChatViewController
//        chatVc.chat = chat
//        chatVc.chat.posts.removeAllObjects()
//        chatVc.chatNameLabel.text = chat.chatName
//        chatVc.sections = NSMutableArray()
//        FirebaseHelper.ref.removeObserver(withHandle: chatVc.postsObserver!)
//        FirebaseHelper.ref.removeObserver(withHandle: chatVc.membersObserver!)
//        chatVc.fetchPosts(chatId: chat.id)
//        chatVc.fetchMembers(chatId: chat.id)
//        chatVc.chatView.reloadData()
//
//        chatVc.modalPresentationStyle = .custom
//        chatVc.transitioningDelegate = self
//
//        presentationAnimator.animationDelegate = chatVc as? GuillotineAnimationDelegate
//        presentationAnimator.supportView = menuButton
//        presentationAnimator.presentButton = sender
//
        delegate?.chatTapped(_chat: chat)
        
//        StoreViewed.sharedInstance.addViewed(id: chat.id)
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
    @objc func moveToAddViewController(sender:UIButton){
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "AddViewController") as! AddViewController
        if sender.tag == 0{
            vc.isFriends = false
        }else{
            vc.isFriends = true
        }
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
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return FirebaseHelper.personal.chats.count+1
        }else{
            return FirebaseHelper.personal.friends.count+1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "selectionCell")
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 60))
        button.backgroundColor = .clear
        button.tag = indexPath.row
        cell.textLabel?.textAlignment = .right
        if indexPath.section == 0{
            if indexPath.row == FirebaseHelper.personal.chats.count{
                cell.textLabel?.text = "Join Chat"
                joinChatButton = button
                joinChatButton.backgroundColor = .clear
                joinChatButton.contentHorizontalAlignment = .right
                cell.contentView.addSubview(joinChatButton)
            }else{
                cell.contentView.addSubview(button)
                let amt = StoreViewed.sharedInstance.getNotViewed(id: (FirebaseHelper.personal.chats.object(at: indexPath.row) as! Chat).id)
                if amt != 0{
                    let notCircle = UILabel()
                    notCircle.frame = CGRect(x: cell.frame.size.width-50, y: cell.frame.size.height/2-notCircle.frame.size.height/2, width: 25, height: 25)
                    notCircle.backgroundColor = .red
                    notCircle.text = "\(amt)"
                    notCircle.layer.cornerRadius = notCircle.frame.size.width/2
                    notCircle.layer.masksToBounds = true
                    cell.contentView.addSubview(notCircle)
                }
                cell.textLabel?.text = (FirebaseHelper.personal.chats.object(at: indexPath.row) as! Chat).chatName+"                        "
            }
            
        }else{
            if indexPath.row == FirebaseHelper.personal.friends.count{
                cell.textLabel?.text = "Add Friends"
                addFriendButton = UIButton(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 60))
                addFriendButton.backgroundColor = .clear
                addFriendButton.contentHorizontalAlignment = .right
                cell.contentView.addSubview(addFriendButton)
            }else{
                cell.textLabel?.text = "                                          "+(FirebaseHelper.personal.friends.object(at: indexPath.row) as! Profile).username
                button.contentHorizontalAlignment = .right
                button.contentVerticalAlignment = .center
                button.backgroundColor = .white
                button.setTitleColor(.black, for: .normal)
                cell.contentView.addSubview(button)
                
                let imageData = NSData(base64Encoded: (FirebaseHelper.personal.friends.object(at: indexPath.row) as! Profile).icon , options: .ignoreUnknownCharacters)
                let imageView = UIImageView(image: UIImage(data: imageData! as Data))
                imageView.frame = CGRect(x: self.view.frame.size.width-60, y: 5, width: 50, height: 50)
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
        let view = UIView()
        view.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 60)
        let label = UILabel(frame: CGRect(x: -20, y: 0, width: tableView.frame.size.width, height: 60))
        label.font = UIFont(name: "Arial", size: UIFont.systemFontSize+10)
        label.textColor = .black
        if section == 0{
            label.text = "Chats"
        }else{
            label.text = "Friends"
            
        }
        label.textAlignment = .right
        let border = CALayer()
        border.frame = CGRect(x: 0, y: view.frame.size.height, width: view.frame.size.width, height: 2)
        border.backgroundColor = UIColor.black.cgColor
        view.layer.addSublayer(border)
        
        view.addSubview(label)
        label.backgroundColor = .clear
        return view
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
}

protocol SelectionViewControllerDelegate{
    func didDismiss()
    func chatTapped(_chat:Chat)
}

//extension SelectionView: UIViewControllerTransitioningDelegate {
//    
//    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        presentationAnimator.mode = .presentation
//        return presentationAnimator
//    }
//    
//    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        presentationAnimator.mode = .dismissal
//        return presentationAnimator
//    }
//}

