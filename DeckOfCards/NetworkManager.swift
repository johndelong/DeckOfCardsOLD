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

    lazy var session: MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()

    // MARK - Streams
    lazy var connectedPeers = Variable<[MCPeerID]>(NetworkManager.shared.session.connectedPeers)
    lazy var communication = Variable<PacketProtocol?>(nil)

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

    // MARK - Communication Functions
    func send(packet: PacketProtocol) {
//        NSLog("%@", "sendColor: \(packet.type.displayName) to \(session.connectedPeers.count) peers")

        if !session.connectedPeers.isEmpty {
            do {
                try self.session.send(packet.encode(), toPeers: session.connectedPeers, with: .reliable)
            } catch let error {
                NSLog("%@", "Error for sending: \(error)")
            }
        }
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
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
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
        NSLog("%@", "foundPeer: \(peerID)")
        NSLog("%@", "invitePeer: \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }

}

extension NetworkManager : MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state)")

        self.connectedPeers.value = session.connectedPeers
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")

        self.communication.value = data.decode()
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
