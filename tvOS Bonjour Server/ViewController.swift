//
//  ViewController.swift
//  tvOS Bonjour Server
//
//  Created by Alexandre  Vassinievski on 28/07/17.
//  Copyright © 2017 Alexandre  Vassinievski. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, BonjourServerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var server: BonjourServer!
    
    
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        // bounjourHandler()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        server = BonjourServer()
        server.delegate = self
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func bounjourHandler(){
        
        BonjourTCPServer.sharedInstance.dataReceivedCallback = {(data) in
            
            print(data)
            
            self.textView.text = data
            
        }
    }
    
    
    func setupCollectionView() {
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cardCollectionView", for: indexPath)
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 30
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var size = CGSize (width: 150, height: 200)
        
        size.width = self.view.frame.width / 10  - 16
        size.height = self.view.frame.height / 3
        
        
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsetsMake(4, 8, 4, 8)
    }
    
    
    // MARK: Bonjour server delegates
    
    func handleBody(body: NSString?) {
        print("Received message: \(body)")
        //self.receivedTextField.text = body! as String
    }
    
    func connectedTo(socket: GCDAsyncSocket!) {
        //print("Connected to " + socket.connectedHost)
        //print("Connected to " + socket.description)
        print( "Connected users: \( server.connectedSockets.count  )")
    }
    
    func disconnected(socket: GCDAsyncSocket!) {
        //self.xStatusText.stringValue = "Disconnected"
        //print("User disconnected: " + socket.description)
        print( "Connected users: \( server.connectedSockets.count  )")
    }
    
    
}

