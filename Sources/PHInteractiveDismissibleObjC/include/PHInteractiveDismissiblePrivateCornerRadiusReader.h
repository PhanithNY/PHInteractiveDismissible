#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Returns nil when the private getter is unavailable, incompatible or invalid.
/// The receiver normally is a UIScreen; capability checks also support test doubles.
@interface PHInteractiveDismissiblePrivateCornerRadiusReader : NSObject
+ (nullable NSNumber *)displayCornerRadiusForObject:(NSObject *)object
    NS_SWIFT_NAME(displayCornerRadius(for:));
@end

NS_ASSUME_NONNULL_END
