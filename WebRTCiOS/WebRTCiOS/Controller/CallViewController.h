//
//  CallViewController.h
//  WebRTCiOS
//
//  Created by zhangguangpeng on 2020/5/15.
//  Copyright © 2020 zhangguangpeng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CallViewController : UIViewController

- (instancetype) initAddr:(NSString*) addr withRoom:(NSString*) room;

@end

NS_ASSUME_NONNULL_END
