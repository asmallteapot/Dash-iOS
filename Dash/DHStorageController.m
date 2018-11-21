//
//  DHStorageController.m
//  Dash iOS
//
//  Created by Ellen Teapot on 12/11/18.
//  Copyright © 2018 Kapeli. All rights reserved.
//

#import "DHStorageController.h"


@interface DHStorageController ()
@property (copy, nonatomic, readwrite) NSString *cachePath;
@property (copy, nonatomic, readwrite) NSString *documentsPath;
@property (copy, nonatomic, readwrite) NSString *libraryPath;
@end


@implementation DHStorageController

+ (instancetype)sharedController {
    static DHStorageController *storageController;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        storageController = [[DHStorageController alloc] init];
    });
    return storageController;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        self.documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        self.libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    }
    return self;
}

@end
