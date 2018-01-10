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
    
    override func viewDidLoad() {
        self.hideKeyboardWhenTappedAround()
        
        let border = CALayer()
        border.frame = CGRect(x: 0, y: emailTextField.frame.size.height, width: self.view.frame.size.width-(emailTextField.frame.origin.x*2), height: 1)
        border.backgroundColor = UIColor.black.cgColor
        emailTextField.layer.addSublayer(border)
        

        
        emailTextField.delegate = self

    }
    
    @IBAction func finishButtonTapped(_ sender: Any) {
        Auth.auth().sendPasswordReset(withEmail: emailTextField.text!) { (err) in
            if err != nil{
                self.errorLabel.text = err?.localizedDescription
                return
            }
            self.navigationController?.popViewController(animated: true)
        }
    }
    @IBAction func backTapped(_ sender: Any) {
        if emailTextField.alpha == 1{
            self.navigationController?.popViewController(animated: true)
        }
    }
}
