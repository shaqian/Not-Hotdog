#import "Foundation/Foundation.h"

@interface TensorflowManager:NSObject
+ (NSString*)loadModel;
+ (NSMutableArray*)recognizeImage:(NSString*)image_path;
@end

