#include <napi.h>

#import <Appkit/Appkit.h>

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

bool _SetWallpaper(int displayID, NSString *wallpaperPath, NSNumber *scalingKey, NSNumber *allowClipping, NSColor *fillColor, NSError *error) {
    NSScreen *screen = GetScreenWithID((CGDirectDisplayID) displayID);
    if (screen == nil)
        return false;

    NSDictionary<NSWorkspaceDesktopImageOptionKey, id> *options = @{
        NSWorkspaceDesktopImageScalingKey: scalingKey,
        NSWorkspaceDesktopImageAllowClippingKey: allowClipping,
        NSWorkspaceDesktopImageFillColorKey: fillColor
    };

    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSURL *wallpaperURL = [NSURL fileURLWithPath:wallpaperPath];
    [workspace setDesktopImageURL:wallpaperURL forScreen:screen options:options error:&error];
    return true;
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

    NSError *error = nil;
    bool success = _SetWallpaper(displayID, @(wallpaperPath.c_str()), @(scaling), @(allowClipping), rgbaColor, error);
    
    Napi::String res;
    if (success) {
        if (error == nil)
            res = Napi::String::New(env, "");
        else
            res = Napi::String::New(env, error.localizedDescription.UTF8String);
    }
    else
        res = Napi::String::New(env, "Invalid displayID");
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
    
    Napi::String res = Napi::String::New(env, wallpaperPath == nil ? "" : std::string([wallpaperPath UTF8String]));
    return res;
}

bool _GetWallpaperOptionsForScreen(int displayID, NSNumber **scaling, NSNumber **allowClipping, NSColor **fillColor) {
    NSScreen *screen = GetScreenWithID((CGDirectDisplayID) displayID);
    if (screen == nil)
        return false;
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSDictionary<NSWorkspaceDesktopImageOptionKey, id> *options = [workspace desktopImageOptionsForScreen:screen];
    *scaling = options[NSWorkspaceDesktopImageScalingKey];
    *allowClipping = options[NSWorkspaceDesktopImageAllowClippingKey];
    *fillColor = options[NSWorkspaceDesktopImageFillColorKey];
    return true;
}

Napi::Object GetWallpaperOptionsForScreen(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto displayID{info[0].As<Napi::Number>().Int32Value()};

    NSNumber *scaling, *allowClipping;
    NSColor *fillColor;

    bool success = _GetWallpaperOptionsForScreen(displayID, &scaling, &allowClipping, &fillColor);

    auto obj = Napi::Object::New(env);
    if (success) {
        obj.Set(Napi::String::New(env, "scaling"), Napi::Number::New(env, scaling == nil ? -1 : [scaling intValue]));
        obj.Set(Napi::String::New(env, "allowClipping"), Napi::Number::New(env, allowClipping == nil ? -1 : [allowClipping intValue]));
        obj.Set(Napi::String::New(env, "red"), Napi::Number::New(env, (double)[fillColor redComponent]));
        obj.Set(Napi::String::New(env, "green"), Napi::Number::New(env, (double)[fillColor greenComponent]));
        obj.Set(Napi::String::New(env, "blue"), Napi::Number::New(env, (double)[fillColor blueComponent]));
        obj.Set(Napi::String::New(env, "alpha"), Napi::Number::New(env, (double)[fillColor alphaComponent]));
    }
    return obj;
}

Napi::Object Init(Napi::Env env, Napi::Object exports) {
  exports.Set("SetWallpaper", Napi::Function::New(env, SetWallpaper));
  exports.Set("GetWallpaperPathForScreen", Napi::Function::New(env, GetWallpaperPathForScreen));
  exports.Set("GetWallpaperOptionsForScreen", Napi::Function::New(env, GetWallpaperOptionsForScreen));
  return exports;
}

NODE_API_MODULE(desktopwallpaper, Init)
