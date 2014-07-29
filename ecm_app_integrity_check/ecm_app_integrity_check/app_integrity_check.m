//
//
//  Created by Ganley, Gregg on 2/4/13.
//  Copyright (c) 2013 MITRE Corp. All rights reserved.
//

#import "app_integrity_check.h"
#import <CommonCrypto/CommonDigest.h>

unsigned char sha256_placeholder[] =
{ 0xaa, 0xbb,    0xaa, 0xaa, 0xaa, 0xaa,    0xaa, 0xaa, 0xaa, 0xaa,    0xaa, 0xaa, 0xaa, 0xaa,    0xaa, 0xaa, 0xaa, 0xaa,    0xaa, 0xaa, 0xaa, 0xaa,   0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa,   0xbb, 0xaa };
             // 8e771664                 97432f2a                   74c8a55f                    2b943797                  77981fa5                   00000000
             // 00000000
//56b20ac6 061d9cc4 46021c08 61f2cb88 d0b23140 68d98b22 423bced5 702e925a };

//** int 32bit - EF BE AD DE
//unsigned int file_size_placeholder = 0xdeadbeef;
unsigned char file_size_placeholder[] = { 0xde, 0xad, 0xbe, 0xef };






NSString * helloWorld(NSString *s) {
    NSLog(@"helloWorld 22: %@", s);
    
    NSData *app_sha256 = [NSData dataWithBytes:sha256_placeholder  length:32];
    NSLog(@"%@", app_sha256);
    
    NSData *app_size = [NSData dataWithBytes:file_size_placeholder  length:4];
    int app_file_size;
    [app_size getBytes:&app_file_size length:sizeof(app_file_size)];
    
    NSLog(@"%d", app_file_size);
    
    return @"roger that gg 2014 iOS7";
}



NSData *get_sha256() {
    NSLog(@"here in get_sha256 -");
    
    NSData *app_sha256 = [NSData dataWithBytes:sha256_placeholder  length:32];
    NSLog(@"%@", app_sha256);
    
    return app_sha256;
}


NSData *get_fileSize() {
    NSLog(@"here in get_fileSize -");
    
    NSData *fsize = [NSData dataWithBytes:file_size_placeholder  length:8];
    NSLog(@"%@", fsize);
    
    return fsize;
}

#define AppName @"imas_ecm_demo_app"

void doAppIntegrity() {
    
    NSLog(@"  ******************************");
    NSLog(@"  Here in iMASAppIntegrity DYLIB");
    
    //** read
    
    
    //** read my APPS executable
    NSFileHandle      *inFile;
    NSFileManager     *fileMgr;
    NSString          *filePath;
    
    fileMgr = [NSFileManager defaultManager];
    //NSString *fileName = @"foo";
    
    //** open and read APP file into a data block
    filePath = [[NSBundle mainBundle] pathForResource:AppName ofType:0 ];
    NSLog(@" filePath: %@", filePath);
    
    if ( [fileMgr fileExistsAtPath:filePath] == NO ) {
        NSLog(@"File does not exist!");
        exit(1);
    }
    
    //** FILE SIZE
    inFile = [NSFileHandle fileHandleForReadingAtPath: filePath];
    NSData *plain_txt = [ inFile readDataToEndOfFile];
    unsigned int app_file_size = [plain_txt length];
    NSLog(@"AS-IS - APP file size: %d", app_file_size);
    [inFile closeFile];
    
    //** SHA256bit HASH
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256([plain_txt bytes], [plain_txt length], hash);
    NSData *app_sig = [NSData dataWithBytes:hash length:CC_SHA1_DIGEST_LENGTH];
    //NSData *sha_hash_val = IMSHashData_SHA256(plain_txt);
    NSLog(@"AS-IS - sha_hash_val 20 bytes: %@", app_sig);
    NSLog(@"app_sig_len:%d", [app_sig length]);
    
    
    NSData *trusted_app_sig = [NSData dataWithBytes:sha256_placeholder  length:CC_SHA1_DIGEST_LENGTH];
    NSLog(@"trusted app sig:%@", trusted_app_sig);
    NSLog(@"trusted app sig len:%d", [trusted_app_sig length]);
    
    NSData *trusted_app_size_data = [NSData dataWithBytes:file_size_placeholder  length:4];
    unsigned int trusted_app_size;
    [trusted_app_size_data getBytes:&trusted_app_size length:sizeof(trusted_app_size)];
    
    NSLog(@"trusted GG app size hex:%@", trusted_app_size_data);
    NSLog(@"trusted GG app size:%d", trusted_app_size);
    
    
    // compare computed sha hash to passed in value
    if (trusted_app_size != app_file_size)
        NSLog(@"App Integrity FAIL - file size mismatch");
    else
        NSLog(@"App Integrity PASS - file size match");
    
    if ([trusted_app_sig isEqualToData:app_sig])
        NSLog(@"App Integrity PASS - signature match");
    else
        NSLog(@"App Integrity FAIL - signature mismatch");

    
    
    
    // read .dylib, decode and write to file
}