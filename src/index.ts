import {DesktopWallpaper} from './addons';

console.log(DesktopWallpaper.SetWallpaper(
    111,
    '',
    0,
    0,
    0,
    0,
    0,
    1
));

console.log(DesktopWallpaper.GetWallpaperPathForScreen(111));

console.log(DesktopWallpaper.GetWallpaperOptionsForScreen(111));
