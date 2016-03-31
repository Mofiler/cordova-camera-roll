/**
 * Camera Roll PhoneGap Plugin. 
 *
 * Reads photos from the iOS Camera Roll.
 *
 * Copyright 2013 Drifty Co.
 * http://drifty.com/
 *
 * See LICENSE in this project for licensing info.
 */

#import "IonicCameraRoll.h"
#import <Cordova/CDV.h>
#import <AssetsLibrary/ALAssetRepresentation.h>
#import <CoreLocation/CoreLocation.h>
#import <AssetsLibrary/AssetsLibrary.h>
// #import "NSData+Base64.h"

@implementation IonicCameraRoll

  + (ALAssetsLibrary *)defaultAssetsLibrary {
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
      library = [[ALAssetsLibrary alloc] init];
    });

    // TODO: Dealloc this later?
    return library;
  }
  
- (void)saveToCameraRoll:(CDVInvokedUrlCommand*)command
{
  NSString *base64String = [command argumentAtIndex:0];
//  NSURL *url = [NSURL URLWithString:base64String];    
//  NSData *imageData = [NSData dataWithContentsOfURL:url];
//  UIImage *image = [UIImage imageWithData:imageData];
    
  // NSData* imageData = [NSData dataFromBase64String:base64String];
  NSData* imageData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];

  // NSData* imageData = [NSData dataWithBase64EncodedString:base64String];
  
    
//    UIImage* image = [[UIImage alloc] initWithData:imageData];
  UIImage *image = [UIImage imageWithData:imageData];

  // save the image to photo album
  UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);

  CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"saved"];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
/**
 * Get all the photos in the library.
 *
 * TODO: This should support block-type reading with a set of images
 */
- (void)getPhotos:(CDVInvokedUrlCommand*)command
{
  
  // Grab the asset library
  ALAssetsLibrary *library = [IonicCameraRoll defaultAssetsLibrary];
  
  // Run a background job
  [self.commandDelegate runInBackground:^{
    
    // Enumerate all of the group saved photos, which is our Camera Roll on iOS
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
      
      // When there are no more images, the group will be nil
      if(group == nil) {
        
        // Send a null response to indicate the end of photostreaming
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:nil];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
      
      } else {
        
        // Enumarate this group of images
        
        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
          
          NSDictionary *urls = [result valueForProperty:ALAssetPropertyURLs];
          
          [urls enumerateKeysAndObjectsUsingBlock:^(id key, NSURL *obj, BOOL *stop) {

            // Send the URL for this asset back to the JS callback
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:obj.absoluteString];
            [pluginResult setKeepCallbackAsBool:YES];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
          
          }];
        }];
      }
    } failureBlock:^(NSError *error) {
      // Ruh-roh, something bad happened.
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
  }];

}

-(void)find:(CDVInvokedUrlCommand*)command {
    
    NSInteger max = [[command.arguments objectAtIndex:0] integerValue];
    
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                           usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                               if (group == nil) {
                                   return;
                               }
                               [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                               
//                               if ([group numberOfAssets] > 0) {
                               
//                               [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *innerStop) {
                               
                               
//                               [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:[group numberOfAssets]-max]
//                                                       options:0
//                                                    usingBlock:^(ALAsset *result, NSUInteger index, BOOL *innerStop) {
                                 [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *innerStop) {
                               
                                   if (result == nil) {
                                       return;
                                   }

                                     
                                     ALAssetRepresentation *representation = [result defaultRepresentation];
                                     NSString* url = [[result valueForProperty:ALAssetPropertyAssetURL] absoluteString];
//                                     CGImageRef thumbnailImageRef = [representation fullScreenImage];
                                     CGImageRef thumbnailImageRef = [result aspectRatioThumbnail];
                                     UIImage* thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];
                                     NSString* base64encoded = [UIImageJPEGRepresentation(thumbnail, 1) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                                     base64encoded = [@"data:image/jpg;base64," stringByAppendingString:base64encoded];
                                     
                                     NSDictionary* photo = @{
                                                             @"url": url,
                                                             @"base64encoded": base64encoded
                                                             };
                                     
                                     [photos addObject:photo];
                                     
                                     if (photos.count >= max) {
                                         *innerStop = YES;
                                         *stop = YES;
                                     }
                                     
                                     /*
                                     NSString* url = [[result valueForProperty:ALAssetPropertyAssetURL] absoluteString];
                                     CGImageRef thumbnailImageRef = [result thumbnail];
                                     UIImage* thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];
//                                     NSString* base64encoded = [UIImageJPEGRepresentation(thumbnail, 1) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                                     NSString* base64encoded = [UIImageJPEGRepresentation(thumbnail, 1) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                                     NSDictionary* photo = @{
                                                             @"url": url,
                                                             @"base64encoded": base64encoded
                                                             };
                                     [photos addObject:base64encoded];
                                     
                                     
                                     NSURL *urld = (NSURL*) [[result defaultRepresentation]url];
//                                     NSData *imageData = [NSData dataWithContentsOfURL:urld];
//                                     NSString *base64EncodedImage = [imageData base64EncodedStringWithOptions:kNilOptions];
                                   
//                                     [photos addObject:base64EncodedImage];
//                                     [photos addObject:urld.absoluteString];
                                     if (photos.count >= max) {
                                         *innerStop = YES;
                                         *stop = YES;
                                     }
                                      */

                               }];
                               
                               if (photos.count > 0) {
                                   CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:photos];
                                   [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                               } else {
                                   CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                                   [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                               }
                               
                           } failureBlock:^(NSError *error) {
                               NSLog(@"%@", [error localizedDescription]);
                               CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                               [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                           }];




}

@end

