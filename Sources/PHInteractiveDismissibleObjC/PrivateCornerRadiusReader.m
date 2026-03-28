#import "PrivateCornerRadiusReader.h"

#import <objc/message.h>

@implementation PrivateCornerRadiusReader

+ (NSNumber *)displayCornerRadiusForScreen:(UIScreen *)screen {
  @try {
    NSString *selectorName = [@[@"_display", @"Corner", @"Radius"] componentsJoinedByString:@""];
    SEL selector = NSSelectorFromString(selectorName);
    if (![screen respondsToSelector:selector]) {
      return nil;
    }

    Method method = class_getInstanceMethod([UIScreen class], selector);
    if (method == NULL) {
      return nil;
    }

    IMP implementation = method_getImplementation(method);
    if (implementation == NULL) {
      return nil;
    }

    CGFloat (*function)(id, SEL) = (CGFloat (*)(id, SEL))implementation;
    return @(function(screen, selector));
  } @catch (__unused NSException *exception) {
    return nil;
  }
}

@end
