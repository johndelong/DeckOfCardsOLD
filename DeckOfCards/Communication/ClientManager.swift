//
//  ClientManager.swift
//  DeckOfCards
//
//  Created by John DeLong on 4/2/16.
//  Copyright © 2016 delong. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class ClientManager: NSObject, GCDAsyncSocketDelegate {

    static let sharedInstance = ClientManager()

    var socketQueue: dispatch_queue_t = dispatch_queue_create("clientSocketQueue", nil)
    let asyncSocket: GCDAsyncSocket = GCDAsyncSocket()

    var isConnected = false

    override init() {
        super.init()

        // Create our GCDAsyncSocket instance.
        //
        // Notice that we give it the normal delegate AND a delegate queue.
        // The socket will do all of its operations in a background queue,
        // and you can tell it which thread/queue to invoke your delegate on.
        // In this case, we're just saying invoke us on the main thread.
        // But you can see how trivial it would be to create your own queue,
        // and parallelize your networking processing code by having your
        // delegate methods invoked and run on background queues.
        self.asyncSocket.delegate = self
        self.asyncSocket.delegateQueue = self.socketQueue
    }


    func connectToHost(host: String) -> Bool {
        if self.isConnected {
            return true
        }

        do {
            try self.asyncSocket.connectToHost(host, onPort: HostManager.Port)
        } catch {
            print("Error connecting to host")
            return false
        }
        print("Connecting...")
        return true
    }

    func writeData(data: String) {
        let tempData = data + "\r\n"
        let msgData = tempData.dataUsingEncoding(NSUTF8StringEncoding)
        self.asyncSocket.writeData(msgData, withTimeout: -1, tag: 0)

        self.asyncSocket.readDataToData(GCDAsyncSocket.CRLFData(), withTimeout: -1, tag: 0)
    }

    func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        print("Did connect to host")

        self.isConnected = true

        dispatch_async(dispatch_get_main_queue()) {
            NSNotificationCenter.defaultCenter().postNotificationName(HostManager.ConnectionEstablishedNotification, object: nil, userInfo: nil)
        }

        let welcomeMsg = "Hello There\r\n";
        let welcomeData = welcomeMsg.dataUsingEncoding(NSUTF8StringEncoding)
        sock.writeData(welcomeData, withTimeout: -1, tag: 0)

        print("sending init connection")

        // Now we tell the socket to read the first line of the http response header.
        // As per the http protocol, we know each header line is terminated with a CRLF (carriage return, line feed).

        sock.readDataToData(GCDAsyncSocket.CRLFData(), withTimeout: -1, tag: 0)
    }

    func socketDidSecure(sock: GCDAsyncSocket!) {
        print("socket did secure")
    }

    func socket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
        print("Data was written")
    }

    func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {

        dispatch_async(dispatch_get_main_queue()) {
            let strData = data.subdataWithRange(NSMakeRange(0, data.length - 2))
            let msg = String(data: strData, encoding: NSUTF8StringEncoding)
            if let msg = msg {
                print(msg)
                NSNotificationCenter.defaultCenter().postNotificationName(HostManager.DataReceivedNotification, object: nil, userInfo: ["data": msg])
            } else {
                print("error converting received data")
            }
        }

        self.asyncSocket.readDataToData(GCDAsyncSocket.CRLFData(), withTimeout: -1, tag: 0)
    }

    func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        print("socket was disconnected")

        self.isConnected = false

        dispatch_async(dispatch_get_main_queue()) {
            NSNotificationCenter.defaultCenter().postNotificationName(HostManager.ConnectionLostNotification, object: nil, userInfo: nil)
        }
    }
}
