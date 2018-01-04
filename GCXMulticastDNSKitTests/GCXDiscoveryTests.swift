//
//  GCXDiscoveryTests.swift
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

import XCTest
@testable import GCXMulticastDNSKit


class GCXDiscoveryTests: XCTestCase {
    
    var service: NetService?
    var didDiscoverExpectation: XCTestExpectation?

    var discovery: Discovery?
    
    override func tearDown() {
        service?.stop()
        discovery?.stopDiscovery()
        discovery = nil
    }
    
    func testThatInitialzationWithEmptyConfigurationReturnsNil() {
        let disovery = Discovery(with: [], delegate: self)
        XCTAssertNil(disovery)
    }
    
    func testThatInitialzationWithValidConfigurationReturnsObject() {
        let configuration = DiscoveryConfiguration(serviceType: "testService", serviceNamePrefix: nil)
        let disovery = Discovery(with: [configuration], delegate: self)
        XCTAssertNotNil(disovery)
    }
    
    func testThatInitialzationForClosuresWithEmptyConfigurationReturnsNil() {
        let disovery = Discovery(with: [], discoverHandler: nil, failHandler: nil, serviceRemovedHandler: nil)
        XCTAssertNil(disovery)
    }
    
    func testThatInitialzationForClosuresWithValidConfigurationReturnsObject() {
        let configuration = DiscoveryConfiguration(serviceType: "testService", serviceNamePrefix: nil)
        let disovery = Discovery(with: [configuration], discoverHandler: nil, failHandler: nil, serviceRemovedHandler: nil)
        XCTAssertNotNil(disovery)
    }
    
    func testThatDiscoveryIsStoppedBeforeStartingANewDiscovery() {
        let discoveryConfiguration = DiscoveryConfiguration(serviceType: "serviceType", serviceNamePrefix: nil)
        
        class DiscoveryMock : Discovery {
            var expectation: XCTestExpectation?
            
            override func stopDiscovery() {
                expectation?.fulfill()
                super.stopDiscovery()
            }
        }
        guard let discovery = DiscoveryMock(with: [ discoveryConfiguration], delegate: self) else {
            XCTAssertTrue(false, "Could not initialize discovery")
            return
        }
        
        discovery.expectation = self.expectation(description: "stopDiscovery is called before starting")
        discovery.startDiscovery()
        waitForExpectations(timeout: 0, handler: nil)
    }
    
    
    func testThatAPublishedServiceIsDiscoveredUsingDelegate() {
        service = NetService(domain: "", type: "_http._tcp", name: "GCXDNSKitTest", port: 10000 )
        service?.publish()
        
        let discoveryConfiguration = DiscoveryConfiguration(serviceType: "_http._tcp", serviceNamePrefix: "GCXDNSKitTest")
        
        guard let discovery = Discovery(with: [ discoveryConfiguration], delegate: self) else {
            XCTAssertTrue(false, "Could not initialize discovery")
            return
        }
        
        self.discovery = discovery
        didDiscoverExpectation = self.expectation(description: "disovery did discover service")
        discovery.startDiscovery()
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testThatAPublishedServiceIsDiscoveredUsingClosures() {
        service = NetService(domain: "", type: "_http._tcp", name: "GCXDNSKitTest", port: 10000 )
        service?.publish()
        
        didDiscoverExpectation = self.expectation(description: "disovery did discover service")

        let discoveryConfiguration = DiscoveryConfiguration(serviceType: "_http._tcp", serviceNamePrefix: "GCXDNSKitTest")
         guard let discovery = Discovery(with: [ discoveryConfiguration ], discoverHandler: { [unowned self] (service) in
            self.didDiscoverExpectation?.fulfill()
        }, failHandler: nil, serviceRemovedHandler: nil) else {
            XCTAssertTrue(false, "Could not initialize discovery")
            return
        }
        
        self.discovery = discovery
        discovery.startDiscovery()
        waitForExpectations(timeout: 10, handler: nil)
    }
}

extension GCXDiscoveryTests: DiscoveryDelegate{
    
    func discoveryDidDiscover(service: DiscoveryService) {
        didDiscoverExpectation?.fulfill()
     }
    
    func discoveryDidDisappear(service: DiscoveryService) {
    }
    
    func discoveryDidFail(configuration: DiscoveryConfiguration, error: DiscoveryError) {
    }
}
