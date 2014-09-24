//
//  MKNetworkEngineEx.h
//  CordovaLib
//
//  Created by mac on 8/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MKNetworkKit.h"

typedef struct
{
    NSString            *httpID;
    NSString            *url;
    NSInteger           status;
    MKNetworkOperation  *op;
} OPinfo;

@interface MKNetworkEngineEx : MKNetworkEngine
{
    NSMutableDictionary* OperationDictionary;
}

@property (atomic, readwrite, strong) NSMutableDictionary* OpInfoDictionary;
@property (atomic, readwrite, strong) NSMutableArray* operationArray;

//@property (atomic, readwrite, strong) NSMutableDictionary* OperationDictionary;

- (id) initWithHostName:(NSString*) hostName customHeaderFields:(NSDictionary*) headers;

- (MKNetworkOperation*)downloadFileFrom:(NSString*)remoteURL toFile:(NSString*)filePath;
- (MKNetworkOperation*)uploadFromFile:(NSString*)file fileName:(NSString*)fileName uploadUrl:(NSString*)url params:(NSMutableDictionary*)params;
- (MKNetworkOperation*)httpGetData:(NSString*)remoteURL httpID:(NSString*)httpID params:(NSMutableDictionary*)body inMethods:(NSString*)inMethods;

@end
