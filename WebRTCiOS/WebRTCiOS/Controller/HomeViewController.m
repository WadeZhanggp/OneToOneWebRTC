//
//  HomeViewController.m
//  WebRTCiOS
//
//  Created by zhangguangpeng on 2020/5/15.
//  Copyright © 2020 zhangguangpeng. All rights reserved.
//

#import "HomeViewController.h"
#import <Masonry/Masonry.h>
#import "ReactiveObjC/ReactiveObjC.h"
#import "CallViewController.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define THEMECOLOR  Color(55, 83, 182, 1)
#define Color(r, g, b, a)    [UIColor colorWithRed:r / 255.f green:g / 255.f blue:b / 255.f alpha:a]

@interface HomeViewController ()

@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextField *roomIdTextField;
@property (nonatomic, strong) UIImageView *roomImage;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UIButton *joinButton;
@property (nonatomic, strong) UIButton *settingButton;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationController.navigationBar.hidden = YES;
    [self.view addSubview:self.bgImageView];
    [self.bgImageView addSubview:self.titleLabel];
    [self.view addSubview:self.roomIdTextField];
    [self.view addSubview:self.roomImage];
    [self.view addSubview:self.lineView];
    [self.view addSubview:self.joinButton];
    [self.view addSubview:self.settingButton];
    
    [self initLayout];
    [self initFunction];
    
}

#pragma mark initfunction
- (void)initFunction {
    @weakify(self)
    [[self.joinButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
         @strongify(self)
        CallViewController *callController = [[CallViewController alloc] init];
        [self.navigationController pushViewController:callController animated:YES];
    }];
    
    [[self.settingButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
         @strongify(self)
        
    }];
}


#pragma mark initlayout
- (void)initLayout {
    [self.bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).with.offset(0);
        make.top.equalTo(self.view).with.offset(0);
        make.right.equalTo(self.view).with.offset(0);
        make.height.equalTo(@(0.3 * SCREEN_HEIGHT));
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.bgImageView);
        make.centerY.equalTo(self.bgImageView);
    }];
    
    [self.roomIdTextField mas_makeConstraints:^(MASConstraintMaker *make) {
  
        make.top.equalTo(self.bgImageView.mas_bottom).offset(80);
        make.height.equalTo(@35);
        make.left.equalTo(self.view).with.offset(70);
        make.right.equalTo(self.view).with.offset(-70);
    }];
    
    [self.roomImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.roomIdTextField);
        make.right.equalTo(self.roomIdTextField.mas_left).offset(-6);
    }];
    
    [self.lineView mas_makeConstraints:^(MASConstraintMaker *make) {
    
        make.top.equalTo(self.roomIdTextField.mas_bottom).offset(0);
        make.height.equalTo(@0.5);
        make.left.equalTo(self.view).with.offset(40);
        make.right.equalTo(self.view).with.offset(-40);
    }];
    
    [self.settingButton mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.bottom.equalTo(self.view.mas_bottom).offset(-40);
        make.height.equalTo(@50);
        make.left.equalTo(self.view).with.offset(40);
        make.right.equalTo(self.view).with.offset(-40);
    }];
    
    [self.joinButton mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.bottom.equalTo(self.settingButton.mas_top).offset(-20);
        make.height.equalTo(@50);
        make.left.equalTo(self.view).with.offset(40);
        make.right.equalTo(self.view).with.offset(-40);
    }];
    
    self.joinButton.layer.masksToBounds = YES;
    self.joinButton.layer.cornerRadius = 25;
    
    self.settingButton.layer.masksToBounds = YES;
    self.settingButton.layer.cornerRadius = 25;
    self.settingButton.layer.borderWidth = 1;
    
}


#pragma mark setter and getter
- (UIImageView *)bgImageView {
    if (!_bgImageView) {
        _bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgHome"]];
    }
    return _bgImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"RTC ROOM";
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:35 weight:1];
    }
    return _titleLabel;
}

- (UITextField *)roomIdTextField {
    if (!_roomIdTextField) {
        _roomIdTextField = [[UITextField alloc] init];
        _roomIdTextField.placeholder = @"Please enter Room Id";
    }
    return _roomIdTextField;
}

- (UIImageView *)roomImage {
    if (!_roomImage) {
        _roomImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"imgRoom"]];
    }
    return _roomImage;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = [UIColor grayColor];
    }
    return _lineView;
}

- (UIButton *)joinButton {
    if (!_joinButton) {
        _joinButton = [[UIButton alloc] init];
        _joinButton.font =  [UIFont systemFontOfSize:18];
        [_joinButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _joinButton.backgroundColor = THEMECOLOR;
        [_joinButton setTitle:@"Join" forState:UIControlStateNormal];
    }
    return _joinButton;
}

- (UIButton *)settingButton {
    if (!_settingButton) {
        _settingButton = [[UIButton alloc] init];
        _settingButton.layer.borderColor = THEMECOLOR.CGColor;
        [_settingButton setTitleColor:THEMECOLOR forState:UIControlStateNormal];
        _settingButton.font =  [UIFont systemFontOfSize:18];
        _settingButton.backgroundColor = [UIColor whiteColor];
        [_settingButton setTitle:@"Setting" forState:UIControlStateNormal];
    }
    return _settingButton;
}




@end
