//
//  FMDatabase+DHDBAdditions.h
//  Dash
//
//  Created by Ellen Teapot on 11/20/18.
//  Copyright © 2018 Kapeli. All rights reserved.
//

#import "FMDatabase.h"

NS_ASSUME_NONNULL_BEGIN

/// Signature for SQLite external functions
typedef void DHDBFunction(void *context, int argc, void * _Nonnull * _Nonnull argv);

/// SQLite function for ranking matches
extern DHDBFunction DHDBRankMatch;

/// SQLite function for compressing text
extern DHDBFunction DHDBCompress;

/// SQLite function for decompressing text
extern DHDBFunction DHDBUncompress;


/// Dash: FMDatabase additions
@interface FMDatabase (DHDBAdditions)

/**
 Dash: Register SQLite3 full-text search extensions
 */
- (void)registerFTSExtensions;

@end

NS_ASSUME_NONNULL_END
