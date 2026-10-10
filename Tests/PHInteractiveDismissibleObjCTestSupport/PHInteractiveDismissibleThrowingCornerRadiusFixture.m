#import "PHInteractiveDismissibleThrowingCornerRadiusFixture.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation PHInteractiveDismissibleThrowingCornerRadiusFixture

- (CGFloat)_displayCornerRadius {
  [NSException raise:NSInternalInconsistencyException format:@"Simulated private getter failure"];
  return 0;
}

@end
