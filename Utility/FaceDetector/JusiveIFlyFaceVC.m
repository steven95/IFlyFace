//
//  FaceStreamDetectorViewController.m
//  IFlyFaceDemo
//
//  Created by 付正 on 16/3/1.
//  Copyright (c) 2016年 fuzheng. All rights reserved.
//
#import <SVProgressHUD/SVProgressHUD.h>
#import "JusiveIFlyFaceVC.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import "PermissionDetector.h"
#import "UIImage+Extensions.h"
#import "UIImage+compress.h"
#import "iflyMSC/IFlyFaceSDK.h"
#import "DemoPreDefine.h"
#import "CaptureManager.h"
#import "CanvasView.h"
#import "CalculatorTools.h"
#import "UIImage+Extensions.h"
#import "IFlyFaceImage.h"
#import "IFlyFaceResultKeys.h"
#import "UIImage+GIFTool.h"
#import "UIImage+Extensions.h"

static dispatch_once_t headupOnceToken;
static dispatch_once_t mouthOnceToken;
static dispatch_once_t shakeOnceToken;
static dispatch_once_t eyeOnceToken;
static dispatch_once_t headDownOnceToken;
@interface JusiveIFlyFaceVC ()<CaptureManagerDelegate>
{
    CGFloat aroundnum;
    int numcount;
    UILabel *alignLabel;
    int number;//
    NSTimer *timer;
    UIImageView *imgView;//动画图片展示
    //拍照操作
    AVCaptureStillImageOutput *myStillImageOutput;
    UIView *backView;//照片背景
    UIImageView *imageView;//照片展示
    int takePhotoNumber;
    int takePhoto;
    BOOL isCrossBorder;//判断是否越界
    BOOL isJudgeMouth;//判断张嘴操作完成
    BOOL isShakeHead;//判断摇头操作完成
    BOOL isDownHead;//判断低头操作完成
    BOOL isUpHead;//判断抬头操作完成
    BOOL isReShakeHead;//判断连续摇头操作完成
    BOOL isReDownlowHead;//判断连续低头操作完成
    BOOL isReUpHead;//判断连续抬头操作完成
    BOOL isAround; //判断前后摆动
    BOOL isReOpnEye; //判断眨眼
    BOOL isCrossleft;//左旋
    BOOL isCrossright;//右旋
    //嘴角坐标
    int leftX;
    int rightX;
    int lowerY;
    int upperY;
    //判断张嘴嘴型的宽高（初始的和后来变化的）
    int mouthWidthF;
    int mouthHeightF;
    int mouthWidth;
    int mouthHeight;
    //摇头嘴中点的数据
    int bigNumber;
    int smallNumber;
    //鼻子上下中点的数据
    int nosetop;
    int nose_top;
    int nosebottom;
    int nose_bottom;
    //前后位置
    CGFloat foraround;
    //左右眼睛坐标
    int left_eye_left;
    int right_eye_right;
}
@property (nonatomic, assign) BOOL faceFound;
@property (nonatomic, assign) BOOL isEyeTakePhoto;
@property (nonatomic,strong) NSMutableArray * ImageArr;
@property (nonatomic,strong) NSMutableArray * arrImage;
@property (nonatomic,strong) NSUserDefaults * isKeyFunc;
@property (nonatomic,strong) NSMutableSet * setKeyFunc;
@property (nonatomic,strong) NSMutableArray * arrKeyFunc;
@property (nonatomic,strong) NSMutableArray * KeyFunc;
@property (nonatomic, retain ) UIView  *previewView;
@property (nonatomic, strong ) UILabel *textLabel;
@property (nonatomic, retain ) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, retain ) CaptureManager             *captureManager;
@property (nonatomic, retain ) IFlyFaceDetector           *faceDetector;
@property (nonatomic, strong) CIDetector *ctfaceDetector;
@property (nonatomic, strong ) UITapGestureRecognizer     *tapGesture;
@property (nonatomic,strong) UIImageView * faceimgV;
@end

@implementation JusiveIFlyFaceVC
@synthesize captureManager;

-(NSMutableArray *)ImageArr{
    if (_ImageArr  ==  nil) {
        _ImageArr  =  [NSMutableArray array];
    }
    return  _ImageArr;
}
-(NSMutableArray *)arrImage{
    if (_arrImage  ==  nil) {
        _arrImage  =  [NSMutableArray array];
    }
    return  _arrImage;
}
-(NSMutableArray *)arrKeyFunc{
    if (_arrKeyFunc  ==  nil) {
        _arrKeyFunc  =  [NSMutableArray array];
    }
    return _arrKeyFunc;
}
-(NSUserDefaults *)isKeyFunc{
    if (_isKeyFunc  ==  nil) {
        _isKeyFunc  =  [NSUserDefaults standardUserDefaults];
        [_isKeyFunc setBool:isJudgeMouth forKey:@"FaceOpenMouth"];
        [_isKeyFunc setBool:isReShakeHead forKey:@"ReFaceShakeHead"];
        [_isKeyFunc setBool:isReOpnEye forKey:@"ReOpenEye"];
        [_isKeyFunc setBool:isReUpHead forKey:@"ReFaceUpHead"];
//        [_isKeyFunc setBool:isReDownlowHead forKey:@"ReFacedownHead"];
//
//        [_isKeyFunc setBool:isAround forKey:@"Faceround"];
//        [_isKeyFunc setBool:isCrossleft forKey:@"Crossleft"];
//        [_isKeyFunc setBool:isCrossright forKey:@"Crossright"];
        [_isKeyFunc synchronize];
    }
    return _isKeyFunc;
}
-(NSMutableArray *)KeyFunc{
    if (_KeyFunc  ==  nil) {
        _KeyFunc  =  [NSMutableArray array];
        [_KeyFunc addObject:@"FaceOpenMouth"];
        [_KeyFunc addObject:@"ReFaceShakeHead"];
        [_KeyFunc addObject:@"ReOpenEye"];
        [_KeyFunc addObject:@"ReFaceUpHead"];
//        [_KeyFunc addObject:@"ReFacedownHead"];
        
//        [_KeyFunc addObject:@"Faceround"];
//        [_KeyFunc addObject:@"Crossleft"];
//        [_KeyFunc addObject:@"Crossright"];
    }
    return _KeyFunc;
}
-(NSMutableSet *)setKeyFunc{
    
    if (_setKeyFunc  ==  nil) {
        _setKeyFunc  =  [NSMutableSet set];
    }
    return _setKeyFunc;
}

-(void)setAppid:(NSString *)appid{
    _appid  =  appid;
}


- (CIDetector *)ctfaceDetector
{
    if (!_ctfaceDetector) {
        // setup the accuracy of the detector
        NSDictionary *detectorOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                         CIDetectorAccuracyHigh, CIDetectorAccuracy, nil];
        
        _ctfaceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    }
    return _ctfaceDetector;
}


-(void)viewDidLoad
{
    [super viewDidLoad];
    
    _isEyeTakePhoto = YES;
    //设置log等级，此处log为默认在app沙盒目录下的msc.log文件
    [IFlySetting setLogFile:LVL_ALL];
    
    //输出在console的log开关
    [IFlySetting showLogcat:YES];
    
    NSArray *paths  =  NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath  =  [paths objectAtIndex:0];
    //设置msc.log的保存路径
    [IFlySetting setLogFilePath:cachePath];
    
    //创建语音配置,appid必须要传入，仅执行一次则可
    NSString *initString  =  [[NSString alloc] initWithFormat:@"appid = %@,",self.appid];
    
    //所有服务启动前，需要确保执行createUtility
    [IFlySpeechUtility createUtility:initString];
    
    NSDictionary *dictionary  =  [self.isKeyFunc dictionaryRepresentation];
    for(NSString *key in [dictionary allKeys]){
        [self.isKeyFunc removeObjectForKey:key];
        [self.isKeyFunc synchronize];
    }
    self.view.backgroundColor  =  [UIColor whiteColor];
    //创建界面
    [self makeUI];
    //创建摄像页面
    [self makeCamera];
    //创建数据
    [self makeNumber];
    [self.setKeyFunc removeAllObjects];
    for (int i  =  0; i < 2; i++) {
    [self.setKeyFunc addObject:self.KeyFunc[(arc4random() % 4)]];
        if (self.setKeyFunc.count !=  2 && i  ==  1) {
            i--;
        }
        NSLog(@"self.setKeyFunc%@",self.setKeyFunc);
    }
    
    [self.setKeyFunc enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        [self.arrKeyFunc addObject:obj];
        NSLog(@"self.arrKeyFunc%@",self.arrKeyFunc);
    }];

}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
   
    //停止摄像
    [self.previewLayer.session stopRunning];
    [self.captureManager removeObserver];
}

-(void)makeNumber
{
    takePhoto  =  0;
    takePhotoNumber  =  0;
    isCrossright  =  NO;
    isCrossleft  =  NO;
    isReShakeHead  =  NO;
    isReDownlowHead  =  NO;
    isJudgeMouth  =  NO;
    isAround  =  NO;
    //张嘴数据
    number  =  0;
    mouthWidthF  =  0;
    mouthHeightF  =  0;
    mouthWidth  =  0;
    mouthHeight  =  0;
    //摇头数据
    bigNumber  =  0;
    smallNumber  =  0;
    //低头数据
    nosetop  =  0;
    nose_top  =  0;
    nose_bottom  =  0;
    nosebottom  =  0;
    //调用次数
    numcount  =  0;
    //前后数据
    foraround  =  0;
    left_eye_left  =  0   ;
    right_eye_right  =  0;
}

#pragma mark --- 创建UI界面
-(void)makeUI
{
    self.previewView  =  [[UIView alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight*2/3)];
    [self.view addSubview:self.previewView];
    //提示框
    imgView  =  [[UIImageView alloc]initWithFrame:CGRectMake((ScreenWidth-ScreenHeight/6+10)/2, CGRectGetMaxY(self.previewView.frame)+10, ScreenHeight/6-10, ScreenHeight/6-10)];
    NSBundle* bundle   =    [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"JusiveIFlyFace" ofType:@"bundle"]];
    NSString *path  =    [bundle pathForResource:@"faceBounds" ofType:@"png"];
    imgView.image = [UIImage imageWithContentsOfFile:path];
    [self.view addSubview:imgView];
    self.textLabel  =  [[UILabel alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(imgView.frame)+5, ScreenWidth, 30)];
    self.textLabel.textAlignment  =  NSTextAlignmentCenter;
    self.textLabel.text  =  @"请按提示做动作";
    self.textLabel.textColor  =  [UIColor whiteColor];
    [self.view addSubview:self.textLabel];
    //背景View
    backView  =  [[UIView alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight-64)];
    backView.backgroundColor  =  [UIColor lightGrayColor];
    //图片放置View
    imageView  =  [[UIImageView alloc]initWithFrame:CGRectMake(0, 10, ScreenWidth, ScreenWidth*4/3)];
    [backView addSubview:imageView];

}

#pragma mark --- 创建相机
-(void)makeCamera
{
    self.title  =  @"活体检测";
    //adjust the UI for iOS 7
#if __IPHONE_OS_VERSION_MAX_ALLOWED >=  70000
    if ( IOS7_OR_LATER ){
        self.edgesForExtendedLayout  =  UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars  =  NO;
        self.modalPresentationCapturesStatusBarAppearance  =  NO;
        self.navigationController.navigationBar.translucent  =  NO;
    }
#endif
    
    self.view.backgroundColor = [UIColor blackColor];
    self.previewView.backgroundColor = [UIColor clearColor];
    
    //设置初始化打开识别
    self.faceDetector = [IFlyFaceDetector sharedInstance];
    [self.faceDetector setParameter:@"1" forKey:@"detect"];
    [self.faceDetector setParameter:@"1" forKey:@"align"];
    [self.faceDetector setParameter:@"1" forKey:@"attr"];
    //初始化 CaptureSessionManager
    self.captureManager  =  [[CaptureManager alloc] init];
    self.captureManager.delegate  =  self;
    self.previewLayer  =  self.captureManager.previewLayer;
    self.captureManager.previewLayer.frame  =   self.previewView.frame;
self.captureManager.previewLayer.position  =  self.previewView.center;    self.captureManager.previewLayer.videoGravity  =  AVLayerVideoGravityResizeAspectFill;
    [self.previewView.layer addSublayer:self.captureManager.previewLayer];
    
    self.faceimgV  =  [[UIImageView alloc]initWithFrame:self.captureManager.previewLayer.frame];
//    [self.faceimgV setImage:[UIImage imageNamed:@"人物头像蒙版"]];
    
    NSBundle* bundle   =    [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"JusiveIFlyFace" ofType:@"bundle"]];
    NSString *path  =    [bundle pathForResource:@"faceBounds" ofType:@"png"];
    self.faceimgV.image = [UIImage imageWithContentsOfFile:path];
    
    [self.previewView addSubview:self.faceimgV] ;
    NSString *str  =  [NSString stringWithFormat:@"{{%f, %f}, {220, 240}}",(ScreenWidth-220)/2,(ScreenWidth-240)/2+15];
    NSMutableDictionary *dic  =  [[NSMutableDictionary alloc]init];
    [dic setObject:str forKey:@"RECT_KEY"];
    [dic setObject:@"1" forKey:@"RECT_ORI"];
    NSMutableArray *arr  =  [[NSMutableArray alloc]init];
    [arr addObject:dic];

    
    //建立 AVCaptureStillImageOutput
    myStillImageOutput  =  [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *myOutputSettings  =  [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
    [myStillImageOutput setOutputSettings:myOutputSettings];
    [self.captureManager.session addOutput:myStillImageOutput];
    //开始摄像
    [self.captureManager setup];
    [self.captureManager addObserver];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    [self.captureManager observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}
//代理之后开启识别优先级2
#pragma mark - 开启识别
- (void) showFaceLandmarksAndFaceRectWithPersonsArray:(NSMutableArray *)arrPersons
{
    
}

//代理之后画识别框优先级2
#pragma mark --- 脸部框识别
-(NSString*)praseDetect:(NSDictionary* )positionDic OrignImage:(IFlyFaceImage*)faceImg
{
    if(!positionDic){
        return nil;
    }
    // 判断摄像头方向
    BOOL isFrontCamera = self.captureManager.videoDeviceInput.device.position == AVCaptureDevicePositionFront;
    
    // scale coordinates so they fit in the preview box, which may be scaled
    CGFloat widthScaleBy  =  self.previewLayer.frame.size.width / faceImg.height;
    CGFloat heightScaleBy  =  self.previewLayer.frame.size.height / faceImg.width;
    CGFloat bottom  = [[positionDic objectForKey:KCIFlyFaceResultBottom] floatValue];
    CGFloat top = [[positionDic objectForKey:KCIFlyFaceResultTop] floatValue];
    CGFloat left = [[positionDic objectForKey:KCIFlyFaceResultLeft] floatValue];
    CGFloat right = [[positionDic objectForKey:KCIFlyFaceResultRight] floatValue];
    float cx  =  (left+right)/2;
    float cy  =  (top + bottom)/2;
    float w  =  right - left;
    float h  =  bottom - top;
    float ncx  =  cy ;
    float ncy  =  cx ;
    CGRect rectFace  =  CGRectMake(ncx-w/2 ,ncy-w/2 , w, h);
    
    if(!isFrontCamera){
        rectFace = rSwap(rectFace);
        rectFace = rRotate90(rectFace, faceImg.height, faceImg.width);
    }
    
    //判断位置
    BOOL isNotLocation  =  [self identifyYourFaceLeft:left right:right top:top bottom:bottom];
    
    if (isNotLocation == YES) {
        return nil;
    }
    
    NSLog(@"left = %f right = %f top = %f bottom = %f",left,right,top,bottom);
    
    isCrossBorder  =  NO;
    
    rectFace = rScale(rectFace, widthScaleBy, heightScaleBy);
    
    return NSStringFromCGRect(rectFace);
}
//代理之后其次调用优先级2
#pragma mark --- 脸部部位识别
-(NSMutableArray*)praseAlign:(NSDictionary* )landmarkDic OrignImage:(IFlyFaceImage*)faceImg
{
    if(!landmarkDic){
        return nil;
    }
    // 判断摄像头方向
    BOOL isFrontCamera =  self.captureManager.videoDeviceInput.device.position ==  AVCaptureDevicePositionFront;
    // scale coordinates so they fit in the preview box, which may be scaled
    CGFloat widthScaleBy  =  self.previewLayer.frame.size.width / faceImg.height;
    CGFloat heightScaleBy  =  self.previewLayer.frame.size.height / faceImg.width;
    NSMutableArray *arrStrPoints  =  [NSMutableArray array];
     NSLog(@"jusive-arrStrPoints%@",arrStrPoints);
    NSEnumerator* keys = [landmarkDic keyEnumerator];
    NSLog(@"jusive-keys%@",keys);
    for(id key in keys){
        id attr = [landmarkDic objectForKey:key];
        if(attr && [attr isKindOfClass:[NSDictionary class]]){
            id attr = [landmarkDic objectForKey:key];
            CGFloat x = [[attr objectForKey:KCIFlyFaceResultPointX] floatValue];
            CGFloat y = [[attr objectForKey:KCIFlyFaceResultPointY] floatValue];
            CGPoint p  =  CGPointMake(y,x);
            if(!isFrontCamera){
                p = pSwap(p);
                p = pRotate90(p, faceImg.height, faceImg.width);
            }
            //判断是否越界
            if (isCrossBorder  ==  YES) {
                [self delateNumber];//清数据
                return nil;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                 [self acrefucnOpen:key p:p];
            });
            p = pScale(p, widthScaleBy, heightScaleBy);
            [arrStrPoints addObject:NSStringFromCGPoint(p)];
        }
    }
    return arrStrPoints;
}
//代理之后首先调用优先级1
#pragma mark --- 脸部识别
-(void)praseTrackResult:(NSString*)result OrignImage:(IFlyFaceImage*)faceImg
{
    if(!result){
        return;
    }
    @try {
        NSError* error;
        NSData* resultData = [result dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* faceDic = [NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error:&error];
        resultData = nil;
        if(!faceDic){
            return;
        }
        NSString* faceRet = [faceDic objectForKey:KCIFlyFaceResultRet];
        NSArray* faceArray = [faceDic objectForKey:KCIFlyFaceResultFace];
        faceDic = nil;
        int ret = 0;
        if(faceRet){
            ret = [faceRet intValue];
        }
        //没有检测到人脸或发生错误
        if (ret || !faceArray || [faceArray count]<1) {
            return;
        }
        //检测到人脸
        NSMutableArray *arrPersons  =  [NSMutableArray array] ;
        for(id faceInArr in faceArray){
            
            if(faceInArr && [faceInArr isKindOfClass:[NSDictionary class]]){
                
                NSDictionary* positionDic = [faceInArr objectForKey:KCIFlyFaceResultPosition];
                NSString* rectString = [self praseDetect:positionDic OrignImage: faceImg];
                positionDic = nil;
                
                NSDictionary* landmarkDic = [faceInArr objectForKey:KCIFlyFaceResultLandmark];
                NSMutableArray* strPoints = [self praseAlign:landmarkDic OrignImage:faceImg];
                landmarkDic = nil;
                NSMutableDictionary *dicPerson  =  [NSMutableDictionary dictionary] ;
                if(rectString){
                    [dicPerson setObject:rectString forKey:RECT_KEY];
                }
                if(strPoints){
                    [dicPerson setObject:strPoints forKey:POINTS_KEY];
                }
                strPoints = nil;
                [dicPerson setObject:@"0" forKey:RECT_ORI];
                [arrPersons addObject:dicPerson] ;
                dicPerson = nil;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showFaceLandmarksAndFaceRectWithPersonsArray:arrPersons];
                });
            }
        }
        faceArray = nil;
    }
    @catch (NSException *exception) {
        NSLog(@"prase exception:%@",exception.name);
    }
    @finally {
    }
}

#pragma mark - 图片处理
//修改image的大小
- (UIImage *)scaleToSize:(UIImage *)img size:(CGSize)size{
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContext(size);
    // 绘制改变大小的图片
    [img drawInRect:CGRectMake(0, 0, size.width, size.height)];
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    // 返回新的改变大小后的图片
    return scaledImage;
}

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    //释放context和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // 用Quartz image创建一个UIImage对象image
    //UIImage *image = [UIImage imageWithCGImage:quartzImage];
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0f orientation:UIImageOrientationRight];
    
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    
    return (image);
    
}

//代理入口 ----->实时调用
#pragma mark - CaptureManagerDelegate
-(void)onOutputFaceImage:(IFlyFaceImage*)faceImg faceImageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
        UIImage *_image  = [self scaleToSize:[self imageFromSampleBuffer:sampleBuffer] size:CGSizeMake(faceImg.width, faceImg.height)];
        CIImage* myImage = [CIImage imageWithCGImage:_image.CGImage];
        NSDictionary *options = @{ CIDetectorSmile: [NSNumber numberWithBool:YES], CIDetectorEyeBlink: [NSNumber numberWithBool:YES]};
        NSArray *features = [self.ctfaceDetector featuresInImage:myImage options:options];
        
        _faceFound = false;
        BOOL foundWink = NO;
        BOOL openWink = NO;
        if (features.count > 0 && isReOpnEye) {
            for (CIFaceFeature * face in features) {
                
                if (face.hasLeftEyePosition && face.hasRightEyePosition && face.hasMouthPosition) {
                    
                    BOOL leftEyeFound = [face hasLeftEyePosition];
                    BOOL rightEyeFound = [face hasRightEyePosition];
                    
                    // 没有眼睛，退出此次循环
                    if ( !leftEyeFound && !rightEyeFound )
                    {
                        continue;
                    }
                    CGPoint maoCenter = CGPointMake((face.leftEyePosition.x + face.rightEyePosition.x) * 0.5,
                                                    (face.mouthPosition.y+face.rightEyePosition.y) * 0.5);
                    if(CGRectContainsPoint(self.previewView.frame,maoCenter)){
                        _faceFound = true;
                        if (_isEyeTakePhoto == YES){
                        
                            BOOL leftEyeClosed = [face leftEyeClosed];
                            BOOL rightEyeClosed = [face rightEyeClosed];
                            if ( ! leftEyeClosed && ! rightEyeClosed ){
                                openWink = YES;
                            }else if (face.leftEyeClosed == YES && face.rightEyeClosed == YES ) {
                                foundWink = YES;
                                isReOpnEye = NO;
                                self.captureManager.isReOpnEye = isReOpnEye;
                                
                                [self.isKeyFunc setBool:foundWink forKey:@"ReOpenEye"];
                                [self.isKeyFunc synchronize];
                            }else
                            {
                                continue;
                            }
                        }
                    }
                }
            }
        }else{
        NSString* strResult = [self.faceDetector trackFrame:faceImg.data withWidth:faceImg.width height:faceImg.height direction:(int)faceImg.direction];
        NSLog(@"result:%@",strResult);
        
        //此处清理图片数据，以防止因为不必要的图片数据的反复传递造成的内存卷积占用。
        faceImg.data = nil;
        
        NSMethodSignature *sig  =  [self methodSignatureForSelector:@selector(praseTrackResult:OrignImage:)];
        if (!sig) return;
        NSInvocation* invocation  =  [NSInvocation invocationWithMethodSignature:sig];
        [invocation setTarget:self];
        [invocation setSelector:@selector(praseTrackResult:OrignImage:)];
        [invocation setArgument:&strResult atIndex:2];
        [invocation setArgument:&faceImg atIndex:3];
        [invocation retainArguments];
        [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil  waitUntilDone:NO];
        faceImg = nil;
    }
}
//代理之后计算数据优先级3
#pragma mark --- 判断位置
-(BOOL)identifyYourFaceLeft:(CGFloat)left right:(CGFloat)right top:(CGFloat)top bottom:(CGFloat)bottom
{
    aroundnum  =  bottom - top;
    NSLog(@"aroundnum%f",aroundnum);
    //判断位置
    if (right - left < 230 || bottom - top < 250) {
        self.textLabel.text  =  @"太远了...";
        NSLog(@"1太远了...");
        [self delateNumber];//清数据
        isCrossBorder  =  YES;
        return YES;
    }else if (right - left > 320 || bottom - top > 320) {
        self.textLabel.text  =  @"太近了...";
        NSLog(@"2太近了...");
        [self delateNumber];//清数据
        isCrossBorder  =  YES;
        return YES;
    }
    return NO;
}
-(void)acrefucnnum:(int)num key:(NSString *)key p:(CGPoint )p{
    
    if ([self.arrKeyFunc[num] isEqualToString:@"FaceOpenMouth"]) {
        [self identifyYourFaceOpenMouth:key p:p];
        dispatch_async(dispatch_get_main_queue(), ^{
              self.textLabel.text  =  @"请重复张嘴动作";
        });
        NSLog(@"111111111");
    }
    if ([self.arrKeyFunc[num] isEqualToString:@"ReFaceShakeHead"]) {
        [self identifyYourReFaceShakeHead:key p:p];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.textLabel.text  =  @"请持续摇头";
        });
        NSLog(@"222222222");
    }
    if ([self.arrKeyFunc[num] isEqualToString:@"ReFacedownHead"]) {
        [self identifyYourReFacedownHead:key p:p];
        dispatch_async(dispatch_get_main_queue(), ^{
              self.textLabel.text  =  @"请持续低头";
        });
        NSLog(@"3333333333");
    }
    
    if ([self.arrKeyFunc[num] isEqualToString:@"ReFaceUpHead"]) {
        [self identifyYourReFaceUpHead:key p:p];
        dispatch_async(dispatch_get_main_queue(), ^{
              self.textLabel.text  =  @"请持续抬头";
        });
        NSLog(@"22222222223333333333");
    }
    
    if ([self.arrKeyFunc[num] isEqualToString:@"Crossleft"]) {
        [self identifyYourFaceCrossleft:key p:p];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.textLabel.text  =  @"请来回向左旋转手机";
        });
        NSLog(@"444444444444");
    }
    if ([self.arrKeyFunc[num]  isEqualToString:@"Crossright"]) {
        [self identifyYourFaceCrossright:key p:p];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.textLabel.text  =  @"请来回向右旋转手机";
        });
        NSLog(@"55555555555");
    }
    if ([self.arrKeyFunc[num] isEqualToString:@"Faceround"]) {
        [self identifyYourFaceAround:aroundnum];
        dispatch_async(dispatch_get_main_queue(), ^{
              self.textLabel.text  =  @"请前后移动手机";
        });
        NSLog(@"666666666");
    }
    
    if ([self.arrKeyFunc[num] isEqualToString:@"ReOpenEye"]) {
        [self reOpnEye];
        dispatch_async(dispatch_get_main_queue(), ^{
              self.textLabel.text  =  @"请眨眼";
        });
        NSLog(@"777777777");
    }
}

#pragma mark --- 预备拍照
-(void)acrefucnOpen:(NSString *)key p:(CGPoint )p{
      if (self.arrKeyFunc.count !=  0) {
        if ([self.isKeyFunc objectForKey:self.arrKeyFunc[0]]  ==  0 && self.arrKeyFunc.count >= 1) {
            [self acrefucnnum:0 key:key p:p];
                takePhoto ++;
            if (takePhoto  ==  1200) {
                takePhoto  =  0;
            }
        }else if ([self.isKeyFunc objectForKey:self.arrKeyFunc[1]]  ==  0  && self.arrKeyFunc.count >= 2){
            [self acrefucnnum:1 key:key p:p];
            takePhoto ++;
            if (takePhoto  ==  1200) {
                takePhoto  =  0;
            }
        }else{
              takePhotoNumber ++;
            if (1200 > takePhotoNumber && takePhotoNumber > 0){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->imgView stopAnimating];
                [self animationGifWithName:@"oliveapp_normal"];
                     self.textLabel.text  =  @"请注视屏幕";
                });
            }else if ( takePhotoNumber  > 1500){
                [self didClickTakePhoto:YES];
            }
        }
    }
}

//代理之后判断数据先级3
#pragma mark --- 判断是否左旋
-(void)identifyYourFaceCrossleft:(NSString *)key p:(CGPoint )p{
    NSLog(@"identifyYourFaceCrossright%d",numcount);
    if ([key isEqualToString:@"left_eye_left_corner"]) {
        if (left_eye_left  ==  0) {
            left_eye_left  =  p.y;
        }else if (p.y - left_eye_left >=  150){
            left_eye_left  =  p.y;
            numcount ++;
        }else if (left_eye_left - p.y >=  150){
            left_eye_left  =  p.y;
            numcount ++;
        }
    }
    if ([key isEqualToString:@"right_eye_right_corner"]) {
        if (right_eye_right  ==  0) {
            right_eye_right  =  p.x;
        }else if (p.x - right_eye_right >=  150){
            right_eye_right  =  p.x;
            numcount ++;
        }else if (right_eye_right - p.x >=  150){
            right_eye_right  =  p.x;
            numcount ++;
        }
    }
    if (numcount >=  1) {
        [self delateNumber];
        isCrossleft  =  YES;
        numcount  =  0;
        [self.isKeyFunc setBool:isCrossleft forKey:@"Crossleft"];
    }
}
//代理之后判断数据～～～优先级3
#pragma mark --- 判断是否右旋
-(void)identifyYourFaceCrossright:(NSString *)key p:(CGPoint )p{
    NSLog(@"identifyYourFaceCrossleft%d",numcount);
    NSLog(@"p.x - left_eye_left%f",left_eye_left - p.x);
    if ([key isEqualToString:@"left_eye_left_corner"]) {
        if (left_eye_left  ==  0) {
            left_eye_left  =  p.x;
        }else if (p.x- left_eye_left >=  150){
            NSLog(@"1left_eye_left_corner");
            left_eye_left  =  p.x;
            numcount ++;
        }else if (left_eye_left -p.x >=  150){
             NSLog(@"2left_eye_left_corner");
            left_eye_left  =  p.x;
            numcount ++;
        }
    }
    if ([key isEqualToString:@"right_eye_right_corner"]) {
        if (right_eye_right  ==  0) {
            right_eye_right  =  p.y;
        }else if (p.y - right_eye_right >=  150){
            right_eye_right  =  p.y;
            numcount ++;
        }else if (right_eye_right - p.y >=  150){
            right_eye_right  =  p.y;
            numcount ++;
        }
    }
    if (numcount >=  1) {
        [self delateNumber];
        isCrossright  =  YES;
        numcount  =  0;
        [self.isKeyFunc setBool:isCrossright forKey:@"Crossright"];
    }
}
//代理之后判断数据～～～优先级3
#pragma mark --- 判断是否前后移动
-(void)identifyYourFaceAround:(CGFloat)around {
    if (foraround  ==  0) {
        foraround  =  around;
        
    }else if (around - foraround > 30){
        foraround  =  around;
        numcount ++;
    }else if (foraround - around > 30){
        foraround  =  around ;
        numcount ++;
    }
    if (numcount >=  1) {
        [self delateNumber];
        isAround  =  YES;
        numcount  =  0;
    [self.isKeyFunc setBool:isAround forKey:@"Faceround"];
        [self.isKeyFunc synchronize];
    }
}
//代理之后判断数据～～～优先级3
#pragma mark --- 判断是否张嘴
-(void)identifyYourFaceOpenMouth:(NSString *)key p:(CGPoint )p
{
    NSLog(@"+++++++++++++张嘴");
    dispatch_once(&mouthOnceToken, ^{
        [self playTipVoice:@"oliveapp_step_hint_mouthopen"];
        [self animationGifWithName:@"oliveapp_mouthopen"];
    });
//    [self tomAnimationWithName:@"mouth_0" count:2];
    
    if ([key isEqualToString:@"mouth_upper_lip_top"]) {
        upperY  =  p.y;
    }
    if ([key isEqualToString:@"mouth_lower_lip_bottom"]) {
        lowerY  =  p.y;
    }
    if ([key isEqualToString:@"mouth_left_corner"]) {
        leftX  =  p.x;
    }
    if ([key isEqualToString:@"mouth_right_corner"]) {
        rightX  =  p.x;
    }
    if (rightX && leftX && upperY && lowerY && isJudgeMouth !=  YES) {
        
        number ++;
        if (number  ==  1 || number  ==  300 || number  ==  600 || number  == 900) {
            mouthWidthF  =  rightX - leftX < 0 ? abs(rightX - leftX) : rightX - leftX;
            mouthHeightF  =  lowerY - upperY < 0 ? abs(lowerY - upperY) : lowerY - upperY;
            NSLog(@"%d,%d",mouthWidthF,mouthHeightF);
        }
        mouthWidth  =  rightX - leftX < 0 ? abs(rightX - leftX) : rightX - leftX;
        mouthHeight  =  lowerY - upperY < 0 ? abs(lowerY - upperY) : lowerY - upperY;
        NSLog(@"%d,%d",mouthWidth,mouthHeight);
        NSLog(@"张嘴前：width = %d，height = %d",mouthWidthF - mouthWidth,mouthHeight - mouthHeightF);
        if (mouthWidth && mouthWidthF) {
            //张嘴验证完毕
            if (mouthHeight - mouthHeightF >=  10 && mouthWidthF - mouthWidth >=  15) {
                isJudgeMouth  =  YES;
                [self.isKeyFunc setBool:isJudgeMouth forKey:@"FaceOpenMouth"];
              [self.isKeyFunc synchronize];
            }
        }
    }
}
//代理之后判断数据～～～优先级3
#pragma mark --- 判断是否持续摇头
-(void)identifyYourReFaceShakeHead:(NSString *)key p:(CGPoint )p
{
    dispatch_once(&shakeOnceToken, ^{
        [self playTipVoice:@"oliveapp_step_hint_headshake"];
        [self animationGifWithName:@"oliveapp_headshake"];
    });
//    [self tomAnimationWithName:@"shake0" count:4];
    [self FaceShakeHead:key p:p];
    //摇头验证完毕
    if (bigNumber - smallNumber > 60) {
        [self delateNumber];//清数据
        [self FaceShakeHead:key p:p];
            numcount ++;
        if (numcount >=  1) {
            isReShakeHead  =  YES;
            [self.isKeyFunc setBool:isReShakeHead forKey:@"ReFaceShakeHead"];
             [self.isKeyFunc synchronize];
            [self delateNumber];
            numcount  =  0;
        }
    }
}

-(void)FaceShakeHead:(NSString *)key p:(CGPoint )p{
    if ([key isEqualToString:@"mouth_middle"]) {
        if (bigNumber  ==  0 ) {
            bigNumber  =  p.x;
            smallNumber  =  p.x;
        }else if (p.x > bigNumber) {
            bigNumber  =  p.x;
        }else if (p.x < smallNumber) {
            smallNumber  =  p.x;
        }
    }
}

//代理之后判断数据～～～优先级3
#pragma mark --- 判断是否持续低头
-(void)identifyYourReFacedownHead:(NSString *)key p:(CGPoint )p
{
    dispatch_once(&headDownOnceToken, ^{
        [self playTipVoice:@"oliveapp_step_hint_headup"];
        [self animationGifWithName:@"oliveapp_headup"];
    });
//    [self tomAnimationWithName:@"down_0" count:2];
    [self ReFacedownHead:key p:p];
    if (nosetop -nose_top >40 && nosebottom - nose_bottom >40) {
            numcount ++;
        [self delateNumber];
        [self ReFacedownHead:key p:p];
        if (numcount >=  1) {
            isReDownlowHead  =  YES;
            [self.isKeyFunc setBool:isReDownlowHead forKey:@"ReFacedownHead"];
             [self.isKeyFunc synchronize];
            [self delateNumber];
            numcount  =  0;
   NSLog(@"+++++++++++++isReDownlowHead低头");
        }
    }
}

-(void)ReFacedownHead:(NSString *)key p:(CGPoint )p{
    if ([key isEqualToString:@"nose_bottom"]) {
        if (nosebottom  ==  0 ) {
            nosebottom  =  p.y;
            nose_bottom  =  p.y;
             NSLog(@"1nosebottom%d",nosebottom);
             NSLog(@"1nose_bottom%d",nose_bottom);
        }else if (p.y > nosebottom) {
            nosebottom  =  p.y;
             NSLog(@"2nosebottom%d",nosebottom);
        }
        if (nosebottom - nose_bottom > 60) {
            nosebottom  =  nose_bottom;
            nose_bottom  =  p.y;
             NSLog(@"3nosebottom%d",nosebottom);
        }
    }
    if ([key isEqualToString:@"nose_top"]) {
        if (nosetop  ==  0) {
            nosetop  =  p.y;
            nose_top  =  p.y;
             NSLog(@"1nosetop%d",nosetop);
             NSLog(@"1nose_top%d",nose_top);
        }else if (p.y > nosetop){
            nosetop  =  p.y;
             NSLog(@"2nosetop%d",nosetop);
        }
        if (nosetop - nose_top > 60 ) {
            nosetop  =  nose_top;
            nose_top  =  p.y;
        }
    }
}


//代理之后判断数据～～～优先级3
#pragma mark --- 判断是否持续抬头
-(void)identifyYourReFaceUpHead:(NSString *)key p:(CGPoint )p
{
    
    dispatch_once(&headupOnceToken, ^{
        [self playTipVoice:@"oliveapp_step_hint_headup"];
        [self animationGifWithName:@"oliveapp_headup"];
    });
//    [self tomAnimationWithName:@"up_0" count:2];
    [self ReFaceUpHead:key p:p];
    if (nosetop - nose_top < -20 && nosebottom - nose_bottom < -20) {
            numcount ++;
        [self delateNumber];
        [self ReFaceUpHead:key p:p];
        if (numcount >=  1) {
            isReUpHead  =  YES;
            [self.isKeyFunc setBool:isReUpHead forKey:@"ReFaceUpHead"];
             [self.isKeyFunc synchronize];
            [self delateNumber];
            numcount  =  0;
            NSLog(@"+++++++++++++isReUpHead抬头");
        }
    }
}

-(void)ReFaceUpHead:(NSString *)key p:(CGPoint )p{
    if ([key isEqualToString:@"nose_bottom"]) {
        if (nosebottom  ==  0 ) {
            nosebottom  =  p.y;
            nose_bottom  =  p.y;
             NSLog(@"1nosebottom%d",nosebottom);
             NSLog(@"1nose_bottom%d",nose_bottom);
        }else if (p.y < nosebottom) {
            nosebottom  =  p.y;
             NSLog(@"2nosebottom%d",nosebottom);
        }
        if (nosebottom - nose_bottom < -30) {
            nosebottom  =  nose_bottom;
            nose_bottom  =  p.y;
             NSLog(@"3nosebottom%d",nosebottom);
        }
    }
    if ([key isEqualToString:@"nose_top"]) {
        if (nosetop  ==  0) {
            nosetop  =  p.y;
            nose_top  =  p.y;
             NSLog(@"1nosetop%d",nosetop);
             NSLog(@"1nose_top%d",nose_top);
        }else if (p.y < nosetop){
            nosetop  =  p.y;
             NSLog(@"2nosetop%d",nosetop);
        }
        if (nosetop - nose_top < -30 ) {
            nosetop  =  nose_top;
            nose_top  =  p.y;
        }
    }
}

//代理之后判断数据～～～优先级3
-(void)reOpnEye{
    dispatch_once(&eyeOnceToken, ^{
        [self playTipVoice:@"oliveapp_step_hint_eyeclose"];
        [self animationGifWithName:@"oliveapp_eyeclose"];
    });
//    [self tomAnimationWithName:@"eye_0" count:2];
    isReOpnEye = YES;
    self.captureManager.isReOpnEye = isReOpnEye;
}

#pragma mark --- 拍照
-(void)didClickTakePhoto:(BOOL)isSound
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        AVCaptureConnection *myVideoConnection  =  nil;
        //从 AVCaptureStillImageOutput 中取得正确类型的 AVCaptureConnection
        for (AVCaptureConnection *connection in self->myStillImageOutput.connections) {
            for (AVCaptureInputPort *port in [connection inputPorts]) {
                if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                    myVideoConnection  =  connection;
                    break;
                }
            }
        }
        if (!isSound) {
            static SystemSoundID soundID  =  0; if (soundID  ==  0) {
                NSBundle* bundle   =    [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"JusiveIFlyFace" ofType:@"bundle"]];
                NSString *path  =    [bundle pathForResource:@"photoShutter2" ofType:@"caf"];
                NSURL *filePath  =  [NSURL fileURLWithPath:path isDirectory:NO];
                AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
              }
            AudioServicesPlaySystemSound(soundID);
        }
        //撷取影像（包含拍照音效）
        [self->myStillImageOutput captureStillImageAsynchronouslyFromConnection:myVideoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            //完成撷取时的处理程序(Block)
            if (imageDataSampleBuffer) {
                NSData *imageData  =  [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                //取得的静态影像
                UIImage *myImage  =  [[UIImage alloc] initWithData:imageData];
                NSData *imagePng = UIImagePNGRepresentation(myImage);
                [self.arrImage addObject:  [UIImage image:[[UIImage alloc] initWithData:imagePng] rotation: UIImageOrientationRight]];
                [self delateNumber];
                dispatch_async( dispatch_get_global_queue(0, 0), ^{
                    [self.previewLayer.session stopRunning];
                    if (self.arrImage.count == 0) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.faceDelegate sendFaceImageErrorWith:self];
                        });
                      }else{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.faceDelegate sendFaceImage:self.arrImage with:self];
                        });
                    }
                });
             }
        }];
    });
}

#pragma mark --- 清掉对应的数
-(void)delateNumber
{
    number  =  0;
    mouthWidthF  =  0;
    mouthHeightF  =  0;
    mouthWidth  =  0;
    mouthHeight  =  0;
    smallNumber  =  0;
    bigNumber  =  0;
    nosetop  =  0;
    nose_top  =  0;
    nosebottom  =  0;
    nose_bottom  = 0;
    foraround  =  0;
    left_eye_left  =  0;
    right_eye_right  =  0;
    imgView.animationImages  =  nil;
}
-(UIButton *)buttonWithTitle:(NSString *)title frame:(CGRect)frame action:(SEL)action AddView:(id)view
{
    UIButton *button  =  [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame  =  frame;
    button.backgroundColor  =  [UIColor lightGrayColor];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchDown];
    [view addSubview:button];
    return button;
}

#pragma mark --- UIImageView显示gif动画
- (void)animationGifWithName:(NSString *)name{
    NSBundle* bundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"JusiveIFlyFace" ofType:@"bundle"]];
    NSString *path = [bundle pathForResource:name ofType:@"gif"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    UIImage *image = [UIImage sd_animatedGIFWithData:data];
    imgView.image = image;
}

- (void)tomAnimationWithName:(NSString *)name count:(NSInteger)count
{
    // 如果正在动画，直接退出
    if ([imgView isAnimating]) return;
    // 动画图片的数组
    NSMutableArray *arrayM  =  [NSMutableArray array];
    // 添加动画播放的图片
    for (int i  =  0; i < count; i++) {
        // 图像名称
        NSString *imageName  =  [NSString stringWithFormat:@"%@%d", name, i];
        NSBundle* bundle   =    [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"JusiveIFlyFace" ofType:@"bundle"]];
        NSString *path  =    [bundle pathForResource:imageName ofType:@"png"];
        
        UIImage *image  =  [UIImage imageWithContentsOfFile:path];
        [arrayM addObject:image];
    }
    // 设置动画数组
    imgView.animationImages  =  arrayM;
    // 重复1次
    imgView.animationRepeatCount  =  100;
    // 动画时长
    imgView.animationDuration  =  imgView.animationImages.count * 0.75;
    // 开始动画
    [imgView startAnimating];
}
#pragma mark - 播放短效音频
- (void)playTipVoice:(NSString *)voiceName{
    //获取音频文件路径
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"JusiveIFlyFace" ofType:@"bundle"]];
    NSString *path = [bundle pathForResource:voiceName ofType:@"mp3"];
    // 本地音频文件URL
    NSURL *soundURL = [NSURL fileURLWithPath:path isDirectory:NO];
    SystemSoundID soundID;
    OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &soundID);
    // 加载音频
    if (error) {
      NSLog(@"error : %@", @(error));
      return;
    }
    AudioServicesPlaySystemSound(soundID);
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
//    销毁 SoundID
//    AudioServicesDisposeSystemSoundID(soundID);
}

-(void)dealloc
{
    self.captureManager  =  nil;
    [self.previewView removeGestureRecognizer:self.tapGesture];
    self.tapGesture  =  nil;
}

@end
