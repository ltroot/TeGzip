//
//  Gzip.m
//
//
//  Created by ltroot on 2011/8/5.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "TeGzip.h"

@implementation TeGzip

+ (NSData *)gzipCompressString: (NSString *)inputString
{
    NSData *uncompressedData = [inputString dataUsingEncoding:NSUTF8StringEncoding];
    
    if( !uncompressedData || ([uncompressedData length] == 0) )
    {
#if DEBUG
        NSLog(@"%s 錯誤 : 不能壓縮空的字串", __func__);
#endif
        return nil;
    }

    z_stream zlibStreamStruct;
    zlibStreamStruct.zalloc = Z_NULL;
    zlibStreamStruct.zfree = Z_NULL;
    zlibStreamStruct.opaque = Z_NULL;
    zlibStreamStruct.total_out = 0;
    zlibStreamStruct.next_in = (Bytef*)[uncompressedData bytes];
    zlibStreamStruct.avail_in = [uncompressedData length];

    gz_header header;
    memset(&header, 0, sizeof(gz_header));
    header.time = (unsigned long)[[NSDate date] timeIntervalSince1970];
    header.os = 255;
    deflateSetHeader(&zlibStreamStruct, &header);
    
    int initError = deflateInit2(&zlibStreamStruct, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY);
    if(initError != Z_OK)
    {
        NSString *errorMsg = nil;
        switch (initError) {
            case Z_STREAM_ERROR:
                errorMsg = @"送入的參數無效";
                break;
            case Z_MEM_ERROR:
                errorMsg = @"記憶體不足";
                break;
            case Z_VERSION_ERROR:
                errorMsg = @"zlib.h跟連結的函式庫版本不同";
                break;
            default:
                errorMsg = @"未知的錯誤";
                break;
        }
#if DEBUG
        NSLog(@"%s: deflateInit2() Error: \"%@\" Message: \"%s\"", __func__, errorMsg, zlibStreamStruct.msg);
#endif
        return nil;
    }
    
    NSMutableData *compressedData = [NSMutableData dataWithLength:[uncompressedData length]*2+12];
    
    int deflateStatus;
    do{
        zlibStreamStruct.next_out = [compressedData mutableBytes] + zlibStreamStruct.total_out;
        zlibStreamStruct.avail_out = [compressedData length] - zlibStreamStruct.total_out;
        deflateStatus = deflate(&zlibStreamStruct, Z_FINISH);
    } while ( deflateStatus == Z_OK );
    
    if(deflateStatus != Z_STREAM_END)
    {
        NSString *errorMsg = nil;
        switch (deflateStatus) {
            case Z_ERRNO:
                errorMsg = @"讀檔時發生錯誤";
                break;
            case Z_STREAM_ERROR:
                errorMsg = @"串流狀態不一致（例如next_in或next_out為NULL）";
                break;
            case Z_DATA_ERROR:
                errorMsg = @"抽取出來的資料無效或不完整";
                break;
            case Z_MEM_ERROR:
                errorMsg = @"在處理的過程中無法分配記憶體";
                break;
            case Z_BUF_ERROR:
                errorMsg = @"輸出緩衝區已經被寫入壓縮的bytes用完";
                break;
            case Z_VERSION_ERROR:
                errorMsg = @"zlib.h跟連結的函式庫版本不同";
                break;
            default:
                errorMsg = @"未知的錯誤";
                break;
        }
#if DEBUG
        NSLog(@"%s: zlib在嘗試壓縮的過程中發生錯誤: \"%@\" Message: \"%s\"", __func__, errorMsg, zlibStreamStruct.msg);
#endif
        deflateEnd(&zlibStreamStruct);
        return nil;
    }
    deflateEnd(&zlibStreamStruct);
    [compressedData setLength:zlibStreamStruct.total_out];
#if DEBUG
    NSLog(@"%s: 壓縮內容從 %d Bytes 變成 %d Bytes", __func__, [uncompressedData length], [compressedData length]);
#endif
    return compressedData;
}

+ (NSString *)gzipDecompressString: (NSData *)inputGzip
{
    if ( !inputGzip || ([inputGzip length] == 0) )
    {
#if DEBUG
        NSLog(@"%s 錯誤 : 不能解壓縮空的Data", __func__);
#endif
        return nil;
    }
    
    z_stream zlibStreamStruct;
    zlibStreamStruct.next_in = (Bytef*)[inputGzip bytes];
    zlibStreamStruct.avail_in = [inputGzip length];
    zlibStreamStruct.total_out = 0;
    zlibStreamStruct.zalloc = Z_NULL;
    zlibStreamStruct.zfree = Z_NULL;
    
    int initError = inflateInit2(&zlibStreamStruct, (15+32));
    if( initError != Z_OK )
    {
        NSString *errorMsg = nil;
        switch (initError) {
            case Z_STREAM_ERROR:
                errorMsg = @"送入的參數無效";
                break;
            case Z_MEM_ERROR:
                errorMsg = @"記憶體不足";
                break;
            case Z_VERSION_ERROR:
                errorMsg = @"zlib.h跟連結的函式庫版本不同";
                break;
            default:
                errorMsg = @"未知的錯誤";
                break;
        }
#if DEBUG
        NSLog(@"%s: zlib在嘗試解壓縮的過程中發生錯誤: \"%@\" Message: \"%s\"", __func__, errorMsg, zlibStreamStruct.msg);
#endif
        inflateEnd(&zlibStreamStruct);
        return nil;
    }
    
    NSMutableData *decompressedData = [NSMutableData dataWithLength:[inputGzip length] + [inputGzip length]/2 ];
    int deflateStatus;
    do{
        if( zlibStreamStruct.total_out >= [decompressedData length] )
        {
            [decompressedData increaseLengthBy: ([inputGzip length]/2)];
        }
        zlibStreamStruct.next_out = [decompressedData mutableBytes] + zlibStreamStruct.total_out;
        zlibStreamStruct.avail_out = [decompressedData length] - zlibStreamStruct.total_out;
        
        deflateStatus = inflate(&zlibStreamStruct, Z_SYNC_FLUSH);
    } while (deflateStatus == Z_OK);
    
    if(deflateStatus != Z_STREAM_END)
    {
        NSString *errorMsg = nil;
        switch (deflateStatus) {
            case Z_ERRNO:
                errorMsg = @"讀檔時發生錯誤";
                break;
            case Z_STREAM_ERROR:
                errorMsg = @"串流狀態不一致（例如next_in或next_out為NULL）";
                break;
            case Z_DATA_ERROR:
                errorMsg = @"抽取出來的資料無效或不完整";
                break;
            case Z_MEM_ERROR:
                errorMsg = @"在處理的過程中無法分配記憶體";
                break;
            case Z_BUF_ERROR:
                errorMsg = @"輸出緩衝區已經被寫入壓縮的bytes用完";
                break;
            case Z_VERSION_ERROR:
                errorMsg = @"zlib.h跟連結的函式庫版本不同";
                break;
            default:
                errorMsg = @"未知的錯誤";
                break;
        }
#if DEBUG
        NSLog(@"%s: zlib在嘗試壓縮的過程中發生錯誤: \"%@\" Message: \"%s\"", __func__, errorMsg, zlibStreamStruct.msg);
#endif
        inflateEnd(&zlibStreamStruct);
        return nil;
    }
    inflateEnd(&zlibStreamStruct);
    [decompressedData setLength:zlibStreamStruct.total_out];
#if DEBUG
    NSLog(@"%s: 壓縮內容從 %d Bytes 變成 %d Bytes", __func__, [inputGzip length], [decompressedData length]);
#endif
    return [TeGzip dataToString:decompressedData];
}

+ (NSString *)dataToString: (NSData *)data
{
    NSString *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    return str;
}

@end
