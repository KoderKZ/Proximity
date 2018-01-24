//
//  StartingViewController.swift
//  Proximity
//
//  Created by Kevin Zhou on 1/16/18.
//  Copyright © 2018 Kevin Zhou. All rights reserved.
//

import Foundation
import UIKit
class StartingViewController:UIViewController{

    override func viewDidLoad() {

        self.view.backgroundColor = lightBgColor
        if StoreLogin.sharedInstance.getUsername() != "" && StoreLogin.sharedInstance.getPassword() != ""{
            let chatVc = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
            let transition = CATransition()
            transition.duration = 1
            transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            transition.type = kCATransitionFade
            self.navigationController?.view.layer.add(transition, forKey: nil)
            loginProcess(username: StoreLogin.sharedInstance.getUsername(), password: StoreLogin.sharedInstance.getPassword(), vc: chatVc, error: { (err) in
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "SignInViewController")
                _ = self.navigationController?.pushViewController(vc!, animated: false)
            }, finished: { (vc) in
                _ = self.navigationController?.pushViewController(vc, animated: false)
                StoreViewed.sharedInstance.loggedIn()
            })
        }else{
            delay(2){
                let transition = CATransition()
                transition.duration = 1
                transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                transition.type = kCATransitionFade
                self.navigationController?.view.layer.add(transition, forKey: nil)
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "SignInViewController")
                _ = self.navigationController?.pushViewController(vc!, animated: false)
            }
        }
    }
}
