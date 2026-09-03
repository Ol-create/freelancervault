package com.bmoniembeddedsdk

import com.facebook.react.TurboReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider

class BmoniEmbeddedSdkPackage : TurboReactPackage() {
  override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? {
    return if (name == BmoniEmbeddedSdkModule.NAME) {
      BmoniEmbeddedSdkModule(reactContext)
    } else {
      null
    }
  }

  override fun getReactModuleInfoProvider(): ReactModuleInfoProvider {
    return ReactModuleInfoProvider {
      mapOf(
        BmoniEmbeddedSdkModule.NAME to ReactModuleInfo(
          BmoniEmbeddedSdkModule.NAME,
          BmoniEmbeddedSdkModule.NAME,
          false, // canOverrideExistingModule
          false, // needsEagerInit
          false, // isCxxModule
          true // isTurboModule
        )
      )
    }
  }
}
