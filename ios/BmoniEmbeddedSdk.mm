#import "BmoniEmbeddedSdk.h"

#if __has_include("bmoni_embedded_sdk-Swift.h")
#import "bmoni_embedded_sdk-Swift.h"
#else
#import <bmoni_embedded_sdk/bmoni_embedded_sdk-Swift.h>
#endif

@implementation BmoniEmbeddedSdk {
  BmoniEmbeddedSdkImpl *_impl;
}

RCT_EXPORT_MODULE(BmoniEmbeddedSdk)

- (instancetype)init {
  if (self = [super init]) {
    _impl = [BmoniEmbeddedSdkImpl new];
  }
  return self;
}

- (void)initialize:(double)pinLength requirePin:(BOOL)requirePin {
  [_impl initializeWithPinLength:pinLength requirePin:requirePin];
}

- (void)initWallet:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [_impl initWalletWithResolve:resolve reject:reject];
}

- (void)walletAddress:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [_impl walletAddressWithResolve:resolve reject:reject];
}

- (void)hasWallet:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [_impl hasWalletWithResolve:resolve reject:reject];
}

- (void)deleteWallet:(NSString *)pin resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [_impl deleteWalletWithPin:pin resolve:resolve reject:reject];
}

- (void)setPin:(NSString *)pin resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [_impl setPinWithPin:pin resolve:resolve reject:reject];
}

- (void)changePin:(NSString *)currentPin newPin:(NSString *)newPin resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [_impl changePinWithCurrentPin:currentPin newPin:newPin resolve:resolve reject:reject];
}

- (void)removePin:(NSString *)currentPin resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [_impl removePinWithCurrentPin:currentPin resolve:resolve reject:reject];
}

- (void)matchPin:(NSString *)pin resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [_impl matchPinWithPin:pin resolve:resolve reject:reject];
}

- (void)hasPin:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [_impl hasPinWithResolve:resolve reject:reject];
}

- (void)signMessage:(NSString *)message pin:(NSString *)pin resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [_impl signMessageWithMessage:message pin:pin resolve:resolve reject:reject];
}

- (void)signTransactionHash:(NSString *)hashHex pin:(NSString *)pin resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [_impl signTransactionHashWithHashHex:hashHex pin:pin resolve:resolve reject:reject];
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeBmoniEmbeddedSdkSpecJSI>(params);
}

@end
