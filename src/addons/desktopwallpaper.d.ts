export function SetWallpaper(
    displayID: number,
    wallpaperPath: string,
    scaling: number,
    allowClipping: number,
    red: number,
    green: number,
    blue: number,
    alpha: number
): string

export function GetWallpaperPathForScreen(displayID: number): string

export interface ReturnedWallpaperOptions {
    scaling?: number
    allowClipping?: number
    red?: number
    green?: number
    blue?: number
    alpha?: number
}

export function GetWallpaperOptionsForScreen(displayID: number): ReturnedWallpaperOptions
