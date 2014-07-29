//
//  main.m
//  iMAS_file_cipher
//
//  Created by Gregg Ganley on 3/11/14.
//  Copyright (c) 2014 Gregg Ganley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "SecureData.h"


void usage(void)
{
	NSLog(@"Usage:\n");
	NSLog(@" -f <hostAppFileName>\n");
    NSLog(@" -d <dynamicLibFileName>\n");
    NSLog(@" -k <8 char appkey>\n");
	exit (8);
}

@interface FileOps : NSObject
 
+(void) writeDataToFile: (NSString *)fname
                  dbuff:(NSData*)dbuff;

@end

@implementation FileOps


+(void) writeDataToFile: (NSString *)fname
                  dbuff:(NSData *)dbuff
{
    NSFileHandle   *outFile;
    
    //** open file for writing
    NSString *outFilePath = [NSString stringWithFormat:@"%@", fname];
    NSLog(@" outFilePath: %@", outFilePath);
    
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
    
}

@end

int main(int argc, const char * argv[])
{
    
    
    @autoreleasepool {
        
        NSString *hostAppFileName;
        NSString *dynamicLibFileName;
        NSString *appkey;
        
        NSLog(@"iMAS Encrypted Code Module Builder ... ");
        
        NSUserDefaults *args = [NSUserDefaults standardUserDefaults];
        
        //NSLog(@"boolArg   = %d", [args boolForKey:@"boolArg"]);
        //NSLog(@"intArg    = %d", [args integerForKey:@"intArg"]);
        //NSLog(@"floatArg  = %f", [args floatForKey:@"floatArg"]);
        NSLog(@"stringArg = %@", [args stringForKey:@"f"]);
        hostAppFileName = [args stringForKey:@"f"];
        
        NSLog(@"stringArg = %@", [args stringForKey:@"d"]);
        dynamicLibFileName = [args stringForKey:@"d"];
        
        NSLog(@"stringArg = %@", [args stringForKey:@"k"]);
        appkey = [args stringForKey:@"k"];
        

        if (!hostAppFileName) {
            NSLog(@"no host app file name specified");
            usage();
        }
        else {
            NSLog(@"host app fn is: %@\n", hostAppFileName);
        }
        
        if (!dynamicLibFileName) {
            NSLog(@"no dynamic lib file name specified");
            usage();
        }
        else {
            NSLog(@"dynamic host fn is: %@\n", dynamicLibFileName);
        }
        
        if (!appkey) {
            NSLog(@"no encryption APPKEY specified");
            usage();
        }
        else {
            NSLog(@"app key is: %@\n", appkey);
        }
        

        //** read HOST APP file
        NSFileHandle        *inFile;
        
        //** open and read file into a data block
        NSFileManager *fileMgr;
        fileMgr = [NSFileManager defaultManager];
        
        NSString *filePath = [NSString stringWithFormat:@"%@", hostAppFileName];
        NSLog(@" filePath: %@", filePath);
        
        if ( [fileMgr fileExistsAtPath:filePath] == NO ) {
            NSLog(@"File does not exist!");
            exit(1);
        }
        
        inFile = [NSFileHandle fileHandleForReadingAtPath: filePath];
        NSData *plain_txt = [inFile readDataToEndOfFile];
        [inFile closeFile];
        
        
        //** FILE SIZE
        unsigned int app_file_size = (int)[plain_txt length];
        NSLog(@"APP file size: %d", app_file_size);

        //** FILE HASH SIG
        unsigned char hash[CC_SHA256_DIGEST_LENGTH];
        CC_SHA256([plain_txt bytes], (unsigned int)[plain_txt length], hash);
        NSData *app_sig = [NSData dataWithBytes:hash length:CC_SHA1_DIGEST_LENGTH];
        NSLog(@"sha_hash_val 20 bytes: %@", app_sig);
        

        //ADD values to .dylib file and output to .dylib.out file
        NSString *dynFilePath = [NSString stringWithFormat:@"%@", dynamicLibFileName];
        char dynFilePath_in_str[512];
        char dynFilePath_out_str[512];
        char dynFilePath_tempStr[512];
        strcpy(dynFilePath_in_str,  [dynFilePath UTF8String]);
        strcpy(dynFilePath_out_str, [dynFilePath UTF8String]);
        strcat(dynFilePath_out_str, ".out");
        strcpy(dynFilePath_tempStr, [dynFilePath UTF8String]);
        strcat(dynFilePath_tempStr, ".tmp");
        
        
        //********************
        //** add FILE SIZE
        //** unsigned int is what we want 32bit - EF BE AD DE
        //** long 64bit - 00 00 00 00 EF BE AD DE
        // 00 00 00 00 EF BE AD DE
        char swap_cmd[1024];
        NSLog(@"%08x", app_file_size);
        NSLog(@"%02x %02x %02x %02x  %s  %s",
              (uint8_t)((app_file_size >> 0) & 0xff),
              (uint8_t)((app_file_size >> 8) & 0xff),
              (uint8_t)((app_file_size >> 16) & 0xff),
              (uint8_t)((app_file_size >> 24) & 0xff), dynFilePath_in_str, dynFilePath_tempStr);

        sprintf(swap_cmd, "perl -pne \'s/\\xDE\\xAD\\xBE\\xEF/\\x%x\\x%x\\x%x\\x%x/g\' < %s > %s",
              (uint8_t)((app_file_size >> 0) & 0xff),
              (uint8_t)((app_file_size >> 8) & 0xff),
              (uint8_t)((app_file_size >> 16) & 0xff),
              (uint8_t)((app_file_size >> 24) & 0xff), dynFilePath_in_str, dynFilePath_tempStr);

        char tmp[1024];
        sprintf(tmp, "; mv %s %s", dynFilePath_tempStr, dynFilePath_out_str);
        strcat(swap_cmd, tmp);
        NSLog(@"swap_cmd: ...%s...", swap_cmd);
        system(swap_cmd);
        

        //***************
        //** add FILE HASH SIG
        strcpy(swap_cmd, "perl -pne \'s/\\xAA\\xBB\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xAA\\xBB\\xAA/");
        
        //** loop through each NSData byte and add to swap_cmd
        const char *bytes = [app_sig bytes];
        char foo[8];
        int cnt = 32; //** number of bytes in struct
        for (int i = 0; i < [app_sig length]; i++)
        {
            //[result appendFormat:@"%02hhx", (unsigned char)bytes[i]];
            sprintf(foo, "\\x%x", (unsigned char)bytes[i]);
            strcat(swap_cmd, foo);
            cnt--;
        }

        for (int i = 0; i < cnt; i++)
        {
            sprintf(foo, "\\x%x", 0);
            strcat(swap_cmd, foo);
        }
        sprintf(tmp, "/g\' < %s > %s", dynFilePath_out_str, dynFilePath_tempStr);
        strcat(swap_cmd, tmp);

        sprintf(tmp, "; mv %s %s", dynFilePath_tempStr, dynFilePath_out_str);
        strcat(swap_cmd, tmp);
        NSLog(@"swap_cmd3: ...%s...", swap_cmd);
        system(swap_cmd);
        

        
#if 0
        //** create a cipherKey
        NSString* key = @"Mitre567";
        NSData* key_data = [key dataUsingEncoding:NSUTF8StringEncoding];
        
        NSData *salt = IMSCryptoUtilsPseudoRandomData(8);
        NSData *key_stretched = IMSCryptoUtilsDeriveKey(key_data, kCCKeySizeAES256, salt);
        
        //** convert buf string to data
        //NSData *plain_txt = [sbuf dataUsingEncoding:NSUTF8StringEncoding];
        
        //** encrypt the data
        NSData *cipher_txt = IMSCryptoUtilsEncryptData(plain_txt, key_stretched);
        
        
        NSString *encodedString = IMSEncodeBase64(cipher_txt);
        NSData *ct2 = IMSDeodeBase64(encodedString);
#endif
        
        //** encrypt dynamic lib file, read .dylib.out in
        
        //** find and read the file in
        NSString *dynFilePath_out = [[NSString alloc] initWithUTF8String:dynFilePath_out_str];
        inFile = [NSFileHandle fileHandleForReadingAtPath: dynFilePath_out];
        NSData *dyn_lib_plain_txt = [inFile readDataToEndOfFile];
        [inFile closeFile];
        
        //** encrypt the file
        NSError *error;
        NSData *cipher_txt = [SecureData encryptedData:dyn_lib_plain_txt password:appkey error:&error];
        if (error) NSLog(@"encrypt error: %@", error);
        
        //NSLog(@" ct: %@", cipher_txt);
        //NSLog(@" ct2: %@", ct2);
        
        //** write out encrypted contents to FELF file
        NSString *currentpath = [dynFilePath stringByDeletingLastPathComponent];
        NSLog(@"cp: %@", currentpath);
        NSString *encrypted_dyn_lib_name = [NSString stringWithFormat:@"%@/%@", currentpath, @"felf.sld"];
        NSLog(@"result file loc: %@", encrypted_dyn_lib_name);
        [FileOps writeDataToFile:encrypted_dyn_lib_name dbuff:cipher_txt];
        
        //** TEST decrypt. open, decrypt, write back to file
        NSData *decrypted_plain_text = [SecureData decryptData:cipher_txt password:appkey error:&error];
        if (error) NSLog(@"decrypt error: %@", error);

        NSString *decrypted_dyn_plaint_txt_name = [NSString stringWithFormat:@"%@/%@", currentpath, @"decrypt.dylib"];
        NSLog(@"RR %@", decrypted_dyn_plaint_txt_name);
        [FileOps writeDataToFile:decrypted_dyn_plaint_txt_name  dbuff:decrypted_plain_text];
        
       // NSData *encoded_dbuf = [encodedString dataUsingEncoding:NSUTF8StringEncoding];
       //[FileOps writeDataToFile:@"base64_encoded.txt":encoded_dbuf];
        
       //NSLog(@"%@", [@"/tmp/afolder/ff.txt" stringByDeletingLastPathComponent]);
        
    }
    
    return 0;
}


