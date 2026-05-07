#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PrivateCornerRadiusReader : NSObject
+ (nullable NSNumber *)displayCornerRadiusForScreen:(UIScreen *)screen;
@end

NS_ASSUME_NONNULL_END
