#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#include "TensorflowManager.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  
  FlutterViewController* controller = (FlutterViewController*)self.window.rootViewController;
  
  FlutterMethodChannel* tensorflowChannel = [FlutterMethodChannel
                                          methodChannelWithName:@"nothotdog.com/tensorflow"
                                          binaryMessenger:controller];
  
  [tensorflowChannel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
    if ([@"loadModel" isEqualToString:call.method]) {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString* res = [TensorflowManager loadModel];
        result(res);
      });
    } else if ([@"recognizeImage" isEqualToString:call.method]) {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray* predictions = [TensorflowManager recognizeImage:call.arguments[@"path"]];
        result(predictions);
      });
    } else {
      result(FlutterMethodNotImplemented);
    }
  }];
  
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}


@end
