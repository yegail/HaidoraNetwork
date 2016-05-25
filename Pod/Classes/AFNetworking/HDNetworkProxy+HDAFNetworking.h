//
//  HDNetworkProxy+HDAFNetworking.h
//  Pods
//
//  Created by Dailingchi on 16/1/31.
//
//

#import "HDNetworkProxy.h"
#import <AFNetworking/AFNetworking.h>

@protocol HDNetworkAFNetworking <NSObject>

@optional

#pragma mark
#pragma mark Config AFNetworking

- (void)configureAFHTTPSessionManager:(AFHTTPSessionManager *)manager;

@end

@interface HDNetworkProxy (HDAFNetworking)

#pragma mark
#pragma mark Serializer

- (Class)loadRequestSerializerWith:(id<HDNetworkRequest>)request;
- (Class)loadResponseSerializerWith:(id<HDNetworkRequest>)request;

#pragma mark
#pragma mark AFNetworking
// TODO: 暂时不考虑AFNetwork3.x

- (void)configureManagerwithRequest:(id<HDNetworkRequest>)requeset;

//创建request
- (NSURLSessionDataTask *)loadRequest:
(id<HDNetworkRequest, HDNetworkValidator, HDNetworkRequestCallBack>)request
                     customURLRequest:(NSURLRequest *)customURLRequest
                           httpMethod:(HDRequestMethod)method
                            urlString:(NSString *)URLString
                           parameters:(id)parameters
                              success:(void (^)(NSURLSessionDataTask *dataTask, id responseObject))success
                              failure:(void (^)(NSURLSessionDataTask *dataTask, NSError *error))failure;

@end
