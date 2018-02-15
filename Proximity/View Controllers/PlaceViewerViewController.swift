//
//  PlaceViewerViewController.swift
//  Proximity
//

import Foundation
import UIKit
import GooglePlaces
import GoogleMaps
import SafariServices
class PlaceViewerViewController:UIViewController,UITableViewDataSource,UITableViewDelegate,SFSafariViewControllerDelegate,GMSMapViewDelegate{
    var place:GMSPlace!
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var ratingLabel: UILabel!
    @IBOutlet var hoursLabel: UILabel!
    @IBOutlet var infoView: UIView!
    @IBOutlet var sendToView: UIView!
    @IBOutlet weak var addressLabel: UITextView!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var websiteButton: UIButton!
    var infoViewY:CGFloat = 0
    var tableView:UITableView!
    var delegate:PlaceViewerViewControllerDelegate!
    override func viewDidLoad() {
        //set up ui/colors
        super.viewDidLoad()
        infoView.subviews[2].backgroundColor = lightBgColor
        infoViewY = infoView.frame.origin.y
        addressLabel.isEditable = false
        nameLabel.text = self.place.name
        addressLabel.text = self.place.formattedAddress
        addressLabel.centerVertically()
        if self.place.rating != 0{
            ratingLabel.text = " \(self.place.rating)/5"
        }else{
            ratingLabel.text = " No rating"
        }
        if self.place.openNowStatus == GMSPlacesOpenNowStatus.no{
            hoursLabel.text = " Closed"
        }else if self.place.openNowStatus == GMSPlacesOpenNowStatus.yes{
            hoursLabel.text = " Open"
        }else{
            hoursLabel.text = " Hours not available"
        }
        if self.place.website?.absoluteString != nil{
            websiteButton.setTitle(" "+(self.place.website?.absoluteString)!, for: .normal)
            websiteButton.contentHorizontalAlignment = .left
        }


        let marker = GMSMarker(position: CLLocationCoordinate2DMake(self.place.coordinate.latitude, self.place.coordinate.longitude))
        marker.map = mapView
        mapView.animate(toZoom: 15)
        mapView.animate(toLocation: marker.position)
        
        self.sendToView.frame.origin.y = self.infoView.frame.size.height

        
        mapView.delegate = self
        
        self.sendToView.frame.size.height = self.infoView.frame.size.height
        tableView = UITableView(frame: CGRect(x: 50, y: 75, width: self.view.frame.size.width-100, height: sendToView.frame.size.height-125-dismissButton.frame.size.height))
        tableView.delegate = self
        tableView.dataSource = self
        sendToView.addSubview(tableView)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //change to view info
        UIView.animate(withDuration: 0.5) {
            self.infoView.frame.origin.y = self.infoViewY
            self.mapView.frame.size.height = self.view.frame.size.height-self.infoViewY
        }
    }
    
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        //change to view map
        UIView.animate(withDuration: 0.5) {
            self.infoView.frame.origin.y = self.view.frame.size.height-self.infoView.subviews[2].frame.size.height
            self.mapView.frame.size.height = self.infoView.frame.origin.y
        }
    }
    
    @IBAction func websiteTapped(_ sender: Any) {
        //goes to website
        let title = websiteButton.title(for: .normal)!
        let index = title.index(title.startIndex, offsetBy: 1)
        let svc = SFSafariViewController(url: URL(string: String(title.suffix(from: index)))!)
        svc.delegate = self
        self.present(svc, animated: true, completion: nil)
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        //dismiss website
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @objc func chatTapped(sender:UIButton) {
        //sends to chat when tapped
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
        
        UIView.animate(withDuration: 0.5, animations: {//go back to place viewer
            self.sendToView.frame.origin.y = self.infoView.frame.size.height
        })
    }
    

    @IBAction func sendTapped(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {//send to view pops up
            self.sendToView.frame.origin.y = self.infoView.subviews[2].frame.size.height
        }
    }
    
    
    func setPlace(place:GMSPlace) {
        self.place = place
    }
    
    @IBAction func dismissTapped(_ sender: Any) {
        UIView.animate(withDuration: 0.5, animations: {//go back to place viewer
            self.sendToView.frame.origin.y = self.infoView.frame.size.height
        })
    }
    @IBAction func backTapped(_ sender: Any) {
        if delegate != nil{//depends on if in chat view, dismisses either way
            delegate.dismissPlace()
        }else{
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    
    
    //table view for chats delegates
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FirebaseHelper.personal.chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //set up labels with chat names
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = (FirebaseHelper.personal.chats.object(at: indexPath.row) as! Chat).chatName
        
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

protocol PlaceViewerViewControllerDelegate{
    func dismissPlace();
}
