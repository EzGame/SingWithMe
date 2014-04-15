//
//  SingModel.m
//  SingWithMe
//
//  Created by David Zhang on 2014-04-14.
//  Copyright (c) 2014 EzGame. All rights reserved.
//

#import "SingModel.h"

@implementation SingModel
#pragma mark - File utility
- (NSArray*) applicationDocuments
{
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
}

- (NSString*) applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (NSURL*) testFilePathURL
{
    return [NSURL fileURLWithPath:
            [NSString stringWithFormat:@"%@/%@",[self applicationDocumentsDirectory],@"sup.mp3"]];
}
@end
