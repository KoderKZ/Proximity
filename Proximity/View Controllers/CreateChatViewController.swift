//
//  CreateChatViewController.swift
//  Proximity
//

import Foundation
import UIKit
class CreateChatViewController:UIViewController,UITableViewDataSource,UITableViewDelegate,SelectionViewDelegate{
    @IBOutlet weak var chatNameTextField: UITextField!
    @IBOutlet weak var createButton: UIButton!
    var membersTable:UITableView!
    var addTable:UITableView!
    let members:NSMutableArray = NSMutableArray()
    let friendsToAdd:NSMutableArray = NSMutableArray()
    var selectionView:SelectionView!
    @IBOutlet var titleBar: UIView!
    @IBOutlet var joinSwitch: UISwitch!
    @IBOutlet var joinLabel: UILabel!
    @IBOutlet var membersTitle: UILabel!
    
    override func viewDidLoad() {//set up ui
        super.viewDidLoad()
        
        let border = CALayer()
        border.frame = CGRect(x: 0, y: titleBar.frame.size.height, width: view.frame.size.width, height: 2)
        border.backgroundColor = UIColor.black.cgColor
        titleBar.layer.addSublayer(border)
        
        let height:CGFloat = 75
        let width = self.view.frame.size.width-30
        selectionView = SelectionView(frame: CGRect(x: 15, y: self.view.frame.size.height-15-height, width: width, height: height))
        selectionView.delegate = self
        selectionView.setTab(tab: 3)
        
        membersTable = UITableView(frame: CGRect(x: joinLabel.frame.origin.x, y: membersTitle.frame.origin.y+membersTitle.frame.size.height+10, width: self.view.frame.size.width-(joinLabel.frame.origin.x*2), height: selectionView.frame.origin.y-membersTitle.frame.origin.y))

        self.view.addSubview(membersTable)
        membersTable.delegate = self
        membersTable.dataSource = self
        
        self.hideKeyboardWhenTappedAround()
        chatNameTextField.delegate = self

        self.view.addSubview(selectionView)
        
        
        membersTable.allowsSelection = false
        
        createButton.isEnabled = false
        
        //set self profile for members table, add all uids to array for members and add portion of table
        let chatArray = NSMutableArray()
        for var chat in FirebaseHelper.personal.chats{
            chatArray.add((chat as! Chat).id)
        }
        
        let friendArray = NSMutableArray()
        for var friend in FirebaseHelper.personal.friends{
            friendArray.add((friend as! Profile).userId)
            friendsToAdd.add(friend)
        }

        let selfProfile = Profile(username: FirebaseHelper.personal.username, userId: FirebaseHelper.personal.userId, friends: friendArray, icon: FirebaseHelper.personal.icon, chats: chatArray, latitude: FirebaseHelper.personal.latitude, longitude: FirebaseHelper.personal.longitude)
        members.add(selfProfile)
    }
    
    func selectionTapped(tag: Int) {//navigate to new vc for each tab
        let selectionVC = self.navigationController?.viewControllers[1] as! SelectionViewController
        if tag < 2{
            self.navigationController?.popViewController(animated: false)
        }else if tag == 2{
            let addVC = self.storyboard?.instantiateViewController(withIdentifier: "AddViewController") as! AddViewController
            self.navigationController?.viewControllers = [(self.navigationController?.viewControllers[0])!, selectionVC, addVC]
        }else if tag == 4{
            let profileVC = self.storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
            profileVC.homeMenu = true
            let friendArray = NSMutableArray()
            for var friend in FirebaseHelper.personal.friends{
                friendArray.add((friend as! Profile).userId)
            }
            profileVC.setProfiles(profile: members[0] as! Profile, profiles: friendArray)
            self.navigationController?.viewControllers = [(self.navigationController?.viewControllers[0])!, selectionVC, profileVC]
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {//check if chat name is filled out
        if textField.text! != ""{
            createButton.isEnabled = true
        }else{
            createButton.isEnabled = false
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {//only allow alphabet
        let characterSet = CharacterSet.letters
        
        if string.rangeOfCharacter(from: characterSet.inverted) != nil {
            return false
        }
        return true
    }
    
    @IBAction func createTapped(_ sender: Any) {
        let usersRef = FirebaseHelper.ref.child("chats").childByAutoId()
        FirebaseHelper.ref.child("chats").observeSingleEvent(of: .value) { (snapshot) in
            var string = ""
            var number = 1
            if let dict = snapshot.value as? NSDictionary{
                number = dict.allKeys.count+1//get numbers for chats so can distinguish chats
            }
            string = "\(number)"
            for var i in 0..<4-string.count{
                string = "0"+string
            }
            var joinType = 1
            if self.joinSwitch.isOn{
                joinType = 0
            }
            let values = ["chatName":self.chatNameTextField.text!+" #\(string)","joinType":joinType] as [String : Any]//upload chat info
            usersRef.updateChildValues(values, withCompletionBlock: { (err, ref) in
                if err != nil{
                    print(err)
                    return
                }
                let refStringArray = ref.url.split(separator: "/")
                let membersIds = NSMutableArray()
                for var member in self.members{
                    membersIds.add((member as! Profile).userId)
                }//add members
                let chat = Chat(id: String(refStringArray[refStringArray.count-1]), chatName: self.chatNameTextField.text!+" #\(string)", joinType: joinType, members: membersIds, posts: NSMutableArray())//update local profile
                FirebaseHelper.personal.chats.add(chat)
                usersRef.updateChildValues(["members":membersIds])//update Firebase
                
                let viewedDict = NSMutableDictionary()
                for var i in 0..<membersIds.count{
                    viewedDict.addEntries(from: ["\(membersIds[i])":0])
                }
                
                usersRef.updateChildValues(["viewed":viewedDict])
                for var i in membersIds{
                    FirebaseHelper.ref.child("users").child(i as! String).observeSingleEvent(of: .value, with: { (user) in
                        if let dict = user.value as? NSDictionary{
                            var index = 0
                            if (dict.allKeys as NSArray).contains("chats"){
                                index = (dict["chats"] as! NSArray).count
                            }
                            user.ref.child("chats").updateChildValues(["\(index)":chat.id])
                        }
                    })
                }
                
                FirebaseHelper.ref.child("chatNames").updateChildValues([chat.chatName.replacingOccurrences(of: "#", with: ""):chat.id])//characters not allowed, get rid of #
                StoreViewed.sharedInstance.addObserver(chatId:chat.id)//add observer for notifications
                self.navigationController?.popViewController(animated: false)
            })
        }
    }
    
    
    //tableview delegate functions
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {//can delete from members, not self
        if indexPath.row != 0 && indexPath.section == 0{
            return true
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            friendsToAdd.add(members.object(at: indexPath.row))
            members.removeObject(at: indexPath.row)//deletes member
            membersTable.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return members.count
        }else{
            return friendsToAdd.count
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //sets up label and profile image view
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        var array:NSArray
        if indexPath.section == 0{
            array = members
        }else{
            array = friendsToAdd
        }
        cell.textLabel?.text = "                    "+(array.object(at: indexPath.row) as! Profile).username//set up label
        let imageData = NSData(base64Encoded: (array.object(at: indexPath.row) as! Profile).icon , options: .ignoreUnknownCharacters)//set up profile picture
        let imageView = UIImageView(image: UIImage(data: imageData! as Data))
        imageView.frame = CGRect(x: 5, y: 5, width: 50, height: 50)
        imageView.layer.cornerRadius = imageView.frame.size.width/2
        imageView.layer.masksToBounds = true
        cell.contentView.addSubview(imageView)
        if indexPath.section == 0 && indexPath.row == members.count-1{
            let border = CALayer()//border between members and friends
            border.frame = CGRect(x: 0, y: 60, width: cell.frame.size.width, height: 2)
            border.backgroundColor = UIColor.black.cgColor
            cell.layer.addSublayer(border)
        }
        if indexPath.section == 1{
            if !members.contains(friendsToAdd.object(at: indexPath.row)){
                let button = UIButton(frame: CGRect(x: 0, y: 0, width: cell.frame.size.width, height: cell.frame.size.height))
                button.backgroundColor = .clear
                button.tag = indexPath.row
                button.addTarget(self, action: #selector(userTapped(sender:)), for: .touchUpInside)
                cell.contentView.addSubview(button)
                
                let width = cell.frame.size.height/2
                let addCircle = UIImageView(frame: CGRect(x: cell.frame.size.width-width*2, y: 30-width/2, width: width, height: width))
                addCircle.image = UIImage(named:"addButton")
                cell.contentView.addSubview(addCircle)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    @objc func userTapped(sender:UIButton) {//add user to members
        if !self.members.contains(friendsToAdd.object(at: sender.tag)){
            self.members.add(friendsToAdd.object(at: sender.tag))
            friendsToAdd.removeObject(at: sender.tag)
        }
        self.membersTable.reloadData()
    }
    

}
