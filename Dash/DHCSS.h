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


extern NSString * const DHActiveAppleLanguageKey;

typedef NS_ENUM(NSInteger, DHActiveAppleLanguage) {
    DHActiveAppleLanguageBoth = 0,
    DHActiveAppleLanguageSwift = 1,
    DHActiveAppleLanguageObjC = 2
};


@interface DHCSS : NSObject

@property (strong) NSString *bothCSS;
@property (strong) NSString *swiftCSS;
@property (strong) NSString *objcCSS;

+ (DHCSS *)sharedCSS;
+ (NSString *)currentCSSString;
+ (NSString *)currentCSSStringWithTextModifier;
+ (DHActiveAppleLanguage)activeAppleLanguage;
- (void)refreshActiveCSS;
- (void)modifyTextSize:(BOOL)increase;
- (BOOL)shouldModifyTextSize;
- (NSString *)textSizeAdjust;

@end
