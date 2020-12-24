import { spawn, SpawnOptions } from 'child_process'
import * as fse from 'fs-extra'
import { parallel, series } from 'gulp'
import * as path from 'path'

const NODE_MODULES_BIN = path.join(__dirname, 'node_modules', '.bin')
const EXTENDED_PATH = NODE_MODULES_BIN + path.delimiter + (process.env.PATH ?? '')
const BUILD = path.join(__dirname, 'build')
const SRC = path.join(__dirname, 'src')
const DIST = path.join(__dirname, 'dist')
const SRC_ADDONS = path.join(SRC, 'addons')
const DIST_ADDONS = path.join(DIST, 'addons')
const DIST_ADDON_FILE = path.join(DIST_ADDONS, 'desktopwallpaper.node')
const BUILT_RELEASE_ADDON = path.join(BUILD, 'Release', 'desktopwallpaper.node')

const defaultSpawnOptions: SpawnOptions = {
    env: {
        PATH: EXTENDED_PATH
    },
    stdio: 'inherit'
}

/**
 * Clean old build/dist files.
 */
async function clean() {
    return Promise.all([
        fse.remove(BUILD),
        fse.remove(DIST)
    ])
}

/**
 * Configure node-gyp.
 */
function configure() {
    return spawn('node-gyp', ['configure'], defaultSpawnOptions)
}

/**
 * Build the addon.
 */
function buildAddon() {
    return spawn('node-gyp', ['build'], defaultSpawnOptions)
}

/**
 * Build the library TS files.
 */
function buildTs() {
    return spawn('tsc', ['-b'], defaultSpawnOptions)
}

/**
 * Copy addon built TS files and .node native library.
 */
async function copyAddonFiles() {
    await fse.copy(SRC_ADDONS, DIST_ADDONS)
    await fse.copy(BUILT_RELEASE_ADDON, DIST_ADDON_FILE)
}

const prepare = series(clean, configure)
const buildSrc = parallel(buildTs, buildAddon)

export const build = series(prepare, buildSrc, copyAddonFiles)
