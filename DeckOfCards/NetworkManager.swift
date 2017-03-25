//
//  NetworkManager.swift
//  DeckOfCards
//
//  Created by John DeLong on 2/25/17.
//  Copyright © 2017 MichiganLabs. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import RxSwift

class NetworkManager: NSObject {
    let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser

    // Sessions are created by advertisers, and passed to peers when accepting an invitation to connect
    lazy var session: MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        return session
    }()

    // MARK - Streams
    lazy var connectedPeers = Variable<[MCPeerID]>(NetworkManager.shared.session.connectedPeers)

    fileprivate let communicationStream = Variable<PacketProtocol?>(nil)
    lazy var communication: Observable<PacketProtocol?> = {
        return self.communicationStream.asObservable()
    }()

    // Service type must be a unique string, at most 15 characters long
    // and can contain only ASCII lowercase letters, numbers and hyphens.
    private let GameServiceType = "deck-of-cards"

    static let shared = NetworkManager()
    private override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(
            peer: myPeerId,
            discoveryInfo: nil,
            serviceType: GameServiceType
        )
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: GameServiceType)

        super.init()

        self.serviceAdvertiser.delegate = self
        self.serviceBrowser.delegate = self
    }

    deinit {
        self.stopSearching()
    }

    func startSearching() {
        self.serviceAdvertiser.startAdvertisingPeer()
        self.serviceBrowser.startBrowsingForPeers()
    }

    func stopSearching() {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }

    func disconnect() {
        self.stopSearching()
        self.session.disconnect()
    }

    static var me: MCPeerID {
        return NetworkManager.shared.myPeerId
    }

    // MARK - Communication Functions
    func send(packet: PacketProtocol) {
        do {
            // Send to all users...
            if !session.connectedPeers.isEmpty {
                try self.session.send(packet.encode(), toPeers: session.connectedPeers, with: .reliable)
            }

            // ...including me!
            self.communicationStream.value = packet
        } catch let error {
            NSLog("%@", "Error for sending: \(error)")
        }
    }

    func sendToMe(packet: PacketProtocol) {
        self.communicationStream.value = packet
    }
}

extension NetworkManager: MCNearbyServiceAdvertiserDelegate {
    // Advertising did not start due to an error.
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }

    // Incoming invitation request.  Call the invitationHandler block with YES
    // and a valid session to connect the inviting peer to the session.
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)") // Somebody would like to join my game
        let canJoin = self.session.connectedPeers.count < GameManager.shared.maxPlayers - 1
        invitationHandler(canJoin, self.session) // Let them play!
    }
}

extension NetworkManager : MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String : String]?
    ) {
        NSLog("%@", "foundPeer: \(peerID)") // Hey, I found a game to join
        NSLog("%@", "invitePeer: \(peerID)") // Lets see if I can play with them
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }

}

extension NetworkManager : MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.rawValue)")
        self.connectedPeers.value = session.connectedPeers
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")

        self.communicationStream.value = data.decode()
    }

    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        NSLog("%@", "didReceiveStream")
    }

    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }

    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL,
        withError error: Error?
    ) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
}
