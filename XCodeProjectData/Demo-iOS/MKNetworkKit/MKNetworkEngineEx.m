//
//  MKNetworkEngineEx.m
//  CordovaLib
//
//  Created by mac on 8/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MKNetworkEngineEx.h"

@implementation MKNetworkEngineEx


- (id) initWithHostName:(NSString*) hostName customHeaderFields:(NSDictionary*) headers
{
    if(self = [super initWithHostName:hostName customHeaderFields:headers])
    {
        self.OpInfoDictionary = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void) dealloc
{
    [self.OpInfoDictionary removeAllObjects];
    self.OpInfoDictionary = nil;
    
    if (_operationArray)
    {
        for(MKNetworkOperation* op in _operationArray)
        {
            if ([op isKindOfClass:[MKNetworkOperation class]])
                [op cancel];
        }
        [_operationArray removeAllObjects];
        [_operationArray release];
    }
    
    [super dealloc];
}

-(MKNetworkOperation*) downloadFileFrom:(NSString*)remoteURL toFile:(NSString*)filePath
{
    if ([OperationDictionary objectForKey:remoteURL]== nil)
    {
        MKNetworkOperation *op = [self operationWithURLString:remoteURL params:nil httpMethod:@"GET"] ;
        
        [op addDownloadStream:[NSOutputStream outputStreamToFileAtPath:filePath append:YES]];
        //加入系统的线程池队列
        //[self enqueueOperation:op];
        //加入队列方便索引和操作
        //[OperationDictionary setObject:op forKey:remoteURL];
            
        return op;
    }
    return nil;
}

- (MKNetworkOperation*)uploadFromFile:(NSString*)file fileName:(NSString*)fileName uploadUrl:(NSString*)url params:(NSMutableDictionary*)params
{
    NSLog(@"uploadFromFile: upload url=%@", url);
    
     if ([OperationDictionary objectForKey:file] == nil)
     {
         MKNetworkOperation *op = [self operationWithURLString:url 
                                                        params:params
                                                    httpMethod:@"POST"];
        
        [op addFile:file forKey:fileName];//fileName
        
        // setFreezable uploads your images after connection is restored!
        [op setFreezable:YES];
        
         [self enqueueOperation:op];
        //加入队列方便索引和操作
       
        //[OperationDictionary setObject:op forKey:file]; 
         return op;
    }
    
    return nil;
}

- (MKNetworkOperation*)httpGetData:(NSString*)remoteURL httpID:(NSString*)httpID params:(NSMutableDictionary*)body inMethods:(NSString*)inMethods
{
    
    if ([OperationDictionary objectForKey:remoteURL]== nil)
    {
        MKNetworkOperation *op = [self operationWithURLString:remoteURL 
                                                        params:body //[NSDictionary dictionaryWithObjectsAndKeys:
                                                                    //                 @"bobs@thga.me", @"email",
                                                                    //                 @"12345678", @"password", nil]
                                                    httpMethod:inMethods] ;
        
        //加入系统的线程池队列
        [self enqueueOperation:op];
        //加入队列方便索引和操作
        //[self.OperationDictionary setObject:op forKey:httpID];
        
        return op;
    }
    
    
    return nil;
}

@end
