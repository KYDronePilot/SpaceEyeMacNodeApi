import { DesktopWallpaper as DesktopWallpaperRaw } from './addons';

/**
 * How to scale the desktop image.
 */
export enum ImageScaling {
    /**
     * Scale each dimension to exactly fit destination.
     */
    axesIndependently = 1,

    /**
     * Do not scale the image.
     */
    none = 2,

    /**
     * Scale the image to its maximum possible dimensions while both
     * staying within the destination area and preserving its aspect ratio.
     */
    proportionallyUpOrDown = 3,
}

/**
 * Color to fill in the margins not covered by the desktop image.
 */
export interface DesktopFillColor {
    /**
     * Red channel: (0 - 255)
     */
    red: number;

    /**
     * Green channel: (0 - 255)
     */
    green: number;

    /**
     * Blue channel: (0 - 255)
     */
    blue: number;

    /**
     * Alpha channel: (0.0 - 1.0)
     */
    alpha: number;
}

/**
 * Options for displaying the desktop image on a particular screen.
 */
export interface DesktopImageOptions {
    /**
     * How to scale the desktop image.
     */
    imageScaling: ImageScaling

    /**
     * Whether to allow parts of the image to be clipped when scaling.
     */
    allowClipping: boolean

    /**
     * Color to fill in the margins not covered by the desktop image.
     */
    desktopFillColor: DesktopFillColor
}

/**
 * Convert a color float value to an 8-bit int representation.
 * @param color - 0.0 - 1.0 color value
 * @return 8-bit int representation of color
 */
function _floatTo8bitColor(color: number): number {
    return Math.round(color * 255)
}

/**
 * Convert a color 8-bit int value to a float representation.
 * @param color - 8-bit int representation of color
 * @return 0.0 - 1.0 color value
 */
function _8bitColorToFloat(color: number): number {
    return color / 255
}

/**
 * Get the wallpaper options for a particular screen.
 * @throws Error if none of the values are set (displayID likely invalid)
 * @param displayID - ID of screen
 * @return Desktop image options for screen
 */
export function GetWallpaperOptionsForScreen(displayID: number): DesktopImageOptions {
    const rawOptions = DesktopWallpaperRaw.GetWallpaperOptionsForScreen(
        displayID
    )
    if (
        rawOptions.scaling == undefined
        && rawOptions.allowClipping == undefined
        && rawOptions.red == undefined
        && rawOptions.green == undefined
        && rawOptions.blue == undefined
        && rawOptions.alpha == undefined
    )
        throw new Error('displayID likely invalid')
    return {
        imageScaling: rawOptions.scaling! == -1 ? ImageScaling.proportionallyUpOrDown : rawOptions.scaling! as ImageScaling,
        allowClipping: rawOptions.allowClipping! == 0,  // -1 and 1 are equivalent in this case
        desktopFillColor: {
            red: _floatTo8bitColor(rawOptions.red!),
            green: _floatTo8bitColor(rawOptions.green!),
            blue: _floatTo8bitColor(rawOptions.blue!),
            alpha: rawOptions.alpha!,
        }
    }
}

/**
 * Get the wallpaper path for a particular screen.
 * @param displayID - ID of screen
 * @return Path to image
 */
export function GetWallpaperPathForScreen(displayID: number): string {
    return DesktopWallpaperRaw.GetWallpaperPathForScreen(displayID)
}

/**
 * Set the wallpaper image for a screen.
 * @throws Error if an error occurs while setting the wallpaper
 * @param displayID - ID of screen
 * @param wallpaperPath - Path to image
 * @param options - Desktop image options
 */
export function SetWallpaper(displayID: number, wallpaperPath: string, options?: DesktopImageOptions) {
    const fullOptions = options ?? GetWallpaperOptionsForScreen(displayID);
    const res = DesktopWallpaperRaw.SetWallpaper(
        displayID,
        wallpaperPath,
        fullOptions.imageScaling,
        fullOptions.allowClipping ? 0 : 1,
        _8bitColorToFloat(fullOptions.desktopFillColor.red),
        _8bitColorToFloat(fullOptions.desktopFillColor.green),
        _8bitColorToFloat(fullOptions.desktopFillColor.blue),
        _8bitColorToFloat(fullOptions.desktopFillColor.alpha),
    )
    if (res !== '')
        throw new Error(`Error setting wallpaper: ${res}`)
}
