//
//  StringTool.m
//  Connect
//
//  Created by MoHuilin on 16/5/11.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "StringTool.h"
#import "NSData+Hash.h"
#import "LMIMHelper.h"
#import <objc/message.h>

@implementation StringTool

unsigned char strToChar (char a, char b)
{
    char encoder[3] = {'\0','\0','\0'};
    encoder[0] = a;
    encoder[1] = b;
    return (char) strtol(encoder,NULL,16);
}


//Data is converted to hexadecimal。
+ (NSString *)hexStringFromData:(NSData *)data{
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    
    if (!dataBuffer)
        return [NSString string];
    
    NSUInteger          dataLength  = [data length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    
    return [NSString stringWithString:hexString];
}


+(NSData *) DataXOR1:(NSData *)data1
            DataXOR2:(NSData *)data2{
    const char *data1Bytes = [data1 bytes];
    const char *data2Bytes = [data2 bytes];
    NSMutableData *xorData = [[NSMutableData alloc] init];
    for (int i = 0; i < data1.length; i++){
        const char xorByte = data1Bytes[i] ^ data2Bytes[i];
        [xorData appendBytes:&xorByte length:1];
    }
    return xorData;
}

+ (NSData *)hexStringToData:(NSString *)hex{
    
    const char * bytes = [hex cStringUsingEncoding: NSUTF8StringEncoding];
    NSUInteger length = strlen(bytes);
    unsigned char * r = (unsigned char *) malloc(length / 2 + 1);
    unsigned char * index = r;
    
    while ((*bytes) && (*(bytes +1))) {
        *index = strToChar(*bytes, *(bytes +1));
        index++;
        bytes+=2;
    }
    *index = '\0';
    
    NSData * result = [NSData dataWithBytes: r length: length / 2];
    free(r);
    
    return result;
}


+ (NSString *)pinxCreator:(NSString *)pan withPinv:(NSString *)pinv
{
    if (pan.length != pinv.length)
    {
        return nil;
    }
    NSMutableArray *hexArray1 = [self splitStringIntoChars:pan];
    NSMutableArray *hexArray2 = [self splitStringIntoChars:pinv];
    NSMutableString *str = [NSMutableString new];
    for (int i=0; i<[hexArray1 count]; i++ )
    {
        /*Convert to base 16*/
        int a=(unsigned char)strtol([[hexArray1 objectAtIndex:i] UTF8String], NULL, 16);
        int b=(unsigned char)strtol([[hexArray2 objectAtIndex:i] UTF8String], NULL, 16);
        char encrypted = a ^ b;
        [str appendFormat:@"%x",encrypted];
    }
    return str;
}

+ (NSMutableArray*)splitStringIntoChars:(NSString*)argStr{
    NSMutableArray *characters = [[NSMutableArray alloc]
                                  initWithCapacity:[argStr length]];
    for (int i=0; i < [argStr length]; i++)
    {
        NSString *ichar = [NSString stringWithFormat:@"%c", [argStr characterAtIndex:i ]];
        [characters addObject:ichar];
    }
    return characters;
}
/**
 *  Return to the page to determine the regular expression of the test string
 *
 */
+ (NSString *)regHttp
{
   return @"(?:(?:(?:[a-z]+:)?//))?(?:localhost|(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])(?:\\.(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])){3}|(?:(?:[a-z0-9]-*)*[a-z0-9]+)(?:\\.(?:[a-z0-9]-*)*[a-z0-9]+)*(?:\\.(?:[a-z]{2,}))\\.?)(?::\\d{2,5})?(?:[/?#][^\\s\"]*)?";
}
/**
 * Can only enter numeric decimal points and @ ""
 */
+ (BOOL)checkString:(NSString*)currentString
{
    // Enter the legitimacy check
    NSString* pattern = @"^+[0-9\\.]$";
    NSRegularExpression* reg = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray* resultArray = [reg matchesInString:currentString options:NSMatchingReportCompletion range:NSMakeRange(0, currentString.length)];
    if (resultArray.count <= 0) {
        if ([currentString isEqualToString:@""]) {
            return YES;
        }
        return NO;
    }else
    {
        return YES;
    }
}
/**
 * Guolv string, remove the first space
 */
+ (NSString*)filterStr:(NSString*)str
{
    if (str.length > 0) {
        return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }else
    {
        return str;
    }
}
/**
 *
 *  Move data to str
 */
+(NSString*)stringWithData:(NSData*)data
{
    NSData *hash512Random = data.sha512Data;
    NSString *str = [[NSString alloc] initWithData:hash512Random encoding:NSMacOSRomanStringEncoding];
    return [str hmacSHA512StringWithKey:str];
}
/**
 *  get SystemUrl
 *
 */
+(NSString*)getSystemUrl
{
    NSData *randomData = [LMIMHelper createRandom512bits];
    return [self hexStringFromData:randomData];
}

@end
