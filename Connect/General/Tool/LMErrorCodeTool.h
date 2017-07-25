//
//  LMErrorCodeTool.h
//  Connect
//
//  Created by bitmain on 2017/1/6.
//  Copyright © 2017年 Connect. All rights reserved.
//



#import <Foundation/Foundation.h>
@interface LMErrorCodeTool : NSObject

/**

 Returns the error message to be displayed according to the large type and error code
 
*/
+(NSString*)showToastErrorType:(ToastErrorType)toastErrorType withErrorCode:(ErrorCodeType)errorCodeType withUrl:(NSString*)url;


+(NSString*)messageWithErrorCode:(ErrorCodeType)errorCodeType;


@end






