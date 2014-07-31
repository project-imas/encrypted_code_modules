//
//  AppIntegrity.m
//  iMAS_app_integrity
//
//  Created by Gregg Ganley on 3/17/14.
//  Copyright (c) 2014 Gregg Ganley. All rights reserved.
//


#import "AppIntegrity.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>
#import "SecureData.h"
#include <stdlib.h>
#include <dlfcn.h>
#import "SecureFoundation.h"


@interface FileOps : NSObject

+(void) writeDataToFile: (NSString *)fname dbuff:(NSData*)dbuff;

@end

@implementation FileOps


+(void) writeDataToFile: (NSString *)outFilePath  dbuff:(NSData *)dbuff
{
    
    //** open file for writing
    NSLog(@" outFilePath: %@", outFilePath);
    [dbuff writeToFile:outFilePath atomically:NO];
    
#if 0
    outFile = [NSFileHandle fileHandleForWritingAtPath: outFilePath];
    
    if(outFile == nil) {
        [[NSFileManager defaultManager] createFileAtPath:outFilePath contents:nil attributes:nil];
        outFile = [NSFileHandle fileHandleForWritingAtPath:outFilePath];
    }
    
    if (outFile == nil) {
        NSLog(@" open of outfile for writing failed!");
        exit(1);
    }
    
    // truncate the output file since it may contain data
    [outFile truncateFileAtOffset: 0];
    [outFile writeData: dbuff];
    [outFile closeFile];
#endif
    
}

@end


#define shazam @"felf.sld"
#define APP_INT_LIBNAME @"ecm_app_integrity_check.dylib"

@implementation AppIntegrity

//** do_app_integrity
//** read .sld file and decrypt, write file back out
+ (int) do_app_integrity: (NSString *)pass {
  
    //** read *this* APPS executable file
    NSFileHandle      *inFile;
    NSFileManager     *fileMgr;
    NSString          *filePath;
    NSError           *error;
    NSArray *directoryContent;
    
    
    //** debug file listing
    /*    NSString *s = [filePath stringByAppendingPathComponent:@"/"];
    NSLog(@"LISTING ALL FILES FOUND - %@", [s stringByDeletingLastPathComponent]);
    directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:NULL];
    for (int count = 0; count < (int)[directoryContent count]; count++) {
        NSLog(@"File %d: %@", (count + 1), [directoryContent objectAtIndex:count]);
    }
    NSLog(@"listing done");
    */
    
    NSLog(@"==========================");
    NSLog(@"Do App Integrity Start ...");
    
    //** set path for reading FELF file from the app bundle area - #define shazam
    fileMgr = [NSFileManager defaultManager];
    filePath = [[NSBundle mainBundle] pathForResource:shazam ofType:0 ];
    NSLog(@" filePath: %@", filePath);
    
    if ( [fileMgr fileExistsAtPath:filePath] == NO ) {
        NSLog(@"File does not exist!");
        return -1;
    }
    inFile = [NSFileHandle fileHandleForReadingAtPath: filePath];
    
    //** read FELF file in
    NSData *cipher_txt = [inFile readDataToEndOfFile];
    [inFile closeFile];
    
    NSLog(@"decrypting ECM lib ...");
    NSData *decrypted_plain_text = [SecureData decryptData:cipher_txt password:pass error:&error];
    if (error) {
        NSLog(@"decrypt error: %@", error);
        return -1;
    }
    
    ///    /var/mobile/Applications/7C3BA57E-0C08-454B-B4D0-C078B7C3BE16/Documents/APP_INT_LIBNAME
    NSLog(@"create ECM dylib file in docs dir...");
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *decrypted_dyn_plain_txt_filePath = [docPath stringByAppendingPathComponent:APP_INT_LIBNAME];
    
    //** iOS does not allow writing to bundle location, just reading
    //NSString *decrypted_dyn_plaint_txt_name = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:APP_INT_LIBNAME];
    NSLog(@"writing file into Docs dir %@", decrypted_dyn_plain_txt_filePath);
    //** create file first
    [[NSFileManager defaultManager] createFileAtPath:decrypted_dyn_plain_txt_filePath contents:nil attributes:nil];
    NSFileHandle *outFile = [NSFileHandle fileHandleForWritingAtPath:decrypted_dyn_plain_txt_filePath];
    //[FileOps writeDataToFile:decrypted_dyn_plaint_txt_name:decrypted_plain_text];
    @try
    {
        [outFile writeData:decrypted_plain_text];
    }
    @catch (NSException *e)
    {
        if (error != NULL)
        {
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey : @"Failed to write data",
                                       // Other stuff?
                                       };
            NSLog(@"%@", userInfo);
        }
        return -1;
    }
    
    [outFile closeFile];
    if ( [fileMgr fileExistsAtPath:decrypted_dyn_plain_txt_filePath] == NO ) {
        NSLog(@"File does not exist!");
        return -1;
    }

    /*
     //** this is a technique to load a function that has bundled as part of the app itself.
     //** may need this later.
     void (*init)() = dlsym(RTLD_MAIN_ONLY, "doAppIntegrity");
     if (init != NULL)  {
     init();
     }
     */
    
    //**
    //** Load Dynamic library that was simply copied into the doc dir
    docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *docPathFile = [docPath stringByAppendingPathComponent:APP_INT_LIBNAME];
    
    //** for testing- overwrite docs/imas_app_check derived from the decryption and just copy over the known good .dylib
    /*  NSString *appDirPath = [[NSBundle mainBundle] pathForResource:APP_INT_LIBNAME ofType:0 ];
     [fileMgr removeItemAtPath:docPathFile error:NULL];
     [[NSFileManager defaultManager] copyItemAtPath:appDirPath //bundlePath
     toPath:docPathFile
     error:&error];
     if (error) NSLog(@"encrypt error: %@", error);
     */
    
    //** debug file listing
    /* NSLog(@"LISTING ALL FILES FOUND 2 - %@", [filePath stringByDeletingLastPathComponent]);
     directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:NULL];
     for (int count = 0; count < (int)[directoryContent count]; count++) {
     NSLog(@"File %d: %@", (count + 1), [directoryContent objectAtIndex:count]);
     }
     
     //** debug file listing
     NSLog(@"LISTING ALL FILES FOUND 3- %@", docPath);
     directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docPath error:NULL];
     for (int count = 0; count < (int)[directoryContent count]; count++) {
     NSLog(@"File %d: %@", (count + 1), [directoryContent objectAtIndex:count]);
     }
    */
    
    //NSString *ff = [filePath2 stringByAppendingString:APP_INT_LIBNAME];
    //const char *dylibPath = [docPathFile cStringUsingEncoding:NSASCIIStringEncoding];
    
    //** read and open the dynamic library
//    void *libHandle = dlVolatileOpen(docPathFile);
    void * libHandle = dlopen([docPathFile UTF8String], RTLD_NOW);
    
    const char* msg = dlerror();
    if (msg) {
        NSLog(@"\n****\n%s\n****\n", msg);
        return -1;
    }
    
    int ret = 0;
    //** make a function call into the newly loaded library
    NSLog(@"calling into .dylib, performing intergrity check");
    if (libHandle != NULL) {
        
        int (*init)() = dlsym(libHandle, "doAppIntegrity");
        if (init != NULL)  {
            if(init() != 0)
                ret = -1;
        }
        NSLog(@"Shreding file on close!");
//        dlVolatileClose(libHandle);
        dlclose(libHandle);
    }
    else {
        NSLog(@"libHandle is NULL - check path!!");
        ret = -1;
    }
    
    return ret;
    
}


@end

