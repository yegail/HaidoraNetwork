//
//  HDNetworkProxy+HDAFNetworking.m
//  Pods
//
//  Created by Dailingchi on 16/1/31.
//
//

#import "HDNetworkProxy+HDAFNetworking.h"
#import "HDNetworkConfig.h"
#import "HDNetworkProxy+HDNetworkProxyUtils.h"
#import <AFNetworking/AFNetworking.h>
#import <objc/runtime.h>

static char *kHDNetworkProxy_manager = "kHDNetworkProxy_manager";

@interface HDNetworkProxy (HDNetwork)

@property (nonatomic, strong) AFHTTPSessionManager *manager;

@end

@implementation HDNetworkProxy (HDNetwork)

@dynamic manager;

- (void)setManager:(AFHTTPSessionManager *)manager
{
    objc_setAssociatedObject(self, &kHDNetworkProxy_manager, manager,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (AFHTTPSessionManager *)manager
{
    AFHTTPSessionManager *manager =
    objc_getAssociatedObject(self, &kHDNetworkProxy_manager);
    if (nil == manager)
    {
        manager = [AFHTTPSessionManager manager];
        manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        manager.operationQueue.maxConcurrentOperationCount = 4;
        [self setManager:manager];
    }
    return manager;
}

@end

@implementation HDNetworkProxy (HDAFNetworking)

#pragma mark
#pragma mark Serializer

- (Class)loadRequestSerializerWith:(id<HDNetworkRequest>)request
{
    Class serializerClass = [AFHTTPRequestSerializer class];
    // default Serializer
    if ([request respondsToSelector:@selector(requestSerializerType)])
    {
        HDSerializerType serializerType = [request requestSerializerType];
        if (serializerType == HDSerializerTypeHTTP)
        {
            serializerClass = [AFHTTPRequestSerializer class];
        }
        else if (serializerType == HDSerializerTypeJSON)
        {
            serializerClass = [AFJSONRequestSerializer class];
        }
    }
    
    // custom Serializer
    if ([request respondsToSelector:@selector(requestSerializerClass)] &&
        [request requestSerializerClass])
    {
        Class serializer = [request requestSerializerClass];
        if ([serializer isSubclassOfClass:[AFHTTPRequestSerializer class]])
        {
            serializerClass = serializer;
        }
        else
        {
            NSAssert(FALSE, @"%@ must be subClass of AFHTTPRequestSerializer",
                     NSStringFromClass(serializer));
        }
    }
    return serializerClass;
}

- (Class)loadResponseSerializerWith:(id<HDNetworkRequest>)request
{
    Class serializerClass = [AFHTTPResponseSerializer class];
    // default Serializer
    if ([request respondsToSelector:@selector(responseSerializerType)])
    {
        HDSerializerType serializerType = [request responseSerializerType];
        if (serializerType == HDSerializerTypeHTTP)
        {
            serializerClass = [AFHTTPResponseSerializer class];
        }
        else if (serializerType == HDSerializerTypeJSON)
        {
            serializerClass = [AFJSONResponseSerializer class];
        }
    }
    
    // custom Serializer
    if ([request respondsToSelector:@selector(responseSerializerClass)] &&
        [request requestSerializerClass])
    {
        Class serializer = [request responseSerializerClass];
        if ([serializer isSubclassOfClass:[AFHTTPResponseSerializer class]])
        {
            serializerClass = serializer;
        }
        else
        {
            NSAssert(FALSE, @"%@ must be subClass of AFHTTPResponseSerializer",
                     NSStringFromClass(serializer));
        }
    }
    return serializerClass;
}

#pragma mark
#pragma mark AFNetworking

/**
 *  请求的相关配置
 */
- (void)configureManagerwithRequest:(id<HDNetworkRequest>)requeset
{
    AFHTTPSessionManager *manager = self.manager;
    //设置序列化
    manager.requestSerializer = [[self loadRequestSerializerWith:requeset] serializer];
    manager.responseSerializer = [[self loadResponseSerializerWith:requeset] serializer];
    //请求超时
    manager.requestSerializer.timeoutInterval = [self loadRequestTimeoutIntervalWith:requeset];
    // setAuthorizationHeaderFieldWithUsername
    // headerFieldValueDictionary
    NSDictionary *requestHeaderField = [self loadRequestHeaderFieldWith:requeset];
    [requestHeaderField
     enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
         if ([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]])
         {
             [manager.requestSerializer setValue:obj forHTTPHeaderField:key];
         }
         else
         {
             //          YTKLog(@"Error, class of key/value in headerFieldValueDictionary shouldbe
             //          NSString.");
         }
     }];
    if ([requeset conformsToProtocol:@protocol(HDNetworkAFNetworking)] &&
        [requeset respondsToSelector:@selector(configureAFHTTPSessionManager:)])
    {
        [(id<HDNetworkAFNetworking>)requeset configureAFHTTPSessionManager:manager];
    }
}

- (NSURLSessionDataTask *)loadRequest:
(id<HDNetworkRequest, HDNetworkValidator, HDNetworkRequestCallBack>)request
                     customURLRequest:(NSURLRequest *)customURLRequest
                           httpMethod:(HDRequestMethod)method
                            urlString:(NSString *)URLString
                           parameters:(id)parameters
                              success:(void (^)(NSURLSessionDataTask *dataTask, id responseObject))success
                              failure:(void (^)(NSURLSessionDataTask *dataTask, NSError *error))failure
{
    AFHTTPSessionManager *manager = self.manager;
    NSURLSessionDataTask *dataTask;
    
    //自定义request
    if (nil != customURLRequest)
    {
        dataTask = [manager dataTaskWithRequest:customURLRequest completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            if (error) {
                if (failure) {
                    
                }
            }
        }];
        [dataTask resume];
    }
    else
    {
        switch (method)
        {
            case HDRequestMethodGet:
            {
                // TODO: 暂时不支持文件下载
                dataTask = [manager GET:URLString parameters:parameters success:success failure:failure];
                break;
            }
            case HDRequestMethodPost:
            {
                dataTask = [manager POST:URLString parameters:parameters success:success failure:failure];
                break;
            }
            case HDRequestMethodHead:
            {
                dataTask = [manager HEAD:URLString parameters:parameters  success:^(NSURLSessionDataTask * _Nonnull task) {
                    if (success) {
                        success(task, nil);
                    }
                } failure:failure];
                break;
            }
            case HDRequestMethodPut:
            {
                dataTask = [manager PUT:URLString parameters:parameters success:success failure:failure];            break;
            }
            case HDRequestMethodDelete:
            {
                dataTask = [manager DELETE:URLString parameters:parameters success:success failure:failure];
                break;
            }
            case HDRequestMethodPatch:
            {
                dataTask = [manager PATCH:URLString parameters:parameters success:success failure:failure];
                break;
            }
            default:
                break;
        }
    }
    return dataTask;
}

@end
