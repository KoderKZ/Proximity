//
//  PlaceViewerViewController.swift
//  Proximity
//
//  Created by Kevin Zhou on 12/13/17.
//  Copyright © 2017 Kevin Zhou. All rights reserved.
//

import Foundation
import UIKit
import GooglePlaces
import GoogleMaps
class PlaceViewerViewController:UIViewController,UITableViewDataSource,UITableViewDelegate{
    var place:GMSPlace!
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var websiteLabel: UILabel!
    @IBOutlet var ratingLabel: UILabel!
    @IBOutlet var hoursLabel: UILabel!
    @IBOutlet var infoView: UIView!
    @IBOutlet var sendToView: UIView!
    var tableView:UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        nameLabel.text = self.place.name
        addressLabel.text = self.place.formattedAddress
        if websiteLabel.text != nil{
            websiteLabel.text = self.place.website?.absoluteString
            if self.place.rating != 0{
                ratingLabel.text = "\(self.place.rating)/5"
                if self.place.openNowStatus.rawValue == 1{
                    hoursLabel.text = "Closed"
                }else{
                    hoursLabel.text = "Open"
                }
            }
        }
        let marker = GMSMarker(position: CLLocationCoordinate2DMake(self.place.coordinate.latitude, self.place.coordinate.longitude))
        marker.map = mapView
        mapView.animate(toZoom: 15)
        mapView.animate(toLocation: marker.position)
        
        sendToView.frame.origin.y = self.view.frame.size.height
        
        
        tableView = UITableView(frame: CGRect(x: 50, y: 100, width: self.view.frame.size.width-100, height: self.view.frame.size.height-200))
        tableView.delegate = self
        tableView.dataSource = self
        sendToView.addSubview(tableView)

        
        
    }
    
    @objc func chatTapped(sender:UIButton) {
        let chat = FirebaseHelper.personal.chats[sender.tag] as! Chat
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "HH:mm:ss"
        let timeString = formatter.string(from: now)
        
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: now)
        
        
        let ref = FirebaseHelper.ref.child("chats").child(chat.id).child("posts")
        let childRef = ref.childByAutoId()
        let values = ["profileId":FirebaseHelper.personal.userId, "timestamp":timeString, "datestamp":dateString,"place": place.placeID] as [String : Any]
        childRef.updateChildValues(values)
    }
    
    @IBAction func sendTapped(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.sendToView.frame.origin.y = 0
        }
    }
    func setPlace(place:GMSPlace) {
        self.place = place
    }
    @IBAction func backTapped(_ sender: Any) {
        if sendToView.frame.origin.y == 0{
            UIView.animate(withDuration: 0.5, animations: {
                self.sendToView.frame.origin.y = self.view.frame.size.height
            })
        }else{
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FirebaseHelper.personal.chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = "                    "+(FirebaseHelper.personal.chats.object(at: indexPath.row) as! Chat).chatName
        
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 60))
        button.backgroundColor = .clear
        button.tag = indexPath.row
        cell.contentView.addSubview(button)
        button.addTarget(self, action: #selector(chatTapped(sender:)), for: .touchUpInside)
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
        label.text = "Chats"
        label.backgroundColor = .white
        return label
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}
