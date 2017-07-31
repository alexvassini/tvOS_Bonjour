//
//  Server.swift
//  Impixable
//
//  Created by Tibor Bodecs on 2015. 09. 29..
//  Copyright © 2015. Tibor Bodecs. All rights reserved.
//
import Foundation
import CocoaAsyncSocket


#if os(OSX)
    private let deviceName = NSHost.currentHost().localizedName!
#else
    import UIKit
    private let deviceName = UIDevice.current.name
#endif


class BonjourUDPServer: NSObject, GCDAsyncUdpSocketDelegate, NetServiceDelegate
{
    
    var socket : GCDAsyncUdpSocket!
    let socketPort: UInt16 = 5566
    
    var service : NetService? = nil
    let servicePort : Int32 = 5667
    let serviceDomain = "local."
    let serviceType = "_udp_discovery._udp."
    
    var registeredName : String? = nil
    
    var callback : ((_ message: String, _ from: String) -> Void)?
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    //  MARK: init
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    static let sharedInstance = BonjourUDPServer()
    
    fileprivate override init() {
        super.init()
        
        self.service = NetService(domain: self.serviceDomain, type: self.serviceType, name: deviceName, port: self.servicePort)
        self.service?.delegate = self
        self.service?.publish()
        
        self.socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        let _ = try? self.socket.bind(toPort: self.socketPort)
        let _ = try? self.socket.beginReceiving()
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    //  MARK: NSNetServiceDelegate
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    func netServiceWillPublish(_ sender: NetService) {}
    
    func netServiceDidPublish(_ sender: NetService) {
        self.registeredName = sender.name
        NSLog("registered \(sender.name)")
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        NSLog("service error \(errorDict)")
    }
    
    func netServiceWillResolve(_ sender: NetService) {}
    func netServiceDidResolveAddress(_ sender: NetService) {}
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {}
    func netServiceDidStop(_ sender: NetService) {}
    func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {}
    func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {}
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    //  MARK: socket delegate
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    func udpSocket(_ sock: GCDAsyncUdpSocket!, didReceive data: Data!,
                   fromAddress address: Data!, withFilterContext filterContext: AnyObject!)
    {
        let address    = GCDAsyncUdpSocket.host(fromAddress: address)
        let dataString = String(data: data, encoding: String.Encoding.utf8)
        
        if
            let message = dataString
        {
            self.callback?(message, address!)
        }
    }
    
    
}
