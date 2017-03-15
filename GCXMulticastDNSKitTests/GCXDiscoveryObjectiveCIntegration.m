//
//  GCXDiscoveryObjectiveCIntegration.m
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

#import <XCTest/XCTest.h>

@import GCXMulticastDNSKit;

@interface GCXDiscoveryObjectiveCIntegration : XCTestCase <GCXDiscoveryDelegate>

@end

@implementation GCXDiscoveryObjectiveCIntegration



- (void)testIntegration {
    GCXDiscoveryConfiguration *configuration = [[GCXDiscoveryConfiguration alloc] initWithServiceType:@"testService" serviceNamePrefix:nil];
    
    NSArray *configs = @[ configuration ];
    GCXDiscovery *discovery = [[GCXDiscovery alloc]initWith:configs delegate:self serviceResolveTimeout:10];
    XCTAssertNotNil(discovery);
}



#pragma mark - GCXDiscoveryDelegate

- (void)discoveryDidDiscoverWithService:(GCXDiscoveryService * _Nonnull)service {
}

- (void)discoveryDidFailWithConfiguration:(GCXDiscoveryConfiguration * _Nonnull)configuration error:(enum GCXDiscoveryError)error {
}

- (void)discoveryDidDisappearWithService:(GCXDiscoveryService * _Nonnull)service {
}

@end
