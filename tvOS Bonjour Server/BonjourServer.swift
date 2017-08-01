//
//  BonjourController.swift
//  xBonjourDemo
//
//  Created by Johnson, Christopher P on 10/20/15.
//  Copyright © 2015 Johnson, Christopher P. All rights reserved.
//

import CocoaAsyncSocket


enum PacketTag: Int {
    case Header = 1
    case Body = 2
}

protocol BonjourServerDelegate {
    func connectedTo(socket: GCDAsyncSocket!)
    func disconnected(socket: GCDAsyncSocket!)
    func handleBody(body: NSString?)
}

class BonjourServer: NSObject, NetServiceDelegate, NetServiceBrowserDelegate, GCDAsyncSocketDelegate {
    
    var delegate: BonjourServerDelegate!
    
    var service: NetService!
    
    var socket: GCDAsyncSocket!
    
    var connectedSockets : NSMutableArray!
    
    override init() {
        super.init()
        self.startBroadCasting()
    }
    
    func startBroadCasting() {
        self.socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        
        connectedSockets = []
        
        var error: NSError?
        //UIDevice.currentDevice().name
        do {
            try self.socket.accept(onPort: 0)
            self.service = NetService(domain: "local.", type: "_probonjoreCJ._tcp.", name: "xHostWithMostist", port: Int32(self.socket.localPort) )
            //self.service.includesPeerToPeer = true
            self.service.delegate = self
            self.service.publish()
            
            
        } catch let error1 as NSError {
            error = error1
            print("Unable to create socket. Error \(error)")
        }
    }
    
    func parseHeader(data: NSData) -> UInt {
        var out: UInt = 0
        data.getBytes(&out, length: MemoryLayout<UInt>.size)
        return out
    }
    
    func handleResponseBody(data: NSData) -> NSString? {
        if let message = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) {
            return message
        }
        return nil
    }
    
    func send( xString: String) {
        //print("send data")
        var xString = xString
        if xString.characters.count == 8 {
            xString = "\(xString) "
        }
        let data : NSData = xString.data(using: String.Encoding.utf8)! as NSData
        
        var header = data.length
        let headerData = NSData(bytes: &header, length: MemoryLayout<UInt>.size)

        for i in 0 ..< connectedSockets.count {
            let thisSocket : GCDAsyncSocket = self.connectedSockets[i] as! GCDAsyncSocket
            
            thisSocket.write(headerData as Data, withTimeout: -1.0, tag: PacketTag.Header.rawValue)
            thisSocket.write(data as Data, withTimeout: -1.0, tag: PacketTag.Body.rawValue)
        }
    }
    
    /// MARK: NSNetService Delegates
    
    func netServiceDidPublish(sender: NetService) {
        //print("Bonjour service published. domain: \(sender.domain), type: \(sender.type), name: \(sender.name), port: \(sender.port)")
    }
    
    func netService(sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        //print("Unable to create socket. domain: \(sender.domain), type: \(sender.type), name: \(sender.name), port: \(sender.port), Error \(errorDict)")
        //print( errorDict["NSNetServicesErrorCode"] )
        let xErrorCode : Int = errorDict["NSNetServicesErrorCode"] as! Int
        
        if xErrorCode == -72001 {
            print("Service named \(sender.name) is already in use on this network!")
        }
    }
    
    /// MARK: GCDAsyncSocket Delegates
    
    func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        //print("Did accept new socket from: \(newSocket.connectedHost) - \(newSocket.connectedPort)")
        
        
        
        newSocket.readData(withTimeout: -1, tag: 0)
        //newSocket.readDataToLength(UInt(sizeof(UInt64)), withTimeout: -1.0, tag: 0)
        
        
        //self.socket = newSocket
        //self.socket.readDataToLength(UInt(sizeof(UInt64)), withTimeout: -1.0, tag: 0)
        self.delegate.connectedTo(socket: newSocket)
    }
    
    func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        //print("socket did disconnect: error \(err)")
        //print(sock )
        
        connectedSockets.remove(sock)
        
        /*
        for (var i = 0; i < connectedSockets.count; i++) {
        let thisSocket : GCDAsyncSocket = self.connectedSockets[i] as! GCDAsyncSocket
        if thisSocket == sock {
        //self.delegate.disconnected()
        print("socket found that left us! as pos: \(i)")
        connectedSockets.removeObjectAtIndex(i)
        break
        }
        }
        */
        
        
        
        
        //if self.socket == socket {
        self.delegate.disconnected(socket: sock)
        //}
        
    }
    
    func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        //print("didReadData")
        
        if data.length == MemoryLayout<UInt>.size {
            let bodyLength: UInt = self.parseHeader(data: data)
            sock.readData(toLength: bodyLength, withTimeout: -1, tag: PacketTag.Body.rawValue)
        } else {
            let body = self.handleResponseBody(data: data)
            self.delegate.handleBody(body: body)
            sock.readData(toLength: UInt(MemoryLayout<UInt>.size), withTimeout: -1, tag: PacketTag.Header.rawValue)
        }
    }
    
    //func socket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
    //---DO NOT DELETE. THIS IS USED
    //print("did write data with tag: \(tag)")
    //}
}
