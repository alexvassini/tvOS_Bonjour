//
//  BonjourController.swift
//  xBonjourDemo
//  Created by Johnson, Christopher P on 10/20/15.
//  Copyright © 2015 Johnson, Christopher P. All rights reserved.

import UIKit
import CocoaAsyncSocket

enum PacketTagC: Int {
    case Header = 1
    case Body = 2
}

protocol BonjourClientDelegate {
    func connected()
    func disconnected()
    func handleBody(body: NSString?)
    func didChangeServices()
}

class BonjourClient: NSObject, NetServiceBrowserDelegate, NetServiceDelegate, GCDAsyncSocketDelegate {
    
    var delegate: BonjourClientDelegate!
    
    var coServiceBrowser: NetServiceBrowser!
    
    var devices: Array<NetService>!
    
    var connectedService: NetService!
    
    var sockets: [String : GCDAsyncSocket]!

    override init() {
        super.init()
        self.devices = []
        self.sockets = [:]
        self.startService()
    }
    
    func parseHeader(data: NSData) -> UInt {
        var out: UInt = 0
        data.getBytes(&out, length: MemoryLayout<UInt>.size)
        return out
    }
    
    func handleResponseBody(data: NSData) {
        if let message = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) {
            self.delegate.handleBody(body: message)
        }
    }
    
    func connectTo(service: NetService) {
        service.delegate = self as! NetServiceDelegate
        service.resolve(withTimeout: 3)
    }
    
    // MARK: NSNetServiceBrowser helpers
    
    func stopBrowsing() {
        if self.coServiceBrowser != nil {
            self.coServiceBrowser.stop()
            self.coServiceBrowser.delegate = nil
            self.coServiceBrowser = nil
        }
    }
    
    func startService() {
        //print("startService")
        if self.devices != nil {
            self.devices.removeAll(keepingCapacity: true)
        }
        
        self.coServiceBrowser = NetServiceBrowser()
        self.coServiceBrowser.delegate = self
        //self.coServiceBrowser.includesPeerToPeer = true
        self.coServiceBrowser.searchForServices(ofType: "_probonjoreCJ._tcp.", inDomain: "local.")
    }
    
    //func send(data: NSData) {
    func send( xString: String) {
        //print("send data")
        var xString = xString
        if xString.characters.count == 8 {
            xString = "\(xString) "
        }
        let data : NSData = xString.data(using: String.Encoding.utf8)! as NSData
        //.dataUsingEncoding(NSUTF8StringEncoding)
        if let socket = self.getSelectedSocket() {
            var header = data.length
            let headerData = NSData(bytes: &header, length: MemoryLayout<UInt>.size)
            socket.write(headerData as Data, withTimeout: -1.0, tag: PacketTagC.Header.rawValue)
            //print ( String(data: headerData, encoding: NSUTF8StringEncoding)  )
            socket.write(data as Data, withTimeout: -1.0, tag: PacketTagC.Body.rawValue)
        } else {
            //print("5")
        }
    }
    
    func connectToServer(service: NetService) -> Bool {
        var connected = false
        
        let addresses: Array = service.addresses!
        var socket = self.sockets[service.name]
        
        if !(socket?.isConnected != nil) {
            socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
            while !connected && !addresses.isEmpty {
                let address: NSData = addresses[0] as NSData
                do {
                    if (try socket?.connect(toAddress: address as Data) != nil) {
                        print( "Connecting to : \( service.name )")
                        self.sockets.updateValue(socket!, forKey: service.name)
                        self.connectedService = service
                        connected = true
                        stopBrowsing()  //cj added
                    }
                } catch {
                    print(error);
                }
            }
        }
        
        return true
    }
    
    // MARK: NSNetService Delegates
    
    func netServiceDidResolveAddress(sender: NetService) {
        //print("did resolve address \(sender.name)")
        if self.connectToServer(service: sender) {
            //print("connected to \(sender.name)")
            self.delegate.connected()
        }
    }
    
    func netService(sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("net service did no resolve. errorDict: \(errorDict)")
    }
    
    // MARK: GCDAsyncSocket Delegates
    
    func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        //print("connected to host \(host), on port \(port)")
        sock.readData(toLength: UInt(MemoryLayout<UInt64>.size), withTimeout: -1.0, tag: 0)
    }
    
    func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        //print("socket did disconnect \(sock), error: \(err.userInfo)")
        self.delegate.disconnected()
    }
    
    func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        //print("socket did read data. tag: \(tag)")
        
        if self.getSelectedSocket() == sock {
            if data.length == MemoryLayout<UInt>.size {
                let bodyLength: UInt = self.parseHeader(data: data)
                //print("bodyLength: \(bodyLength)")
                //7668058320735204196
                //if bodyLength > 2342343223 {
                    //fdfgdsee
                    //sock.readDataWithTimeout(-1, tag: PacketTagC.Body.rawValue)
                //} else {
                sock.readData(toLength: bodyLength, withTimeout: -1, tag: PacketTagC.Body.rawValue)
                //}
                
            } else {
                self.handleResponseBody(data: data)
                sock.readData(toLength: UInt(MemoryLayout<UInt>.size), withTimeout: -1, tag: PacketTagC.Header.rawValue)
            }
        }
    }
    
    func socketDidCloseReadStream(sock: GCDAsyncSocket!) {
        print("socket did close read stream")
    }
    
    // MARK: NSNetServiceBrowser Delegates
    
    func netServiceBrowser(aNetServiceBrowser: NetServiceBrowser, didFindService aNetService: NetService, moreComing: Bool) {
        self.devices.append(aNetService)
        if !moreComing {
            self.delegate.didChangeServices()
        }
    }
    
    func netServiceBrowser(aNetServiceBrowser: NetServiceBrowser, didRemoveService aNetService: NetService, moreComing: Bool) {
        self.devices.removeObject(object: aNetService)
        if !moreComing {
            self.delegate.didChangeServices()
        }
    }
    
    func netServiceBrowserDidStopSearch(aNetServiceBrowser: NetServiceBrowser) {
        self.stopBrowsing()
    }
    
    func netServiceBrowser(aNetServiceBrowser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        self.stopBrowsing()
    }
    
    // MARK: helpers
    
    func getSelectedSocket() -> GCDAsyncSocket? {
        var sock: GCDAsyncSocket?
        if self.connectedService != nil {
            sock = self.sockets[self.connectedService.name]!
        }
        return sock
    }
    
}

extension Array {
    mutating func removeObject<U: Equatable>(object: U) {
        var index: Int?
        for (idx, objectToCompare) in self.enumerated() {
            if let to = objectToCompare as? U {
                if object == to {
                    index = idx
                }
            }
        }
        
        if(index != nil) {
            self.remove(at: index!)
        }
    }
}
