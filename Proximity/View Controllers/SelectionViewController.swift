//
//  SelectionView.swift
//  Proximity
//
import Foundation
import UIKit

class SelectionViewController:UIViewController,UITableViewDataSource,UITableViewDelegate,StoreViewedDelegate,SelectionViewDelegate{

    var tab = 0
    var selectionView:SelectionView!
    var tableView:UITableView!
    var joinChatButton:UIButton!
    var addFriendButton:UIButton!
    
    var chatVC:ChatViewController!
    
    //set up ui
    override func viewWillLayoutSubviews() {
        self.view.backgroundColor = bgColor
    }
    //set up ui
    override func viewDidLoad() {
        
        let signIn = self.storyboard?.instantiateViewController(withIdentifier: "SignInViewController") as! SignInViewController
        self.navigationController?.viewControllers = [signIn, self]
        
        self.view.backgroundColor = darkBgColor
        
        setUpLabels(cellHeight: 60)
        chatVC = storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        
        tableView.backgroundColor = .white
        
        tableView.separatorColor = darkGray
        self.tableView.reloadData()
        
        chatAdded()
        friendAdded()
        
        StoreViewed.sharedInstance.delegate = self
        
        let height:CGFloat = 75
        let width = self.view.frame.size.width-30
        selectionView = SelectionView(frame: CGRect(x: 15, y: self.view.frame.size.height-15-height, width: width, height: height))
        selectionView.delegate = self
        self.view.addSubview(selectionView)
        
    }

    
    func selectionTapped(tag: Int) {//move to vc based on tab tapped
        if tag < 2{
            tab = tag
            tableView.reloadData()
            selectionView.setTab(tab: tag)
        }else if tag == 2{
            let addVC = self.storyboard?.instantiateViewController(withIdentifier: "AddViewController") as! AddViewController
            self.navigationController?.pushViewController(addVC, animated: false)
        }else if tag == 3{
            let createVC = self.storyboard?.instantiateViewController(withIdentifier: "CreateChatViewController") as! CreateChatViewController
            self.navigationController?.pushViewController(createVC, animated: false)
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
            self.navigationController?.pushViewController(profileVC, animated: false)
        }
    }
    
    func changedAmt() {
        tableView.reloadData()
    }
    
    //reloads table view
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
        selectionView.setTab(tab: tab)
    }
    
    //reset buttons
    override func viewDidAppear(_ animated: Bool) {
    }
    
    func chatAdded(){
        //observer for when new chat is added, will be displayed
        FirebaseHelper.ref.child("users").child(FirebaseHelper.personal.userId).child("chats").observe(.childAdded) { (snapshot) in
            if let id = snapshot.value as? String{
                let ids = NSMutableArray()
                for var i in FirebaseHelper.personal.chats{
                    let chat = i as! Chat
                    ids.add(chat.id)
                }
                if !ids.contains(id){
                    FirebaseHelper.ref.child("chats").child(id).observeSingleEvent(of: .value, with: { (chat) in
                        if let dictionary = chat.value as? NSDictionary{
                            var members = NSMutableArray()
                            if let membArr = dictionary["members"] as? NSMutableArray{members = membArr}
                            var posts = NSMutableArray()
                            if let postArr = dictionary["posts"] as? NSMutableArray{posts = postArr}
                            let chat = Chat(id: id, chatName: dictionary["chatName"] as! String, joinType: dictionary["joinType"] as! Int, members: members, posts: posts)
                            FirebaseHelper.personal.chats.add(chat)
                        }
                    })
                }
            }
        }
    }
    func friendAdded(){
        //observer for when new friend is added, will be displayed
        FirebaseHelper.ref.child("users").child(FirebaseHelper.personal.userId).child("friends").observe(.childAdded) { (snapshot) in
            if let id = snapshot.value as? String{
                let ids = NSMutableArray()
                for var i in FirebaseHelper.personal.friends{
                    let chat = i as! Profile
                    ids.add(chat.userId)
                }
                if !ids.contains(id){
                    FirebaseHelper.ref.child("users").child(id).observeSingleEvent(of: .value, with: { (prof) in
                        if let dictionary = prof.value as? NSDictionary{
                        
                            var friends = NSMutableArray()
                            if let friendsArr = dictionary["friends"] as? NSMutableArray{friends = friendsArr}
                            var chats = NSMutableArray()
                            if let chatsArr = dictionary["chats"] as? NSMutableArray{chats = chatsArr}
                            let profile = Profile(username: dictionary["username"] as! String, userId: id, friends: friends, icon: dictionary["icon"] as! String, chats: chats, latitude: dictionary["latitude"] as! Double, longitude: dictionary["longitude"] as! Double)
                            FirebaseHelper.personal.friends.add(profile)
                        }
                    })
                }
            }
        }
    }
    
    
    func setUpLabels(cellHeight:CGFloat) {
        //set up all of the labels/buttons
        tableView = UITableView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height),style:.grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.backgroundColor = .clear
        tableView.bounces = false
        tableView.reloadData()
        self.view.insertSubview(tableView, at: 0)
        

        
    }
    

    @objc func chatTapped(sender:UIButton){
        //change chats

        let chat = FirebaseHelper.personal.chats.object(at: sender.tag) as! Chat
        chatVC = storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        chatVC.chat = chat
        self.navigationController?.pushViewController(chatVC, animated: true)
        
        StoreViewed.sharedInstance.addViewed(id: chat.id)
    }


    @objc func moveToProfileViewController(sender:UIButton){//move to other profile viewer
        for var i in FirebaseHelper.personal.friends{
            let prof = i as! Profile
            if prof.username == sender.currentTitle!.replacingOccurrences(of: " ", with: "") {
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController


                let profile = Profile(username: prof.username, userId: prof.userId, friends: prof.friends, icon: prof.icon, chats: prof.chats, latitude: prof.latitude, longitude: prof.longitude)
                vc.setProfiles(profile: profile, profiles: prof.friends as! NSMutableArray)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    //table view delegates
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tab == 0{
            return FirebaseHelper.personal.chats.count
        }else if tab == 1{
            return FirebaseHelper.personal.friends.count
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "selectionCell")
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 80))
        button.backgroundColor = .clear
        button.tag = indexPath.row
        if tab == 0{//set up chats part of tableview
            cell.textLabel?.text = (FirebaseHelper.personal.chats.object(at: indexPath.row) as! Chat).chatName//chat name text
            cell.contentView.addSubview(button)
            var amt = StoreViewed.sharedInstance.getNotViewed(id: (FirebaseHelper.personal.chats.object(at: indexPath.row) as! Chat).id)

            if amt != 0{//set up notification circles
                let notCircle = UILabel()
                notCircle.frame = CGRect(x: cell.frame.size.width+45, y : cell.frame.size.height/2-2, width: 25, height: 25)
                notCircle.backgroundColor = .red
                if amt > 9{
                    notCircle.text = "9+"
                }else{
                    notCircle.text = "\(amt)"
                }
                notCircle.textAlignment = .center
                notCircle.textColor = .white
                
                
                notCircle.layer.cornerRadius = notCircle.frame.size.width/2
                notCircle.layer.masksToBounds = true
                cell.contentView.addSubview(notCircle)
            }else{
                //arrow image to show its a button
                let arrowImage = UIImageView(frame: CGRect(x: cell.frame.size.width+50, y: cell.frame.size.height/2, width: 7.5, height: 15))
                arrowImage.image = UIImage(named: "rightArrow")
                cell.contentView.addSubview(arrowImage)
            }
            button.addTarget(self, action: #selector(chatTapped(sender:)), for: .touchUpInside)
        }else if tab == 1{//set up friends part of tableview
            button.setTitleColor(.clear, for: .normal)
            button.setTitle((FirebaseHelper.personal.friends.object(at: indexPath.row) as! Profile).username, for: .normal)
            
            let label = UILabel()
            label.text = (FirebaseHelper.personal.friends.object(at: indexPath.row) as! Profile).username
            let size = label.sizeThatFits(CGSize(width:1000,height:1000))

            //profile picture image view
            let imageData = NSData(base64Encoded: (FirebaseHelper.personal.friends.object(at: indexPath.row) as! Profile).icon , options: .ignoreUnknownCharacters)
            let imageView = UIImageView(image: UIImage(data: imageData! as Data))
            imageView.frame = CGRect(x: 5, y: 5, width: 50, height: 50)
            imageView.layer.cornerRadius = imageView.frame.size.width/2
            imageView.layer.masksToBounds = true
            
            label.sizeToFit()
            label.frame.origin.x = imageView.frame.origin.x+60
            label.textAlignment = .center
            label.baselineAdjustment = .alignCenters
            label.frame.origin.y = cell.frame.size.height/2
            
            cell.contentView.addSubview(label)
            cell.contentView.addSubview(button)
            cell.contentView.addSubview(imageView)
            
            //arrow image to show its a button
            let arrowImage = UIImageView(frame: CGRect(x: cell.frame.size.width+50, y: cell.frame.size.height/2, width: 7.5, height: 15))
            arrowImage.image = UIImage(named: "rightArrow")
            cell.contentView.addSubview(arrowImage)
            button.addTarget(self, action: #selector(moveToProfileViewController(sender:)), for: .touchUpInside)
        }
        return cell
    }
    
    
    //headers/heights/sections functions
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()//set up headers to distinguish different tabs
        view.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 60)
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 60))
        label.font = UIFont(name: "Arial", size: UIFont.systemFontSize+10)
        label.textColor = .white
        if tab == 0{
            label.text = "Chat Rooms"
        }else if tab == 1{
            label.text = "Friends"
            
        }
        label.textAlignment = .center
        let border = CALayer()
        border.frame = CGRect(x: 0, y: view.frame.size.height, width: view.frame.size.width, height: 2)
        border.backgroundColor = UIColor.black.cgColor
        view.layer.addSublayer(border)
        
        view.addSubview(label)
        label.backgroundColor = darkBgColor
        return view
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1//will only have one displayed at a time
    }
    
    //dismiss chat vc
    func didDismiss() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
}

