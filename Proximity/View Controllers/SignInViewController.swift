//
//  SignInViewController.swift
//  Proximity
//
//  Created by Kevin Zhou on 11/22/17.
//  Copyright © 2017 Kevin Zhou. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
class SignInViewController:UIViewController{
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    
    override func viewDidLoad() {
        self.view.backgroundColor = .clear
        self.view.setGradientBackground(colorOne: bgColor, colorTwo: darkGray)
        let border = CALayer()
        border.frame = CGRect(x: 0, y: emailTextField.frame.size.height, width: self.view.frame.size.width-(emailTextField.frame.origin.x*2), height: 1)
        border.backgroundColor = UIColor.white.cgColor
        emailTextField.layer.addSublayer(border)
        
        let border2 = CALayer()
        border2.frame = CGRect(x: 0, y: passwordTextField.frame.size.height, width: self.view.frame.size.width-(passwordTextField.frame.origin.x*2), height: 1)
        border2.backgroundColor = UIColor.white.cgColor
        passwordTextField.layer.addSublayer(border2)
        
        signInButton.layer.bounds.size = signInButton.frame.size
        signInButton.backgroundColor = .clear
        signInButton.setGradientBackground(colorOne: darkGray, colorTwo: gray)
        
        signInButton.setTitleColor(.white, for: .normal)
        signInButton.layer.masksToBounds = true
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        emailTextField.returnKeyType = .done
        passwordTextField.returnKeyType = .done
        
        emailTextField.keyboardType = .emailAddress
        passwordTextField.isSecureTextEntry = true
        
        errorLabel.alpha = 0
        
        self.hideKeyboardWhenTappedAround()
        
    }
    @IBAction func signInTapped(_ sender: Any) {
        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
            if error != nil{
                self.errorLabel.text = error?.localizedDescription
                self.errorLabel.alpha = 1
                return
            }
            let ref = FirebaseHelper.ref.child("users").child((user?.uid)!)
            //            let chats = ref.child("chats").
            
            var icon = ""
            var username = ""
            var latitude:Double = 0
            var longitude:Double = 0
            let chats = NSMutableArray()
            let friends = NSMutableArray()
            let friendRequests = NSMutableArray()
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
            
            var requiredIconAmt = 0
            var actualIconAmt = 0
            var finishedFriends = 0
            var finishedRequests = 0
            var actualFriendsAmount = 0
            var finishedFriendRequests = false
            ref.observeSingleEvent(of: .value, with: { (snapshot1) in
                if let dictionary = snapshot1.value as? [String:AnyObject]{
                    icon = dictionary["icon"] as! String
                    latitude = dictionary["latitude"] as! Double
                    longitude = dictionary["longitude"] as! Double
                    username = dictionary["username"] as! String
                }
                ref.child("chats").observeSingleEvent(of: .value, with: { (snapshot2) in
                    if let array = snapshot2.value as? NSArray{
                        for var i in array{
                            FirebaseHelper.ref.child("chats").child(i as! String).observe(.value, with: { (chatSnapshot) in
                                if let dictionary = chatSnapshot.value as? [String:AnyObject]{
                                    var chat = Chat(id: i as! String, chatName: dictionary["chatName"] as! String, joinType: dictionary["joinType"] as! Int, members: NSMutableArray(), posts: NSMutableArray())
                                    if let members = dictionary["members"]{
                                        chat.members = members as! NSMutableArray
                                        for var j in chat.members{
                                            if vc.profileIcons.object(forKey: j as! String) == nil{
                                                requiredIconAmt += 1
                                                FirebaseHelper.ref.child("users").child(j as! String).observe(.value, with: { (snapshot) in
                                                    if let profile = snapshot.value as? [String:AnyObject] {
                                                        vc.profileIcons.addEntries(from: [(j as! String): profile["icon"]])
                                                        actualIconAmt += 1
                                                        if requiredIconAmt == actualIconAmt && finishedRequests == 1 && finishedFriendRequests{
                                                            self.navigationController?.pushViewController(vc, animated: true)
                                                        }else if requiredIconAmt == actualIconAmt && finishedRequests == 0{
                                                            finishedRequests += 1
                                                        }
                                                    }
                                                })
                                            }
                                        }
                                    }
                                    chats.add(chat)
                                }
                            })
                        }
                        ref.child("friends").observeSingleEvent(of: .value, with: { (snapshot4) in
                            if let friendArray = snapshot4.value as? NSArray{
                                actualFriendsAmount = friendArray.count
                                for var i in friendArray{
                                    FirebaseHelper.ref.child("users").child(i as! String).observe(.value, with: { (snapshot) in
                                        if let dictionary = snapshot.value as? [String:AnyObject]{
                                            var friends = NSMutableArray()
                                            var chats = NSMutableArray()
                                            if dictionary.keys.contains("chats"){chats = dictionary["chats"] as! NSMutableArray}
                                            var friend = Profile(username: dictionary["username"] as! String, userId: i as! String, friends: friends, icon: dictionary["icon"] as! String, chats: chats, latitude: dictionary["latitude"] as! Double, longitude: dictionary["longitude"] as! Double)
                                            friends.add(friend)
                                            finishedFriends += 1
                                            if finishedFriends == friendArray.count && finishedRequests == 1 && finishedFriendRequests{
                                                FirebaseHelper.personal.friends = friends
                                                self.navigationController?.pushViewController(vc, animated: true)
                                            }else if finishedFriends == friendArray.count && finishedRequests == 0{
                                                finishedRequests += 1
                                            }
                                        }
                                    })
                                }
                            }else{
                                finishedRequests += 1
                            }

                            ref.child("friendRequests").observeSingleEvent(of: .value, with: { (snapshot5) in
                                if let array = snapshot5.value as? NSArray{
                                    for var i in array{
                                        FirebaseHelper.ref.child("users").child(i as! String).observe(.value, with: { (snapshot) in
                                            if let dictionary = snapshot.value as? [String:AnyObject]{
                                                var friends = NSMutableArray()
                                                var chats = NSMutableArray()
                                                if dictionary.keys.contains("friends"){friends = dictionary["friends"] as! NSMutableArray}
                                                if dictionary.keys.contains("chats"){chats = dictionary["chats"] as! NSMutableArray}
                                                var friend = Profile(username: dictionary["username"] as! String, userId: i as! String, friends: friends, icon: dictionary["icon"] as! String, chats: chats, latitude: dictionary["latitude"] as! Double, longitude: dictionary["longitude"] as! Double)
                                                friendRequests.add(friend)
                                            }
                                        })
                                    }
                                }
                                finishedFriendRequests = true
                                FirebaseHelper.personal = Personal(username: username, userId: (user?.uid)!, friendRequests: friendRequests, email: self.emailTextField.text!, friends: friends, icon: icon, chats: chats, latitude: latitude, longitude: longitude)
                                if actualIconAmt == requiredIconAmt{
                                    self.navigationController?.pushViewController(vc, animated: true)
                                }
                            })
                        })
                    }
                })
            })
        }
    }
    @IBAction func forgotPasswordTapped(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ForgotPasswordViewController")
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    @IBAction func registerTapped(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "RegistrationViewController")
        self.navigationController?.pushViewController(vc!, animated: true)
    }
}
