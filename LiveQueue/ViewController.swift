//
//  ViewController.swift
//  LiveQueue
//
//  Created by Jordan Siff on 12/26/17.
//  Copyright © 2017 Jordan Siff. All rights reserved.
//

import UIKit
import Alamofire

class TableViewController: UITableViewController {
    
    var names = [String]()
    var searchURL = "https://api.spotify.com/v1/search?q=Kanye+West&type=track"
    
    typealias JSONStandard = [String : AnyObject]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        callAlamo(url: searchURL)
        setup()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateAfterFirstLogin))
    }
    
    func updateAfterFirstLogin () {
        if let sessionObj:AnyObject = userDefaults.object(forKey: "SpotifySession") as AnyObject? {
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            self.session = firstTimeSession
            initializePlayer(authSession: session)
        }
        
    func initializePlayer(authSession:SPTSession){
        if self.player == nil {
            self.player = SPTAudioStreamingController.sharedInstance()
            self.player!.playbackDelegate = self
            self.player!.delegate = self
            try! player!.start(withClientId: auth.clientID)
            self.player!.login(withAccessToken: authSession.accessToken)
            }
        }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        // after a user authenticates a session, the SPTAudioStreamingController is then initialized and this method called
        print("logged in")
        self.player?.playSpotifyURI("spotify:track:58s6EuEYJdlb0kO7awm3Vp", startingWith: 0, startingWithPosition: 0, callback: { (error) in
            if (error != nil) {
                print("playing!")
            }
        })
    }
        
        

    func callAlamo(url : String){
        Alamofire.request(url).responseJSON(completionHandler: {
            response in
            
            self.parseData(JSONData : response.data!)
            
        })
        
    }
    
    func parseData(JSONData : Data){
        do{
            let readableJSON = try JSONSerialization.jsonObject(with: JSONData, options: .mutableContainers) as! JSONStandard
            if let tracks = readableJSON["tracks"] as? JSONStandard{
                if let items = tracks["items"]{
                    for i in 0..<items.count{
                        let item = items[i] as! JSONStandard
                        let name = item["name"] as! String
                        names.append(name)
                        
                        self.tableView.reloadData()
                    }
                }
            }
        }
        catch{
            print(error)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return names.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        
        cell?.textLabel?.text = names[indexPath.row]
        
        return cell!
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Authentication
    
    var auth = SPTAuth.defaultInstance()!
    var session:SPTSession!
    var player: SPTAudioStreamingController?
    var loginUrl: URL?
    //let clientID  = "5820fd69400947cb87dc2784c9dd5afc"
    
    func setup() {
        SPTAuth.defaultInstance().clientID = "5820fd69400947cb87dc2784c9dd5afc"
        SPTAuth.defaultInstance().redirectURL = URL(string : "LiveQueue://returnAfterLogin")
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope]
        loginUrl = SPTAuth.defaultInstance().spotifyWebAuthenticationURL()
    }

    @IBAction func loginButtonPressed(_ sender: UIButton) {
        if UIApplication.shared.openURL(loginUrl!) {
            if auth.canHandle(auth.redirectURL) {
                // To do - build in error handling
            }
        }
    }
    
}

}
