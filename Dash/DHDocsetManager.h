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

@import Foundation;

@class DHDocset;


NS_ASSUME_NONNULL_BEGIN

/// Notification posted when the available docsets change.
extern NSString * const DHDocsetsChangedNotification;

@interface DHDocsetManager : NSObject

/// @section Singleton

/// @return The shared docset manager.
+ (instancetype)sharedManager;

- (instancetype)init NS_UNAVAILABLE;

/// @section Storing the list of docsets in the user defaults

/// Save the list of docsets to the user defaults
- (void)saveDocsetList;

/// @section Reading the list of docsets

/// Docset download path
@property (strong, nonatomic, readonly) NSURL *docsetDownloadsURL;

/// Docset library path
@property (strong, nonatomic, readonly) NSURL *docsetLibraryURL;

/// The list of all docsets.
@property (copy, nonatomic, readonly) NSArray<DHDocset *> *docsets;

/// The list of enabled docsets.
@property (copy, nonatomic, readonly) NSArray<DHDocset *> *enabledDocsets;

//// @section Finding docsets in the list

/// @return The Apple API reference docset, if available.
- (nullable DHDocset *)appleAPIReferenceDocset;

/**
 Returns the docset containing the provided URL.
 @param url The Dash URL to find the docset for.
 @return The docset for the provided URL, or nil if the provided URL was not a Dash URL, or if no matching docset was found.
 */
- (nullable DHDocset *)docsetForDocumentationPage:(NSString *)url;

/**
 Returns the docset matching the provided relative path.
 @param relativePath The relative path of the docset to find.
 @return The docset matching the provided relative path, or nil if no matching docset was found.
 */
- (nullable DHDocset *)docsetWithRelativePath:(NSString *)relativePath;

//// @section Modifying the list of docsets

/**
 Adds the provided docset to the list.
 @param docset The docset to add.
 @param replaceExisting Replace existing docsets with the same name
 */
- (void)addDocset:(DHDocset *)docset replaceExisting:(BOOL)replaceExisting;

- (BOOL)importDocsetFromURL:(NSURL *)sourceURL error:(NSError **)error;

/**
 Enables or disables the provided docset.
 @param docset The docset to enable or disable
 @param enabled YES to enable the docset, NO to disable
 */
- (void)updateDocset:(DHDocset *)docset setEnabled:(BOOL)enabled;

/**
 Removes docsets in the provided directory.
 @param path The path of the directory containing docsets to remove.
 */
- (void)removeDocsetsInFolder:(NSString *)path;

/**
 Reorders a docset within the list.
 @param fromIndex The index of the docset to move.
 @param toIndex The index that the docset should be moved to.
 */
- (void)moveDocsetAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;

/// @section Cache

- (void)removeCachedDownloads;

@end

NS_ASSUME_NONNULL_END
