#include <napi.h>

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

NSScreen *GetScreenWithID(CGDirectDisplayID id) {
    for (NSScreen *screen in [NSScreen screens]) {
        NSDictionary *screenDictionary = [screen deviceDescription];
        NSNumber *screenID = screenDictionary[@"NSScreenNumber"];
        if (id == [screenID unsignedIntValue]) {
            return screen;
        }
    }
    return nil;
}

NSString *_SetWallpaper(int displayID, NSString *wallpaperPath, NSNumber *scalingKey, NSNumber *allowClipping, NSColor *fillColor) {
    NSScreen *screen = GetScreenWithID((CGDirectDisplayID) displayID);
    if (screen == nil)
        return nil;

    NSDictionary<NSWorkspaceDesktopImageOptionKey, id> *options = @{
        NSWorkspaceDesktopImageScalingKey: scalingKey,
        NSWorkspaceDesktopImageAllowClippingKey: allowClipping,
        NSWorkspaceDesktopImageFillColorKey: fillColor
    };

    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSURL *wallpaperURL = [NSURL fileURLWithPath:wallpaperPath];
    NSError *error;
    [workspace setDesktopImageURL:wallpaperURL forScreen:screen options:options error:&error];
    return error == nil ? nil : error.localizedDescription;
}

Napi::String SetWallpaper(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto displayID{info[0].As<Napi::Number>().Int32Value()};
    auto wallpaperPath{info[1].As<Napi::String>().Utf8Value()};
    auto scaling{info[2].As<Napi::Number>().Int32Value()};
    auto allowClipping{info[3].As<Napi::Number>().Int32Value()};
    auto red{info[4].As<Napi::Number>().DoubleValue()};
    auto green{info[5].As<Napi::Number>().DoubleValue()};
    auto blue{info[6].As<Napi::Number>().DoubleValue()};
    auto alpha{info[7].As<Napi::Number>().DoubleValue()};

    NSColor *rgbaColor = [NSColor colorWithSRGBRed:red green:green blue:blue alpha:alpha];

    NSString *error = _SetWallpaper(displayID, @(wallpaperPath.c_str()), @(scaling), @(allowClipping), rgbaColor);
    
    Napi::String res;
    if (error == nil)
        res = Napi::String::New(env, "");
    else
        res = Napi::String::New(env, std::string([error UTF8String]));
    return res;
}

NSString *_GetWallpaperPathForScreen(int displayID) {
    NSScreen *screen = GetScreenWithID((CGDirectDisplayID) displayID);
    if (screen == nil)
        return nil;
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSURL *imageURL = [workspace desktopImageURLForScreen:screen];
    return [imageURL path];
}

Napi::String GetWallpaperPathForScreen(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto displayID{info[0].As<Napi::Number>().Int32Value()};

    NSString *wallpaperPath = _GetWallpaperPathForScreen(displayID);
    
    Napi::String res = Napi::String::New(env, std::string([wallpaperPath UTF8String]));
    return res;
}

void _GetWallpaperOptionsForScreen(int displayID, NSNumber **scaling, NSNumber **allowClipping, NSColor **fillColor) {
    NSScreen *screen = GetScreenWithID((CGDirectDisplayID) displayID);
    if (screen == nil)
        return;
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSDictionary<NSWorkspaceDesktopImageOptionKey, id> *options = [workspace desktopImageOptionsForScreen:screen];
    *scaling = options[NSWorkspaceDesktopImageScalingKey];
    *allowClipping = options[NSWorkspaceDesktopImageAllowClippingKey];
    *fillColor = options[NSWorkspaceDesktopImageFillColorKey];
}

Napi::Object GetWallpaperOptionsForScreen(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto displayID{info[0].As<Napi::Number>().Int32Value()};

    NSNumber *scaling, *allowClipping;
    NSColor *fillColor;

    _GetWallpaperOptionsForScreen(displayID, &scaling, &allowClipping, &fillColor);

    auto obj = Napi::Object::New(env);
    obj.Set(Napi::String::New(env, "scaling"), scaling == nil ? -1 : Napi::Number::New(env, [scaling intValue]));
    obj.Set(Napi::String::New(env, "allowClipping"), allowClipping == nil ? -1 : Napi::Number::New(env, [allowClipping intValue]));
    obj.Set(Napi::String::New(env, "red"), Napi::Number::New(env, (double)[fillColor redComponent]));
    obj.Set(Napi::String::New(env, "green"), Napi::Number::New(env, (double)[fillColor greenComponent]));
    obj.Set(Napi::String::New(env, "blue"), Napi::Number::New(env, (double)[fillColor blueComponent]));
    obj.Set(Napi::String::New(env, "alpha"), Napi::Number::New(env, (double)[fillColor alphaComponent]));
    return obj;
}

Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports.Set("SetWallpaper", Napi::Function::New(env, SetWallpaper));
  exports.Set("GetWallpaperPathForScreen", Napi::Function::New(env, GetWallpaperPathForScreen));
  exports.Set("GetWallpaperOptionsForScreen", Napi::Function::New(env, GetWallpaperOptionsForScreen));
  return exports;
}

NODE_API_MODULE(desktopwallpaper, Init)
