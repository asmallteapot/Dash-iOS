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

/// Predicate for listing enabled docsets
@property (strong, nonatomic, nonnull) NSPredicate *predicateMatchingAppleAPIReferenceDocsets;

/// Predicate for matching docsets at a relative path
@property (strong, nonatomic, nonnull) NSPredicate *predicateMatchingDocsetsAtRelativePath;

/// Predicate for listing enabled docsets
@property (strong, nonatomic, nonnull) NSPredicate *predicateMatchingEnabledDocsets;

// redeclare internal-readwrite properties
@property (copy, nonatomic, readwrite) NSArray<DHDocset *> *docsets;
@end

@implementation DHDocsetManager

#pragma mark - File paths

+ (nullable NSString *)cachePath;
{
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
}

+ (nullable NSString *)documentsPath;
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+ (nullable NSString *)libraryPath;
{
    return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
}

#pragma mark - Singleton

+ (nonnull instancetype)sharedManager;
{
    static dispatch_once_t pred;
    static DHDocsetManager *_docsetManager = nil;
    dispatch_once(&pred, ^{
        _docsetManager = [[DHDocsetManager alloc] init];
    });
    return _docsetManager;
}

#pragma mark - Initialization

- (instancetype)init;
{
    self = [super init];
    if (self) {
        self.docsets = @[];
        self.fileManager = [NSFileManager defaultManager];
        self.notificationCenter = [NSNotificationCenter defaultCenter];
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
        self.userDefaults = [NSUserDefaults standardUserDefaults];

        [self loadDefaults];
    }
    return self;
}

#pragma mark - Internal state

/// Saves the changed docset list and posts a notification.
- (void)handleDocsetListChanged;
{
    [self saveDefaults];
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

/// Loads the docset list from the user defaults
- (void)loadDefaults;
{
    NSMutableArray *loadedDocsets = [[NSMutableArray alloc] init];
    NSArray *docsetList = [self.userDefaults arrayForKey:DHDocsetsUserDefaultsKey];
    for (NSDictionary *dictionary in docsetList) {
        DHDocset *docset = [DHDocset docsetWithDictionaryRepresentation:dictionary];
        if ([self.fileManager fileExistsAtPath:docset.path]) {
            [loadedDocsets addObject:docset];
        } else {
            NSLog(@"%s - Docset not found at '%@'", __PRETTY_FUNCTION__, docset.path);
        }
    }

    self.docsets = [loadedDocsets mutableCopy];
    NSLog(@"%s - Loaded %lu docset(s).", __PRETTY_FUNCTION__, self.docsets.count);
}

/// Saves the docset list to the user defaults.
- (void)saveDefaults;
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

    [self saveDefaults];
}

- (void)removeDocsetsInFolder:(nonnull NSString *)path
{
    self.docsets = [self.docsets filteredArrayUsingPredicate:[self predicateExcludingDocsetsAtPath:path]];
    [self handleDocsetListChanged];
}

- (void)updateDocset:(DHDocset *)docset setEnabled:(BOOL)enabled;
{
    docset.isEnabled = YES;
    [self saveDefaults];
}

@end
