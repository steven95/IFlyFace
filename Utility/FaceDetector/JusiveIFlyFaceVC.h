//
//  FaceStreamDetectorViewController.h
//  IFlyFaceDemo
//
//  Created by 付正 on 16/3/1.
//  Copyright (c) 2016年 fuzheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "iflyMSC/IFlyFaceSDK.h"
@protocol FaceDetectorDelegate <NSObject>

-(void)sendFaceImage:(NSMutableArray *)arrimG with:(UIViewController *)uSelf; //上传图片成功
-(void)sendFaceImageErrorWith:(UIViewController *)uSelf; //上传图片失败

@end

@interface JusiveIFlyFaceVC : UIViewController
@property (nonatomic,copy) NSString * appid;
@property (assign,nonatomic) id<FaceDetectorDelegate> faceDelegate;

@end
