//
//  SecureData.h
//  iMAS_file_cipher
//
//  Created by Gregg Ganley on 3/17/14.
//  Copyright (c) 2014 Gregg Ganley. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SecureData : NSObject

+ (NSData *)encryptedData:(NSData *)data
                 password:(NSString *)password
                    error:(NSError **)error;

+ (NSData *)decryptData:(NSData *)cipherData
                 password:(NSString *)password
                  error:(NSError **)error;
@end
