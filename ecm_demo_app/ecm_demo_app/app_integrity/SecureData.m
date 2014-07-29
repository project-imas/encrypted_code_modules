//
//  SecureData.m
//  iMAS_file_cipher
//
//  Created by Gregg Ganley on 3/17/14.
//  Copyright (c) 2014 Gregg Ganley. All rights reserved.
//

#import "SecureData.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>

@implementation SecureData


NSString * const
kRNCryptManagerErrorDomain = @"org.mitre.app_integrity";

const CCAlgorithm kAlgorithm = kCCAlgorithmAES128;
const NSUInteger kAlgorithmKeySize = kCCKeySizeAES128;
const NSUInteger kAlgorithmBlockSize = kCCBlockSizeAES128;
const NSUInteger kAlgorithmIVSize = kCCBlockSizeAES128;
const NSUInteger kPBKDFSaltSize = 8;
const NSUInteger kPBKDFRounds = 10000;  // ~80ms on an iPhone 4

// ===================

+ (NSData *)decryptData:(NSData *)cipherData
               password:(NSString *)password
                  error:(NSError **)error {
    //NSAssert(iv, @"IV must not be NULL");
    //NSAssert(salt, @"salt must not be NULL");
    
    //NSData *iv = [self randomDataOfLength:kAlgorithmIVSize];
    NSData *salt = [password dataUsingEncoding:NSUTF8StringEncoding];
    NSData *key = [self AESKeyForPassword:password salt:salt];
    
    size_t outLength;
    NSMutableData *
    plainText = [NSMutableData dataWithLength:cipherData.length + kAlgorithmBlockSize];
    
    CCCryptorStatus result = CCCrypt(kCCDecrypt, // operation
                                     kAlgorithm, // Algorithm
                                     kCCOptionPKCS7Padding, // options
                                     key.bytes, // key
                                     key.length, // keylength
                                     NULL, //iv.bytes,// iv
                                     cipherData.bytes, // dataIn
                                     cipherData.length, // dataInLength,
                                     plainText.mutableBytes, // dataOut
                                     plainText.length, // dataOutAvailable
                                     &outLength); // dataOutMoved
    NSLog(@"data out: %zu", outLength);
    
    if (result == kCCSuccess) {
        plainText.length = outLength;
    }
    else {
        if (error) {
            NSLog(@"ERROR !!");
            *error = [NSError errorWithDomain:kRNCryptManagerErrorDomain
                                         code:result
                                     userInfo:nil];
        }
        return nil;
    }
    
    return plainText;
}



// ===================

+ (NSData *)randomDataOfLength:(size_t)length {
    NSMutableData *data = [NSMutableData dataWithLength:length];
    
    int result = SecRandomCopyBytes(kSecRandomDefault,
                                    length,
                                    data.mutableBytes);
    NSAssert(result == 0, @"Unable to generate random bytes: %d",
             errno);
    
    return data;
}

// ===================

// Replace this with a 10,000 hash calls if you don't have CCKeyDerivationPBKDF
+ (NSData *)AESKeyForPassword:(NSString *)password
                         salt:(NSData *)salt {
    
    NSMutableData *
    derivedKey = [NSMutableData dataWithLength:kAlgorithmKeySize];
    
    int
    result = CCKeyDerivationPBKDF(kCCPBKDF2,            // algorithm
                                  password.UTF8String,  // password
                                  [password lengthOfBytesUsingEncoding:NSUTF8StringEncoding],  // passwordLength
                                  salt.bytes,           // salt
                                  salt.length,          // saltLen
                                  kCCPRFHmacAlgSHA1,    // PRF
                                  kPBKDFRounds,         // rounds
                                  derivedKey.mutableBytes, // derivedKey
                                  derivedKey.length); // derivedKeyLen
    
    // Do not log password here
    NSAssert(result == kCCSuccess,
             @"Unable to create AES key for password: %d", result);
    
    return derivedKey;
}


@end
