//
//  darkdock.m
//  darkdock
//
//  Created by Adam Bell on 2014-07-05.
//  Copyright (c) 2014 Adam Bell. All rights reserved.
//

#import "darkdock.h"

#import <dlfcn.h>
#import <fishhook/fishhook.h>

@implementation darkdock

static id (*orig_CFPreferencesCopyAppValue)(CFStringRef key, CFStringRef applicationID);

// Always return @"Dark" whenever @"AppleInterfaceTheme" is requested. @"AppleInterfaceTheme"'s value is stored in /Library/Preferences/.GlobalPreferences.
id hax_CFPreferencesCopyAppValue(CFStringRef key, CFStringRef applicationID)
{
    if ([(__bridge NSString *)key isEqualToString:@"AppleInterfaceTheme"] || [(__bridge NSString *)key isEqualToString:@"AppleInterfaceStyle"]) {
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *docDir = [paths objectAtIndex:0];
        NSString *docFile = [NSString stringWithFormat:@"%@/Application Support/SIMBL/plugins/DarkDock.bundle/Contents/Resources/mode.txt", docDir];
        NSString *contents = [NSString stringWithContentsOfFile:docFile encoding:NSUTF8StringEncoding error:NULL];
        NSArray *lines = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        NSString *res = @"Light";
        
        
        if ([lines count] > 0)
        {
            NSInteger val = [lines[0] integerValue];
            if (val)
                res = @"Dark";
        }
        
        return res;
    } else {
        return orig_CFPreferencesCopyAppValue(key, applicationID);
    }
}

__attribute__((constructor))
static void goGoGadgetDarkMode() {
    // Use fishhook to do CoreFoundation hooks.
    orig_CFPreferencesCopyAppValue = dlsym(RTLD_DEFAULT, "CFPreferencesCopyAppValue");
    rebind_symbols((struct rebinding[1]){{"CFPreferencesCopyAppValue", hax_CFPreferencesCopyAppValue}}, 1);
    
    // Wait a few seconds for the Dock to warm up before firing a notification to reload the Dock colour.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("AppleInterfaceThemeChangedNotification"), (void *)0x1, NULL, YES);
    });
}

@end
