//
//  test.h
//  FFmpegiOS
//
//  Created by zhangguangpeng on 2020/5/25.
//  Copyright © 2020 zhangguangpeng. All rights reserved.
//

#ifndef test_h
#define test_h

#include <stdio.h>
#include "libavutil/avutil.h"
#include "libavdevice/avdevice.h"
#include "libavformat/avformat.h"
#include "libavcodec/avcodec.h"
#include "libswresample/swresample.h"
#include "x264.h"

void set_status(int status);
void rec_video(void);

#endif /* testc_h */
