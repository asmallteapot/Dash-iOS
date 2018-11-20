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

@interface DHTypes : NSObject {
    NSMutableArray *orderedTypeObjects;
    NSMutableArray *orderedTypes;
    NSMutableDictionary *encodedToSingular;
    NSMutableDictionary *encodedToPlural;
    NSMutableArray *orderedHeaders;
}

@property (retain) NSMutableArray *orderedTypeObjects;
@property (retain) NSMutableArray *orderedTypes;
@property (retain) NSMutableDictionary *encodedToSingular;
@property (retain) NSMutableDictionary *encodedToPlural;
@property (retain) NSMutableArray *orderedHeaders;

+ (DHTypes *)sharedTypes;
+ (NSString *)singularFromEncoded:(NSString *)encodedType notFoundReturn:(NSString *)notFound;
+ (NSString *)pluralFromEncoded:(NSString *)encodedType;
- (NSString *)typeFromScalaType:(NSString*)scalaType;
- (NSString *)unifiedSQLiteOrder:(BOOL)isDashDocset platform:(NSString *)platform;

@end
