//
//  Copyright (C) 2016  Kapeli
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "DHDocset.h"
#import "NSString+DHUtils.h"

#import "DHDocsetManager.h"

NSString * const DHDocsetsChangedNotification = @"DHDocsetsChangedNotification";

NSString * const DHDocsetsUserDefaultsKey = @"docsets";


@interface DHDocsetManager ()
/// Controller for accessing files on disk
@property (strong, nonatomic, nonnull) NSFileManager *fileManager;

/// Controller for posting notifications
@property (strong, nonatomic, nonnull) NSNotificationCenter *notificationCenter;

/// Controller for accessing user defaults
@property (strong, nonatomic, nonnull) NSUserDefaults *userDefaults;

/// Cached downloads URL
@property (copy, nonatomic, nonnull) NSURL *cachedDownloadsURL;

/// Predicate for listing enabled docsets
@property (strong, nonatomic, nonnull) NSPredicate *predicateMatchingAppleAPIReferenceDocsets;

/// Predicate for matching docsets at a relative path
@property (strong, nonatomic, nonnull) NSPredicate *predicateMatchingDocsetsAtRelativePath;

/// Predicate for listing enabled docsets
@property (strong, nonatomic, nonnull) NSPredicate *predicateMatchingEnabledDocsets;

// redeclare internal-readwrite properties
@property (strong, nonatomic, nonnull, readwrite) NSURL *docsetDownloadsURL;
@property (strong, nonatomic, nonnull, readwrite) NSURL *docsetLibraryURL;
@property (copy, nonatomic, nonnull, readwrite) NSArray<DHDocset *> *docsets;
@end

@implementation DHDocsetManager

#pragma mark - Singleton

+ (nonnull instancetype)sharedManager;
{
    static dispatch_once_t pred;
    static DHDocsetManager *_docsetManager = nil;
    dispatch_once(&pred, ^{
        NSString *docsetLibraryPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Docsets"];
        NSURL *docsetLibraryURL = [NSURL fileURLWithPath:docsetLibraryPath isDirectory:YES];
        _docsetManager = [[DHDocsetManager alloc] initWithDocsetLibraryURL:docsetLibraryURL];
    });
    return _docsetManager;
}

#pragma mark - Initialization

- (instancetype)initWithDocsetLibraryURL:(NSURL *)docsetLibraryURL;
{
    self = [super init];
    if (self) {
        self.fileManager = [NSFileManager defaultManager];
        self.notificationCenter = [NSNotificationCenter defaultCenter];
        self.userDefaults = [NSUserDefaults standardUserDefaults];

        self.predicateMatchingAppleAPIReferenceDocsets = [NSPredicate predicateWithBlock:^BOOL(DHDocset * _Nullable docset, NSDictionary<NSString *,id> * _Nullable bindings) {
            if (![[docset.relativePath lastPathComponent] isEqualToString:@"Apple_API_Reference.docset"]) {
                return NO;
            }

            NSString *helperDirectoryPath = [docset.documentsPath stringByAppendingPathComponent:@"Apple Docs Helper"];
            if (![self.fileManager fileExistsAtPath:helperDirectoryPath]) {
                return NO;
            }

            if (![docset.plist[@"DashDocSetIsGeneratedForiOSCompatibility"] boolValue]) {
                return NO;
            }

            return YES;
        }];
        self.predicateMatchingDocsetsAtRelativePath = [NSPredicate predicateWithFormat:@"relativePath = '%@'"];
        self.predicateMatchingEnabledDocsets = [NSPredicate predicateWithFormat:@"isEnabled = YES"];

        NSString *docsetDownloadsPath = [NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) lastObject];
        self.docsetDownloadsURL = [NSURL fileURLWithPath:docsetDownloadsPath isDirectory:YES];

        NSString *cachedDownloadsPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"com.apple.nsurlsessiond/Downloads"];
        self.cachedDownloadsURL = [NSURL fileURLWithPath:cachedDownloadsPath isDirectory:YES];

        self.docsetLibraryURL = docsetLibraryURL;
        [self createDocsetLibraryIfNeeded];
        [self loadDocsetList];
    }
    return self;
}

#pragma mark - Internal state

/// Saves the changed docset list and posts a notification.
- (void)handleDocsetListChanged;
{
    [self saveDocsetList];
    [self postDocsetsChangedNotification];
}

/// Post a notification that the docset list has changed.
- (void)postDocsetsChangedNotification;
{
    [self.notificationCenter postNotificationName:DHDocsetsChangedNotification object:self];
}

#pragma mark - Predicates

- (NSPredicate *)predicateMatchingDocsetsAtPath:(NSString *)path;
{
    return [NSPredicate predicateWithBlock:^BOOL(DHDocset * _Nullable docset, NSDictionary<NSString *,id> * _Nullable bindings) {
        if ([docset.path isCaseInsensitiveEqual:path]) {
            return YES;
        }

        if ([[docset.path stringByDeletingLastPathComponent] isCaseInsensitiveEqual:path]) {
            return YES;
        }

        return NO;
    }];
}

- (NSPredicate *)predicateExcludingDocsetsAtPath:(NSString *)path;
{
    return [NSCompoundPredicate notPredicateWithSubpredicate:[self predicateMatchingDocsetsAtPath:path]];
}

#pragma mark - User defaults

- (void)createDocsetLibraryIfNeeded;
{
    BOOL isDirectory;
    BOOL exists = [self.fileManager fileExistsAtPath:self.docsetLibraryURL.path isDirectory:&isDirectory];
    if (exists && isDirectory) {
        NSLog(@"%s - Using storage directory at %@'", __PRETTY_FUNCTION__, self.docsetLibraryURL);
    } else {
        NSLog(@"%s - Creating storage directory at %@'", __PRETTY_FUNCTION__, self.docsetLibraryURL);
        [self.fileManager createDirectoryAtPath:self.self.docsetLibraryURL.path withIntermediateDirectories:YES attributes:nil error:nil];

        NSArray<NSString *> *defaultsKeys = @[
            @"DHDocsetDownloaderScheduledUpdate",
            @"DHDocsetDownloader",
            @"DHDocsetTransferrer",
            @"docsets"
        ];

        for (NSString *key in defaultsKeys) {
            [self.userDefaults removeObjectForKey:key];
        }
    }

    [self.docsetLibraryURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
}

/// Loads the docset list from the user defaults
- (void)loadDocsetList;
{
    NSMutableArray *loadedDocsets = [[NSMutableArray alloc] init];
    NSArray *docsetList = [self.userDefaults arrayForKey:DHDocsetsUserDefaultsKey];
    for (NSDictionary *dictionary in docsetList) {
        DHDocset *docset = [DHDocset docsetWithDictionaryRepresentation:dictionary];
        NSURL *docsetURL = [self.docsetLibraryURL URLByAppendingPathComponent:docset.name];
        if ([self.fileManager fileExistsAtPath:docsetURL.path]) {
            [loadedDocsets addObject:docset];
        } else {
            NSLog(@"%s - Docset not found at '%@'", __PRETTY_FUNCTION__, docsetURL);
        }
    }

    self.docsets = [loadedDocsets mutableCopy];
    NSLog(@"%s - Loaded %lu docset(s).", __PRETTY_FUNCTION__, self.docsets.count);
}

/// Saves the docset list to the user defaults.
- (void)saveDocsetList;
{
    NSMutableArray<NSDictionary *> *dictionaries = [NSMutableArray array];
    for (DHDocset *docset in self.docsets) {
        [dictionaries addObject:[docset dictionaryRepresentation]];
    }

    [self.userDefaults setObject:dictionaries forKey:DHDocsetsUserDefaultsKey];
    NSLog(@"%s - Saved %lu docset(s).", __PRETTY_FUNCTION__, dictionaries.count);
}

#pragma mark - Reading the list of docsets

- (nonnull NSArray<DHDocset *> *)enabledDocsets;
{
    return [self.docsets filteredArrayUsingPredicate:self.predicateMatchingEnabledDocsets];
}

#pragma mark - Finding docsets in the list

- (nullable DHDocset *)appleAPIReferenceDocset;
{
    NSMutableOrderedSet *orderedDocsets = [NSMutableOrderedSet orderedSet];
    [orderedDocsets addObjectsFromArray:self.enabledDocsets];
    [orderedDocsets addObjectsFromArray:self.docsets];
    [orderedDocsets filterUsingPredicate:self.predicateMatchingAppleAPIReferenceDocsets];
    return [orderedDocsets firstObject];
}

- (nullable DHDocset *)docsetForDocumentationPage:(nonnull NSString *)url;
{
    if ([url hasPrefix:@"dash-apple-api://"]) {
        return [self appleAPIReferenceDocset];
    }

    url = [[url stringByDeletingPathFragment] stringByReplacingPercentEscapes];
    for (DHDocset *docset in self.docsets) {
        NSString *path = docset.path;
        if (path && [url rangeOfString:path].location != NSNotFound) {
            return docset;
        }
    }

    return nil;
}

- (nullable DHDocset *)docsetWithRelativePath:(nonnull NSString *)relativePath
{
    NSPredicate *predicate = [self.predicateMatchingDocsetsAtRelativePath predicateWithSubstitutionVariables:@{
        @"relativePath": @"relativePath"
    }];
    return [[self.docsets filteredArrayUsingPredicate:predicate] firstObject];
}

#pragma mark - Modifying the list of docsets

- (void)addDocset:(nonnull DHDocset *)newDocset replaceExisting:(BOOL)replaceExisting;
{
    NSParameterAssert(newDocset);

    DHDocset *existingDocset = [self docsetWithRelativePath:newDocset.path];
    NSMutableArray *mutableDocsets = [self.docsets mutableCopy];

    if (replaceExisting && existingDocset) {
        [newDocset grabUserDataFromDocset:existingDocset];

        NSUInteger existingDocsetCount = mutableDocsets.count;
        NSUInteger existingDocsetIndex = [mutableDocsets indexOfObject:existingDocset];
        [mutableDocsets filterUsingPredicate:[self predicateExcludingDocsetsAtPath:newDocset.path]];
        NSUInteger removedDocsetCount = existingDocsetCount - mutableDocsets.count;
        existingDocsetIndex -= removedDocsetCount;

        NSUInteger newDocsetIndex = MIN(existingDocsetIndex, mutableDocsets.count);
        [mutableDocsets insertObject:newDocset atIndex:newDocsetIndex];
    } else {
        [mutableDocsets addObject:newDocset];
    }

    self.docsets = [mutableDocsets copy];
    [self handleDocsetListChanged];
}

- (BOOL)importDocsetFromURL:(NSURL *)sourceURL error:(NSError **)error;
{
    NSString *fileName = [sourceURL lastPathComponent];
    NSURL *destinationURL = [self.docsetLibraryURL URLByAppendingPathComponent:fileName isDirectory:NO];

    [self.fileManager removeItemAtURL:destinationURL error:nil];
    return [self.fileManager moveItemAtURL:sourceURL toURL:destinationURL error:error];
}

- (void)moveDocsetAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
    NSParameterAssert(fromIndex >= 0);
    NSParameterAssert(fromIndex < self.docsets.count);
    NSParameterAssert(toIndex >= 0);
    NSParameterAssert(toIndex < self.docsets.count);

    if (fromIndex == toIndex) {
        return;
    }

    NSMutableArray *mutableDocsets = [self.docsets mutableCopy];
    DHDocset *movedDocset = mutableDocsets[fromIndex];
    [mutableDocsets removeObjectAtIndex:fromIndex];
    [mutableDocsets insertObject:movedDocset atIndex:toIndex];
    self.docsets = [mutableDocsets copy];

    [self saveDocsetList];
}

- (void)removeDocsetsInFolder:(nonnull NSString *)path
{
    self.docsets = [self.docsets filteredArrayUsingPredicate:[self predicateExcludingDocsetsAtPath:path]];
    [self handleDocsetListChanged];
}

- (void)updateDocset:(DHDocset *)docset setEnabled:(BOOL)enabled;
{
    docset.isEnabled = YES;
    [self saveDocsetList];
}

#pragma mark - Cache

- (void)removeCachedDownloads;
{
    [self.fileManager removeItemAtPath:self.cachedDownloadsURL.path error:nil];
}

@end
