//
//  DHStorageController.h
//  Dash iOS
//
//  Created by Ellen Teapot on 12/11/18.
//  Copyright © 2018 Kapeli. All rights reserved.
//

@import Foundation;


NS_ASSUME_NONNULL_BEGIN

@interface DHStorageController : NSObject

/// The path to the user's cache directory.
@property (copy, nonatomic, readonly) NSString *cachePath;

/// The path to the user's documents directory.
@property (copy, nonatomic, readonly) NSString *documentsPath;

/// The path to the user's library directory.
@property (copy, nonatomic, readonly) NSString *libraryPath;

+ (instancetype)sharedController;
@end

NS_ASSUME_NONNULL_END
