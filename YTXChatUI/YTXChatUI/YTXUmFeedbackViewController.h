//
//  YTXUmFeedbackViewController.h
//  EFSMobile
//
//  Created by zhanglu on 15/11/24.
//  Copyright © 2015年 Elephants Financial Service. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  当日显示：MM:SS，例如：09：08
 *  当日之前显示：MM月DD日 MM:SS，例如：09月09日 09：09
 *  非本年显示：YYYY年MM月DD日MM:SS，例如：2014年09月09日09：09
 */
static NSString * kNSDateHmFormatYTXFeedBack = @"HH':'mm";
static NSString * kNSDateMdHmFormatYTXFeedBack = @"MM'月'dd'日 'HH':'mm";
static NSString * kNSDateyMdHmFormatYTXFeedBack = @"yyyy'年'MM'月'dd'日 'HH':'mm";

@interface YTXUmFeedbackViewController : UIViewController

/** 设定输入框最大字符数，默认为140*/
@property (nonatomic, assign) NSUInteger maxLimitTextLength;

+ (void)setUMengAppKey:(NSString *)appKey;

@end
