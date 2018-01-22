//
//  CreateChatViewController.swift
//  Proximity
//
//  Created by Kevin Zhou on 11/5/17.
//  Copyright © 2017 Kevin Zhou. All rights reserved.
//

import Foundation
import UIKit
class CreateChatViewController:UIViewController,UITableViewDataSource,UITableViewDelegate{
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var chatNameTextField: UITextField!
    @IBOutlet weak var joinTypeSegment: UISegmentedControl!
    @IBOutlet weak var addMembersButton: UIButton!
    @IBOutlet weak var createButton: UIButton!
    var membersTable:UITableView!
    var addTable:UITableView!
    let members:NSMutableArray = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        membersTable = UITableView(frame: CGRect(x: joinTypeSegment.frame.origin.x, y: joinTypeSegment.frame.origin.y+joinTypeSegment.frame.size.height*1.5, width: self.view.frame.size.width-(joinTypeSegment.frame.origin.x*2), height: addMembersButton.frame.origin.y-joinTypeSegment.frame.origin.y))

        self.view.addSubview(membersTable)
        membersTable.delegate = self
        membersTable.dataSource = self
        
        addTable = UITableView(frame: CGRect(x: joinTypeSegment.frame.origin.x, y: joinTypeSegment.frame.origin.y+joinTypeSegment.frame.size.height*1.5, width: self.view.frame.size.width-(joinTypeSegment.frame.origin.x*2), height: addMembersButton.frame.origin.y-joinTypeSegment.frame.origin.y))
        
        self.view.addSubview(addTable)
        addTable.delegate = self
        addTable.dataSource = self
        addTable.alpha = 0
        self.view.addSubview(addTable)
        self.hideKeyboardWhenTappedAround()
        chatNameTextField.delegate = self
    }
    
    @IBAction func createTapped(_ sender: Any) {
        let usersRef = FirebaseHelper.ref.child("chats").childByAutoId()
        let values = ["chatName":chatNameTextField.text!,"joinType":joinTypeSegment.selectedSegmentIndex] as [String : Any]
        usersRef.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil{
                print(err)
                return
            }
            let refStringArray = ref.url.split(separator: "/")
            let membersIds = NSMutableArray()
            membersIds.add(FirebaseHelper.personal.userId)
            for var member in self.members{
                membersIds.add((member as! Profile).userId)
            }
            let chat = Chat(id: String(refStringArray[refStringArray.count-1]), chatName: self.chatNameTextField.text!, joinType: self.joinTypeSegment.selectedSegmentIndex, members: membersIds, posts: NSMutableArray())
            usersRef.updateChildValues(["members":membersIds])
            FirebaseHelper.personal.chats.add(chat)
            FirebaseHelper.updatePersonal()
            FirebaseHelper.ref.child("chatNames").observeSingleEvent(of: .value, with: { (snapshot) in
                if let array = snapshot.value as? NSMutableArray{
                    array.add(chat.id)
                    let dict = NSMutableDictionary()
                    for var i in 0..<array.count{
                        dict.addEntries(from: ["\(i)":array[i]])
                    }
                    snapshot.ref.updateChildValues(dict as! [AnyHashable:Any])
                }
            })
            self.navigationController?.popViewController(animated: true)
        })
        
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
