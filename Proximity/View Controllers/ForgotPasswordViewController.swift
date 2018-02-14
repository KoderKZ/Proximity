//
//  ForgotPasswordViewController.swift
//  Proximity
//
//  Created by Kevin Zhou on 11/27/17.
//  Copyright © 2017 Kevin Zhou. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
class ForgotPasswordViewController:UIViewController{
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var confirmTextField: UITextField!
    
    override func viewDidLoad() {
        //set up ui/default functions
        self.view.setGradientBackground(colorOne: lightGray, colorTwo: bgColor)
        
        self.hideKeyboardWhenTappedAround()
        
        let border = CALayer()
        border.frame = CGRect(x: 0, y: emailTextField.frame.size.height, width: self.view.frame.size.width-(emailTextField.frame.origin.x*2), height: 1)
        border.backgroundColor = UIColor.black.cgColor
        emailTextField.layer.addSublayer(border)
        
        let border2 = CALayer()
        border2.frame = CGRect(x: 0, y: confirmTextField.frame.size.height, width: self.view.frame.size.width-(confirmTextField.frame.origin.x*2), height: 1)
        border2.backgroundColor = UIColor.black.cgColor
        confirmTextField.layer.addSublayer(border2)
        
        emailTextField.delegate = self

    }
    
    @IBAction func finishButtonTapped(_ sender: Any) {
        if emailTextField.text! == confirmTextField.text!{
            Auth.auth().sendPasswordReset(withEmail: emailTextField.text!) { (err) in//Firebase will help send email
                if err != nil{//error, gives description
                    self.errorLabel.text = err?.localizedDescription
                    return
                }
                self.navigationController?.popViewController(animated: true)
            }
        }else{
            self.errorLabel.text = "Emails do not match"
        }
    }
    @IBAction func backTapped(_ sender: Any) {//goes back
        if emailTextField.alpha == 1{
            self.navigationController?.popViewController(animated: true)
        }
    }
}
