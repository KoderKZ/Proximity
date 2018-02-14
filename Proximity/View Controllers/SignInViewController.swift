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
import SwiftGifOrigin
class SignInViewController:UIViewController{//sign in vc
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    var originalWidth:CGFloat = 0
    var image = UIImage()
    var animatingView:UIView!
    override func viewDidLoad() {
        //set ui colors and positioning
        self.view.backgroundColor = .clear
        self.view.setGradientBackground(colorOne: lightGray, colorTwo: bgColor)
        let border = CALayer()
        border.frame = CGRect(x: 0, y: emailTextField.frame.size.height, width: self.view.frame.size.width-(emailTextField.frame.origin.x*2), height: 1)
        border.backgroundColor = UIColor.black.cgColor
        emailTextField.layer.addSublayer(border)
        
        let border2 = CALayer()
        border2.frame = CGRect(x: 0, y: passwordTextField.frame.size.height, width: self.view.frame.size.width-(passwordTextField.frame.origin.x*2), height: 1)
        border2.backgroundColor = UIColor.black.cgColor
        passwordTextField.layer.addSublayer(border2)
        
        signInButton.backgroundColor = .black
        
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
        
        originalWidth = self.view.frame.size.width/5*4
        signInButton.frame = CGRect(x: self.view.frame.size.width/2-originalWidth/2, y: forgotPasswordButton.frame.origin.y+forgotPasswordButton.frame.size.height+50, width: originalWidth, height: originalWidth/5)
        signInButton.layer.cornerRadius = signInButton.frame.size.height/2
        
        animatingView = UIView(frame: signInButton.frame)
        animatingView.frame.size.width = animatingView.frame.size.height
        animatingView.backgroundColor = .white
        animatingView.alpha = 0
        self.view.addSubview(animatingView)
        
        self.view.isUserInteractionEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)//correct autolayout if it went wrong
        errorLabel.alpha = 0
        self.signInButton.frame.size.width = self.originalWidth
        self.signInButton.setBackgroundImage(nil, for: .normal)
        self.signInButton.frame.origin.x = self.view.frame.size.width/2-self.originalWidth/2
        self.signInButton.setTitleColor(.white, for: .normal)
        
        image = UIImage.gif(name: "spinner")!//get gif image so can set later
        
        //set up animatingView:animates when log in
        animatingView.alpha = 0
        animatingView.frame = signInButton.frame
        
        animatingView.frame.size.width = animatingView.frame.size.height
        animatingView.frame.origin.x = self.view.frame.size.width/2-animatingView.frame.size.width/2
        animatingView.layer.cornerRadius = animatingView.frame.size.width/2

    }
    
    
    @IBAction func signInTapped(_ sender: Any) {
        originalWidth = self.signInButton.frame.size.width
        self.view.isUserInteractionEnabled = false//make sure nothing happens while trying to log in

        UIView.animate(withDuration: 0.5, animations: {//set button as loading circle
            self.signInButton.frame = CGRect(origin: CGPoint(x:self.view.frame.size.width/2-self.signInButton.frame.size.height/2,y:self.signInButton.frame.origin.y), size: CGSize(width: self.signInButton.frame.size.height, height: self.signInButton.frame.size.height))
            self.signInButton.setTitleColor(.clear, for: .normal)
        }) { (true) in
            self.signInButton.setBackgroundImage(self.image, for: .normal)
        }
        
        loginProcess(username: emailTextField.text!, password: passwordTextField.text!, error: { (err) in
            self.errorLabel.text = err.localizedDescription//error in logging in, set error message, return to normal
            self.errorLabel.alpha = 1
            self.view.isUserInteractionEnabled = true
            self.signInButton.setBackgroundImage(nil, for: .normal)
            UIView.animate(withDuration: 0.5, animations: {
                self.signInButton.frame.size.width = self.originalWidth
                self.signInButton.frame.origin.x = self.view.frame.size.width/2-self.originalWidth/2
                self.signInButton.setBackgroundImage(nil, for: .normal)
            }) { (true) in
                self.signInButton.setTitleColor(.white, for: .normal)
                self.signInButton.setBackgroundImage(nil, for: .normal)
            }
        }) { (bool) in
            self.animatingView.alpha = 1//successfully logged in, animate to next view

            let anim1 = CABasicAnimation(keyPath: #keyPath(CALayer.cornerRadius))
            anim1.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            anim1.fromValue = self.animatingView.frame.size.width/2
            anim1.toValue = (self.view.frame.size.height+200)/2
            anim1.duration = 0.5
            self.animatingView.layer.add(anim1, forKey: "cornerRadius")

            UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear, animations: {
                self.animatingView.frame = CGRect(x: -100+self.view.frame.size.width/2-self.view.frame.size.height/2, y: -100, width: self.view.frame.size.height+200, height: self.view.frame.size.height+200)

            }, completion: { (true) in
                let transition = CATransition()
                transition.duration = 0.5
                transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                transition.type = kCATransitionFade
                self.navigationController?.view.layer.add(transition, forKey: nil)
                StoreLogin.sharedInstance.setLogin(username: self.emailTextField.text!, password: self.passwordTextField.text!)
                StoreViewed.sharedInstance.loggedIn()
                let selectionVc = self.storyboard?.instantiateViewController(withIdentifier: "SelectionViewController") as! SelectionViewController
                self.navigationController?.pushViewController(selectionVc, animated: false)
            })
        }
    }
    @IBAction func forgotPasswordTapped(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ForgotPasswordViewController")//pushes to forgot password vc
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    @IBAction func registerTapped(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "RegistrationViewController")//pushes to register tapped vc
        self.navigationController?.pushViewController(vc!, animated: true)
    }
}
