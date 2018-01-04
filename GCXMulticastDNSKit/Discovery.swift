//
//  Discovery.swift
//  GCXMulticastDNSKit
//
//  Copyright 2017 grandcentrix GmbH
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import Foundation

public typealias DiscoveryDiscoverHandler = (DiscoveryService) -> Void
public typealias DiscoveryFailHandler = (DiscoveryConfiguration, DiscoveryError) -> Void
public typealias DiscoveryServiceRemovedHandler = (DiscoveryService) -> Void


/// a private class that encapsulates all information for a specific service discovery
private class DiscoveryItem {
    
    /// the configuration used for this discovery
    var configuration: DiscoveryConfiguration
    
    /// the net service browser used to discover this service
    var netServiceBrowser = NetServiceBrowser()
    
    /// the found net services
    var netServices: Set<NetService> = Set()
    
    
    /// designated initializer, must be initialized with a configuration
    ///
    /// - Parameter configuration: the configuration
    init(with configuration: DiscoveryConfiguration) {
        self.configuration = configuration
    }
    
    
    /// checks if a service instance is valid for this discovery configuration
    ///
    /// - Parameter netService: the net service to check
    /// - Returns: true if the net service matches the configuration's spec, else false
    func isValidForService(netService: NetService) -> Bool {
        guard let serviceNamePrefix = configuration.serviceNamePrefix else {
            // when no service name prefix is specified, all services are valid
            return true
        }
        return netService.name.hasPrefix(serviceNamePrefix)
    }
}


/// a structure to enapsulate the result of a service discovery, this is returned
public class DiscoveryService: NSObject {
    
    /// the configuration used to search
    public let configuration: DiscoveryConfiguration
    
    /// the found service
    public let netService: NetService
    
    init(configuration: DiscoveryConfiguration, netService: NetService) {
        self.configuration = configuration
        self.netService  = netService
        super.init()
    }
}


/// the errors that can occur whilst searching for services
///
/// - unknown: a unknown error
/// - browsingFailure: failed to browse
/// - resolvingTimeout: timeout while resolving
/// - resolvingFailure: a general failure while resolving
public enum DiscoveryError: Int, Error {
    case unknown
    case browsingFailure
    case resolvingTimeout
    case resolvingFailure
}


/// the protocol used for the delegate
public protocol DiscoveryDelegate {
    
    /// called when a service has been discovered and resolved. Can be called multiple times for a
    /// search when more than one matching service is found. Is only called while in search mode.
    ///
    /// - Parameter service: the found service
    func discoveryDidDiscover(service: DiscoveryService)
    
    
    /// called when the discovery for a configuration fails. Can be called multiple times for a
    /// search when more than one matching service is present and some of them fail to resolve.
    /// Is only called while in search mode.
    ///
    /// - Parameters:
    ///   - configuration: the configuration
    ///   - error: the reason for the fail
    func discoveryDidFail(configuration: DiscoveryConfiguration, error: DiscoveryError)
    
    
    /// called when a service disappers, can be called multiple times. Is only called while in search mode.
    ///
    /// - Parameter service: the service that disappeared
    func discoveryDidDisappear(service: DiscoveryService)
}

// MARK: - public interface


/// the class to use to discover service on the network. Initialize a new instance with an array of
/// configurations and start the search.
public class Discovery: NSObject {

    
    /// the default search domain, empty string means .local. 
    /// Should be sufficient for 99% of the use cases
    fileprivate let defaultMDNSDomain = ""
    
    /// the timeout for resolving a service
    fileprivate var serviceResolveTimeout: TimeInterval
    
    /// the configurations used for the search
    fileprivate var configurations: [DiscoveryConfiguration]
    
    /// the local models to manage the search
    fileprivate var items: [DiscoveryItem]?
    
    /// the delegate
    public var delegate: DiscoveryDelegate?
    
    
    /// the completion closures
    fileprivate var discoverHandler: DiscoveryDiscoverHandler?
    fileprivate var failHandler: DiscoveryFailHandler?
    fileprivate var serviceRemovedHandler: DiscoveryServiceRemovedHandler?
    
    /// the designated initializer. creates a new discovery for the specified configurations
    ///
    /// - Parameters:
    ///   - configurations: an array of GCXDiscoveryConfiguration instance. Must contain at least one config or the init will fail
    ///   - delegate: the delegate
    public init?(with configurations: [DiscoveryConfiguration],
                 delegate: DiscoveryDelegate,
                 serviceResolveTimeout: TimeInterval = 10) {
        guard configurations.count > 0 else {
            return nil
        }
        
        self.configurations = configurations
        self.delegate = delegate
        self.serviceResolveTimeout = serviceResolveTimeout
    }
    
    public init?(with configurations: [DiscoveryConfiguration],
                 discoverHandler: DiscoveryDiscoverHandler?,
                 failHandler: DiscoveryFailHandler?,
                 serviceRemovedHandler: DiscoveryServiceRemovedHandler?,
                 serviceResolveTimeout: TimeInterval = 10) {
        guard configurations.count > 0 else {
            return nil
        }
        
        self.configurations = configurations
        self.discoverHandler = discoverHandler
        self.failHandler = failHandler
        self.serviceRemovedHandler = serviceRemovedHandler
        self.serviceResolveTimeout = serviceResolveTimeout
    }
    
    /// starts the discovery process
    public func startDiscovery() {
        stopDiscovery()
        initializeItems()
    }
    
    /// stops the discovery process
    public func stopDiscovery() {
        stopSearchingAndResolving()
    }
}

// MARK: - private methods
extension Discovery {
    
    /// creates the models from the configurations and starts the search for the services
    fileprivate func initializeItems() {
        items = configurations.map {
            let item = DiscoveryItem( with: $0)
            item.netServiceBrowser.delegate = self
            item.netServiceBrowser.searchForServices(ofType: item.configuration.serviceType, inDomain: defaultMDNSDomain)
            return item
        }
    }
    
    /// stops all search and resolve operations
    fileprivate func stopSearchingAndResolving() {
        let _ = items?.map {
            $0.netServiceBrowser.stop()
            let _ = $0.netServices.map { $0.stop() }
        }
        
        items = nil
    }
    
    /// lookup for an item from a net service
    fileprivate func item(service: NetService) -> DiscoveryItem? {
        guard let item = items?.filter({ (discoveryItem) -> Bool in
            return discoveryItem.netServices.contains(service)
        }).first else {
            return nil
        }
        
        return item
    }
    
    /// lookup for an item from a net service browser
    fileprivate func item(serviceBrowser: NetServiceBrowser) -> DiscoveryItem? {
        guard let item = items?.filter({ (discoveryItem) -> Bool in
            return discoveryItem.netServiceBrowser == serviceBrowser
        }).first else {
            return nil
        }
        
        return item
    }
}

// MARK: - Delegate notifiction helpers
extension Discovery {
    fileprivate func notifyDiscoveryDidDiscover(service: DiscoveryService) {
        DispatchQueue.main.async { [weak self] () -> Void in
            self?.delegate?.discoveryDidDiscover(service: service)
            self?.discoverHandler?(service)
        }
    }
    
    fileprivate func notifyDiscoveryDidFail(configuration: DiscoveryConfiguration, error: DiscoveryError) {
        DispatchQueue.main.async { [weak self] () -> Void in
            self?.delegate?.discoveryDidFail(configuration: configuration, error: error)
            self?.failHandler?(configuration, error)
        }
    }
    
    fileprivate func notifyDiscoveryServiceDidDisappear(service: DiscoveryService) {
        DispatchQueue.main.async { [weak self] () -> Void in
            self?.delegate?.discoveryDidDisappear(service: service)
            self?.serviceRemovedHandler?(service)
        }
    }
}

// MARK: - NetServiceBrowserDelegate
extension Discovery: NetServiceBrowserDelegate {
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        guard let item = item(serviceBrowser: browser) else {
            return
        }
        
        if item.isValidForService(netService: service) {
            item.netServices.insert(service)
            service.delegate = self
            service.resolve(withTimeout: serviceResolveTimeout)
        }
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        guard let item = item(serviceBrowser: browser) else {
            return
        }

        notifyDiscoveryDidFail(configuration: item.configuration, error: .browsingFailure)
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        guard let item = item(service: service) else {
            return
        }

        item.netServices.remove(service)
        
        notifyDiscoveryServiceDidDisappear(service: DiscoveryService(configuration: item.configuration, netService: service))
    }
}

// MARK: - NetServiceDelegate
extension Discovery: NetServiceDelegate {
    
    public func netServiceDidResolveAddress(_ sender: NetService) {
        guard let item = item(service: sender) else {
            return
        }
        
        notifyDiscoveryDidDiscover(service: DiscoveryService(configuration: item.configuration, netService: sender))
    }
    
    public func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        guard let item = item(service: sender) else {
            return
        }
        
        notifyDiscoveryDidFail(configuration: item.configuration, error: .resolvingFailure)
    }
}
