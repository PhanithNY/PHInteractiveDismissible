#import "PHInteractiveDismissiblePrivateCornerRadiusReader.h"

#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>
#include <math.h>
#include <string.h>

@implementation PHInteractiveDismissiblePrivateCornerRadiusReader

+ (NSNumber *)displayCornerRadiusForObject:(NSObject *)object {
  @try {
    NSString *selectorName = [@[@"_display", @"Corner", @"Radius"] componentsJoinedByString:@""];
    SEL selector = NSSelectorFromString(selectorName);
    if (![object respondsToSelector:selector]) {
      return nil;
    }

    // Use the receiver's actual class so overrides and their signatures are respected.
    Method method = class_getInstanceMethod(object_getClass(object), selector);
    if (method == NULL || method_getNumberOfArguments(method) != 2) {
      return nil;
    }

    char returnType[32] = {0};
    method_getReturnType(method, returnType, sizeof(returnType));
    if (strcmp(returnType, @encode(CGFloat)) != 0) {
      return nil;
    }

    IMP implementation = method_getImplementation(method);
    if (implementation == NULL) {
      return nil;
    }

    CGFloat (*function)(id, SEL) = (CGFloat (*)(id, SEL))implementation;
    CGFloat radius = function(object, selector);
    if (!isfinite(radius) || radius < 0) {
      return nil;
    }
    return @(radius);
  } @catch (__unused NSException *exception) {
    return nil;
  }
}

@end
