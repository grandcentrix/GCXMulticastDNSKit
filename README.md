# GCXMulticastDNSKit
 [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) ![Release](https://img.shields.io/github/release/grandcentrix/GCXMulticastDNSKit.svg) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![Cocoapods compatible](https://img.shields.io/cocoapods/v/GCXMulticastDNSKit.svg)](https://cocoapods.org/) 	


Multicast DNS framework for iOS

## Abtract

GCXMulticastDNSKit is a framework that can be used to discover network services that are announced on the local network. It is a wrapper for the network services provided by Apple.

## Introduction

mDNS is a service to resolve hostnames on a local network without the use of a central domain name server. Instead a resolving host simply sends a DNS query to a local multicast address and the host with that name responds with a multicast message with its IP address. Multicast DNS is also used in combination with DNS based service discovery where a host that provides a network service can announce its service to the local network. Those services can then be discovered using multicast messages

See: [1] [Multicast DNS](https://en.wikipedia.org/wiki/Multicast_DNS)
     [2] [Zeroconf Service discovery](https://en.wikipedia.org/wiki/Zero-configuration_networking#Service_discovery)

This framework currenlty provides functionality to discover services on the local network based on their service type and service name.

## Installation

### Cocoapods

```ruby
use_frameworks!

pod 'GCXMulticastDNSKit', :git => 'https://github.com/grandcentrix/GCXMulticastDNSKit.git', :tag => 'v1.3.1'

```

### Carthage

```ruby
git "https://github.com/grandcentrix/GCXMulticastDNSKit.git" ~> 1.3.1

```

### Swift Package Manager

[Swift Package Manager](https://swift.org/package-manager/) is a dependency manager built into Xcode. GCXMulticastDNSKit supports SPM from version 5.2.0.

If you are using Xcode 11 or higher, go to `File` -> `Swift Packages` -> `Add Package Dependency` and enter the [package repository URL](https://github.com/grandcentrix/GCXMulticastDNSKit.git), then follow the instructions.

## Usage

To use this framework we assume that you know the service type of the services (for example `_ptp._tcp` is valid service type for PTP/IP services, another example would be `_http._tcp`). Because there can be more than one service that provides functionality you can also specify an optional prefix for service name that must match. For the example below we are looking for PTP compatible cameras from Vendor A. Those announce themselves with a PTP service type and a services name of `Vendor A (#serialnr)`. We want to find all VendorA cameras on the local network so we use `_ptp._tcp` as service type and `Vendor A` as service name prefix:

```swift
let configurations = [DiscoveryConfiguration(serviceType: "_ptp._tcp",
                                           serviceNamePrefix: "Vendor A")]

discovery = Discovery(with: configurations, delegate: self)
discovery?.startDiscovery()

```

## License

```
Copyright 2017 grandcentrix GmbH

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
