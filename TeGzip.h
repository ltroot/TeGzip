//
//  Gzip.h
//
//
//  Created by ltroot on 2011/8/5.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//
//  使用備註：記得在Build Phases的Link Binary With Libraries加入libz.dylib

#import <Foundation/Foundation.h>
#import "zlib.h"

@interface TeGzip : NSObject {
    
}

+ (NSData *)gzipCompressString: (NSString *)inputString;
+ (NSString *)gzipDecompressString: (NSData *)inputGzip;

+ (NSString *)dataToString: (NSData *)data;

@end
