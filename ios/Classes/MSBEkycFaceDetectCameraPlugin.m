#import "MSBEkycFaceDetectCameraPlugin.h"
#if __has_include(<msb_ekyc_face_detect_camera/msb_ekyc_face_detect_camera-Swift.h>)
#import <msb_ekyc_face_detect_camera/msb_ekyc_face_detect_camera-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "msb_ekyc_face_detect_camera-Swift.h"
#endif

@implementation MSBEkycFaceDetectCameraPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMSBEkycFaceDetectCameraPlugin registerWithRegistrar:registrar];
}
@end
