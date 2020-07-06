//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Metal

final class MetalContext {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let textureCache: CVMetalTextureCache
    let library: MTLLibrary
    
    init(device: MTLDevice, commandQueue: MTLCommandQueue, textureCache: CVMetalTextureCache, library: MTLLibrary) {
        self.device = device
        self.commandQueue = commandQueue
        self.textureCache = textureCache
        self.library = library
    }
}
