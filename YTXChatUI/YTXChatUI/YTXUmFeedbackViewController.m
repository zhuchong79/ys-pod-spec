//
//  YTXUmFeedbackViewController.m
//  EFSMobile
//
//  Created by zhanglu on 15/11/24.
//  Copyright © 2015年 Elephants Financial Service. All rights reserved.
//

#import "YTXUmFeedbackViewController.h"

#import <TSMessagesNW/TSMessage.h>
#import "YTXChatView.h"
#import <YTXUtilCategory/NSDate+YTXUtilCategory.h>
#import <UMengFeedback/UMFeedback.h>
#import <MBProgressHUD/MBProgressHUD.h>


@interface YTXUmFeedbackViewController () <YTXChatViewDelegate>

@property (nonatomic, strong) NSMutableArray *feedbacks;
@property (nonatomic, strong) NSMutableArray *chatArray;
@property (nonatomic, strong) UMFeedback *feedbackApi;
@property (nonatomic, strong) YTXChatView *chatView;

@end

static CGFloat kYTXFeedbackNavAndStatusHeight = 64;

@implementation YTXUmFeedbackViewController

+ (void)setUMengAppKey:(NSString *)appKey
{
    [UMFeedback setAppkey:appKey];
}

NSInteger const kTIME_AMONE_10_YTXFeedback = 600*1000;

- (NSMutableArray *)feedbacks
{
    if(_feedbacks == nil) {
        _feedbacks = [NSMutableArray array];
    }
    return _feedbacks;
}

- (NSMutableArray *)chatArray
{
    if (_chatArray == nil) {
        _chatArray = [NSMutableArray array];
    }
    return _chatArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.chatView = [YTXChatView createFromNib];
    self.chatView.placeholder = @"您有什么建议或者意见?";
    self.chatView.maxLimitTextLength = self.maxLimitTextLength;
    self.chatView.translatesAutoresizingMaskIntoConstraints = YES;
    if (self.navigationController.navigationBarHidden) {
        self.chatView.frame = CGRectMake(0, kYTXFeedbackNavAndStatusHeight, self.view.bounds.size.width, self.view.bounds.size.height - kYTXFeedbackNavAndStatusHeight);
    } else {
        self.chatView.frame = self.view.frame;
        UIEdgeInsets insets = UIEdgeInsetsMake(kYTXFeedbackNavAndStatusHeight, 0, 0, 0);
        self.chatView.tableView.contentInset = insets;
        self.chatView.tableView.scrollIndicatorInsets = insets;
    }
    
    self.chatView.delegate = self;
    [self.view addSubview:self.chatView];
    self.feedbackApi = [UMFeedback sharedInstance];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    __weak YTXUmFeedbackViewController *weak_self = self;
    [self.feedbackApi get:^(NSError *error) {
        __strong YTXUmFeedbackViewController *self = weak_self;
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        if(error == nil) {
            self.feedbacks = [self.feedbackApi.topicAndReplies mutableCopy];
            [self updateUmFeedBackType];
            self.chatView.chatModels = [self.chatArray copy];
        }
    }];
    
}

- (void)setMaxLimitTextLength:(NSUInteger)maxLimitTextLength
{
    _maxLimitTextLength = maxLimitTextLength;
    self.chatView.maxLimitTextLength = maxLimitTextLength;
}

#pragma mark - YTXChatViewDelegate
- (void)chatViewSendMessage:(NSString *)content
{
    if (content.length == 0) {
        return [TSMessage showNotificationInViewController:self
                                                     title:@"内容不能为空"
                                                  subtitle:nil
                                                     image:nil
                                                      type:TSMessageNotificationTypeError
                                                  duration:2.f
                                                  callback:nil
                                               buttonTitle:nil
                                            buttonCallback:nil
                                                atPosition:TSMessageNotificationPositionTop
                                      canBeDismissedByUser:YES];
    }
    if (content.length > 2000) {
        return [TSMessage showNotificationInViewController:self
                                                     title:@"内容长度不应超过2000个字符"
                                                  subtitle:nil
                                                     image:nil
                                                      type:TSMessageNotificationTypeError
                                                  duration:2.f
                                                  callback:nil
                                               buttonTitle:nil
                                            buttonCallback:nil
                                                atPosition:TSMessageNotificationPositionTop
                                      canBeDismissedByUser:YES];
    }
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    __weak YTXUmFeedbackViewController *weak_self = self;
    [self.feedbackApi post:@{@"content": content} completion:^(NSError *error) {
        __strong YTXUmFeedbackViewController *self = weak_self;
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        if(error) {
            return [TSMessage showNotificationInViewController:self
                                                         title:@"发送失败"
                                                      subtitle:nil
                                                         image:nil
                                                          type:TSMessageNotificationTypeError
                                                      duration:2.f
                                                      callback:nil
                                                   buttonTitle:nil
                                                buttonCallback:nil
                                                    atPosition:TSMessageNotificationPositionTop
                                          canBeDismissedByUser:YES];
        }
        [self.feedbacks addObject:@{
                                    @"content": content,
                                    @"created_at": @([[NSDate date] timeIntervalSince1970] * 1000),
                                    }];
        [self updateUmFeedBackType];
        self.chatView.chatModels = [self.chatArray copy];
    }];
}

- (void)chatViewResendMessage:(YTXChatOutgoingTextModel *)model
{
    
}

- (void)chatViewTextLengthOverMaxLimit
{
    [TSMessage showNotificationInViewController:self
                                          title:[NSString stringWithFormat:@"最多输入%d个字",self.maxLimitTextLength != 0 ? : 140]
                                       subtitle:nil
                                          image:nil
                                           type:TSMessageNotificationTypeError
                                       duration:2.f
                                       callback:nil
                                    buttonTitle:nil
                                 buttonCallback:nil
                                     atPosition:TSMessageNotificationPositionTop
                           canBeDismissedByUser:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// 10 分钟打一个时间戳
- (void)updateUmFeedBackType
{
    [self.chatArray removeAllObjects];
    NSInteger beforeTime = 0;
    for (NSInteger i = 0; i< self.feedbacks.count; i++) {
        BOOL time = [self.feedbacks[i][@"created_at"] integerValue] - beforeTime >= kTIME_AMONE_10_YTXFeedback;
        if ([self.feedbacks[i][@"type"] isEqualToString:@"dev_reply"]) {
            if (time) {
                YTXChatTimeModel *model = [[YTXChatTimeModel alloc] init];
                model.time = [self updateDateShow:self.feedbacks[i][@"created_at"]];
                [self.chatArray addObject:model];
                YTXChatIncomingTextModel *textModel = [[YTXChatIncomingTextModel alloc] init];
                textModel.content = self.feedbacks[i][@"content"];
                [self.chatArray addObject:textModel];
            } else {
                YTXChatIncomingTextModel *textModel = [[YTXChatIncomingTextModel alloc] init];
                textModel.content = self.feedbacks[i][@"content"];
                [self.chatArray addObject:textModel];
            }
        } else {
            if (time) {
                YTXChatTimeModel *model = [[YTXChatTimeModel alloc] init];
                model.time = [self updateDateShow:self.feedbacks[i][@"created_at"]];
                [self.chatArray addObject:model];
                YTXChatOutgoingTextModel *textModel = [[YTXChatOutgoingTextModel alloc] init];
                textModel.content = self.feedbacks[i][@"content"];
                [self.chatArray addObject:textModel];
            } else {
                YTXChatOutgoingTextModel *textModel = [[YTXChatOutgoingTextModel alloc] init];
                textModel.content = self.feedbacks[i][@"content"];
                [self.chatArray addObject:textModel];
            }
        }
        beforeTime = [self.feedbacks[i][@"created_at"] integerValue];
    }
}

- (NSString *)updateDateShow:(NSNumber *)dateStr
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[dateStr doubleValue] / 1000];
    NSString *string = [date stringWithFormat:kNSDateyMdHmFormatYTXFeedBack];
    NSString *today = [[[NSDate alloc] init] stringWithFormat:@"yyyy'年'MM'月'dd'日'"];
    NSString *toyear = [[[NSDate alloc] init] stringWithFormat:@"yyyy"];
    
    if ([string rangeOfString:toyear].length <= 0) {
        return [date stringWithFormat:kNSDateyMdHmFormatYTXFeedBack];
    }
    if ([string rangeOfString:today].length <= 0) {
        return [date stringWithFormat:kNSDateMdHmFormatYTXFeedBack];
    }
    return [date stringWithFormat:kNSDateHmFormatYTXFeedBack];
}

- (IBAction)backAction:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
