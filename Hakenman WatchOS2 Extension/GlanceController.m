//
//  GlanceController.m
//  Hakenman WatchKit Extension
//
//  Created by lee jaeeun on 2015/09/15.
//  Copyright (c) 2015年 kjcode. All rights reserved.
//

#import "GlanceController.h"
#import <CoreGraphics/CoreGraphics.h>
#import "NSDate+Helper.h"
#import "WatchUtil.h"
#import "UIColor+Helper.h"
#import "NSUserDefaults+Setting.h"
#import "HKMConnectivityManager.h"

#define SET_DOT_GRAPH_CELL(obj, no, sz, col)    \
    NSMutableAttributedString *txt##no = [[NSMutableAttributedString alloc] initWithString:@"■"]; \
    [txt##no addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:sz] range:NSMakeRange(0, txt##no.length)]; \
    [txt##no addAttribute:NSForegroundColorAttributeName value:col range:NSMakeRange(0, txt##no.length)]; \
    [obj setAttributedText:txt##no];

@interface GlanceController()

@property (nonatomic, weak) IBOutlet WKInterfaceImage *iconImage;
@property (nonatomic, weak) IBOutlet WKInterfaceLabel *titleLabel;

@property (nonatomic, weak) IBOutlet WKInterfaceLabel *monthlyWorkTimeTitleLabel;
@property (nonatomic, weak) IBOutlet WKInterfaceLabel *monthlyWorkTimeLabel;

@property (nonatomic, weak) IBOutlet WKInterfaceLabel *workDayTitleLabel;
@property (nonatomic, weak) IBOutlet WKInterfaceLabel *workDayLabel;

@property (nonatomic, weak) IBOutlet WKInterfaceImage *graphImage;

//watchOS1.0のため
@property (nonatomic, weak) IBOutlet WKInterfaceGroup *dotGraphGroup;

//@property (nonatomic, strong) IBOutletCollection(WKInterfaceLabel) NSArray *dotCell; できない。。。
@property (nonatomic, strong) IBOutlet WKInterfaceLabel *dotCell_1;
@property (nonatomic, strong) IBOutlet WKInterfaceLabel *dotCell_2;
@property (nonatomic, strong) IBOutlet WKInterfaceLabel *dotCell_3;
@property (nonatomic, strong) IBOutlet WKInterfaceLabel *dotCell_4;
@property (nonatomic, strong) IBOutlet WKInterfaceLabel *dotCell_5;
@property (nonatomic, strong) IBOutlet WKInterfaceLabel *dotCell_6;
@property (nonatomic, strong) IBOutlet WKInterfaceLabel *dotCell_7;

//@property (nonatomic, strong) NSString *remainTimeString;    //출근시간까지 남은시간

#if 0
@property (nonatomic, assign) NSTimer *loadTimer;
#endif

@end


@implementation GlanceController

#pragma setter

#if 0
- (void)setLoadTimer:(NSTimer *)newTimer {
    [_loadTimer invalidate];
    _loadTimer = newTimer;
}
#endif

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
//    self.remainTimeString = @"- ";
    [self.monthlyWorkTimeTitleLabel setText:LOCALIZE(@"Watch_Glance_Time_Title")];
    [self.workDayTitleLabel setText:LOCALIZE(@"Watch_Glance_Day_Title")];
    
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    [[HKMConnectivityManager sharedInstance] sessionConnect];
    
    [self loadScreenData];
    
    //最初は直接に実行する
//    [self updateRemainTime];
    
    //그래프가 깜박거리고 그러지지 않아서 타이머 삭제
#if 0
    //出勤時間チェック開始
    [self startLoadTimer];
#endif
    
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];

#if 0
    self.loadTimer = nil;
#endif
    
}

#if 0
#pragma mark - timer
- (void)startLoadTimer {

    if (_loadTimer != nil) {
        return;
    }
    
    self.loadTimer = [NSTimer scheduledTimerWithTimeInterval:10.f
                                                      target:self
                                                    selector:@selector(updateRemainTime)
                                                    userInfo:nil
                                                     repeats:YES];
}
#endif

#pragma mark - private methods
//- (void)updateRemainTime {
//    
//    //今日の日付から
//    NSDate *current_time = [NSDate date];
//    NSInteger calc_minute = 0;
//        
//    //出勤時間までの時間を計算
//    NSArray *timeArray = [[NSUserDefaults workStartTimeForWatch] componentsSeparatedByString:@":"];
//    NSDate *workStartTime = [current_time getTimeOfMonth:[timeArray[0] intValue]
//                                                  mimute:[timeArray[1] intValue]];
//    
//    NSTimeInterval t = [current_time timeIntervalSinceDate:workStartTime];
//    calc_minute = (int)(t / 60);
//    
//    NSLog(@"calc_minute:%ld",(long)calc_minute);
//    
//    //表示対象外
//    if (calc_minute < -120 || calc_minute > 0) {
//        self.remainTimeString = @"- ";
//        return;
//    }
//    
//    //休日の場合
//    if ([current_time getWeekday] == weekSatDay || [current_time getWeekday] == weekSunday) {
//        self.remainTimeString = @"- ";
//        return;
//    }
//    
//    self.remainTimeString = [NSString stringWithFormat:@"%d", (int)calc_minute*-1];
//    
//    [self loadScreenData];
//}

- (void)loadScreenData {
    
    NSDate *dt = [NSDate date];
    NSString *yyyymm = [NSString stringWithFormat:@"%d%02d", [dt getYear], [dt getMonth]];
    NSString *work_time_unit = LOCALIZE(@"Watch_Glance_Time_Unit");
    
    HKMConnectivityManager *mgr = [HKMConnectivityManager sharedInstance];
    
    //TEST
    //yyyymm = @"201607";
    [mgr sendMessageYear:[yyyymm substringWithRange:NSMakeRange(0, 4)]
                   month:[yyyymm substringWithRange:NSMakeRange(4, 2)]
            replyHandler:^(NSDictionary *results) {
                
                float display_total_time = 0;
                
                NSArray *items = results[@"data"];
                
                for (NSDictionary *tm in items) {
                    
                    NSDate *startTimeFromCore = [NSDate convDate2String:tm[@"start_time"]];
                    NSDate *endTimeFromCore = [NSDate convDate2String:tm[@"end_time"]];
                    
                    float workTimeFromCore = [WatchUtil getWorkTime:startTimeFromCore endTime:endTimeFromCore] - [tm[@"rest_time"] floatValue];
                    
                    if (tm[@"start_time"] == nil || [tm[@"start_time"] isEqualToString:@""] == YES
                        || tm[@"end_time"] == nil || [tm[@"end_time"] isEqualToString:@""] == YES) {
                        continue;
                    }
                    
                    if ([tm[@"workday_flag"] boolValue] == NO) {
                        workTimeFromCore = 0.f;
                    }
                    
                    display_total_time = display_total_time + workTimeFromCore;
                }
                
                NSString *total_work_time = [NSString stringWithFormat:@"%d", (int)display_total_time];
                
                
                NSMutableAttributedString *attrTimeString = [[NSMutableAttributedString alloc] initWithString:
                                                             [NSString stringWithFormat:@"%@%@", total_work_time, work_time_unit]];
                
                [attrTimeString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:20.f]
                                       range:NSMakeRange(0, total_work_time.length)];
                
                [attrTimeString addAttribute:NSForegroundColorAttributeName
                                       value:[UIColor whiteColor]
                                       range:NSMakeRange(0, total_work_time.length)];
                
                
                [attrTimeString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:10.f]
                                       range:NSMakeRange(total_work_time.length, work_time_unit.length)];
                
                [attrTimeString addAttribute:NSForegroundColorAttributeName
                                       value:[UIColor whiteColor]
                                       range:NSMakeRange(total_work_time.length, work_time_unit.length)];
                
                [_monthlyWorkTimeLabel setAttributedText:attrTimeString];
                
            }];
    
    
    
    [mgr sendMessageWorkDayYear:[yyyymm substringWithRange:NSMakeRange(0, 4)]
                          month:[yyyymm substringWithRange:NSMakeRange(4, 2)]
                   replyHandler:^(NSDictionary *results) {
                
                       NSNumber *workDayCount = results[@"data"];
                       
                       NSString *work_day_unit = LOCALIZE(@"Watch_Glance_Day_Unit");
                       NSString *work_day_count = [NSString stringWithFormat:@"%ld", (long)[workDayCount integerValue]];
                
                       NSMutableAttributedString *attrMinuteString = [[NSMutableAttributedString alloc] initWithString:
                                                                      [NSString stringWithFormat:@"%@%@", work_day_count, work_day_unit]];
                
                       [attrMinuteString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:20.f]
                                         range:NSMakeRange(0, work_day_count.length)];
                
                       [attrMinuteString addAttribute:NSForegroundColorAttributeName
                                                value:[UIColor whiteColor]
                                                range:NSMakeRange(0, work_day_count.length)];
                
                
                       [attrMinuteString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:10.f]
                                                range:NSMakeRange(work_day_count.length, work_day_unit.length)];
                       
                       [attrMinuteString addAttribute:NSForegroundColorAttributeName
                                                value:[UIColor whiteColor]
                                                range:NSMakeRange(work_day_count.length, work_day_unit.length)];
                
                [_workDayLabel setAttributedText:attrMinuteString];
                
            }];
    
#if 1
    //그래프표시. 버전이 2.0이상
    if ([WatchUtil wathcOSVersion] >= 200) {
        [_graphImage setHidden:NO];
        [_dotGraphGroup setHidden:YES];
        [self drawGraphView:CGSizeMake(130.f, 50.f)];
    }else {
        //ラベル表示
        [_graphImage setHidden:YES];
        [_dotGraphGroup setHidden:NO];
        [self drawDotGraphView];
    }
#endif
    
}

#pragma mark - dotGraphGroup
- (void)drawDotGraphView {
    
    [_dotGraphGroup setBackgroundColor:[[UIColor HKMBlueColor] colorWithAlphaComponent:0.4f]];
    
    //initialize
    NSMutableArray *dotCells = [NSMutableArray new];
    [dotCells addObject:_dotCell_1];
    [dotCells addObject:_dotCell_2];
    [dotCells addObject:_dotCell_3];
    [dotCells addObject:_dotCell_4];
    [dotCells addObject:_dotCell_5];
    [dotCells addObject:_dotCell_6];
    [dotCells addObject:_dotCell_7];
    
    HKMConnectivityManager *mgr = [HKMConnectivityManager sharedInstance];
    
    [mgr sendMessageGraphDate:[[NSDate date] yyyyMMddHHmmssString] replyHandler:^(NSDictionary *results) {
        NSArray *weekTimeCards = results[@"data"];
        
        //최대값 구함.
        float max_worktime = 8.f;  //default
        NSMutableArray *graph_data = [NSMutableArray new];
        
        for (NSDictionary *card in weekTimeCards) {
            NSTimeInterval t = [[NSDate convDate2String:card[@"end_time"]]
                                 timeIntervalSinceDate:[NSDate convDate2String:card[@"start_time"]]];
            
            float duration = (float)t - [card[@"rest_time"] floatValue];
            float work_time = (duration / (60*60)) - [card[@"rest_time"] floatValue];
            
            if (max_worktime < work_time) {
                max_worktime = work_time;
            }
            
            [graph_data addObject:@(work_time)];
        }
        
        
        //라벨그래프? 그리기
        for (int c=0;c<dotCells.count;c++) {
            
            WKInterfaceLabel *lbl = dotCells[c];
            [lbl setHidden:NO];
            
            if (c > graph_data.count -1) {
                [lbl setHidden:YES];
            }
        }
        
        for (int no=0;no<graph_data.count;no++) {
            float val = [graph_data[no] floatValue];
            
            SET_DOT_GRAPH_CELL(dotCells[no], no, 10.f+ val, [[UIColor whiteColor] colorWithAlphaComponent:0.5f]);
        }
        
    }];
    
}

#pragma mark - draw methods
- (void)drawGraphView:(CGSize)size {
    
    //http://d.hatena.ne.jp/shu223/20150714/1436875676
    
    HKMConnectivityManager *mgr = [HKMConnectivityManager sharedInstance];
    
    NSDate *today = [NSDate date];
    [mgr sendMessageGraphDate:[today yyyyMMddHHmmssString] replyHandler:^(NSDictionary *results) {
        
        // Create a graphics context
        //fix size.
        float g_width = size.width * 2.f;
        float g_height = size.height * 2.f;
        
        float margin = 16.f;
        
        CGSize retina_size = CGSizeMake(g_width, g_height);
        UIGraphicsBeginImageContext(retina_size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        //배경칠하기
        CGContextBeginPath(context);
        CGContextSetFillColorWithColor(context, [[UIColor HKMBlueColor] colorWithAlphaComponent:0.4f].CGColor);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, g_width , g_height) cornerRadius:10.f];
        [path fill];
        CGContextFillPath(context);
        
        //배경선 그리기 가로줄 4개
        for (int b_line=0; b_line<4; b_line++) {
            
            float line_y = g_height/(4+1)*(b_line+1);
            NSValue *start_pt = [NSValue valueWithCGPoint:CGPointMake(0 + margin, line_y)];
            NSValue *end_pt = [NSValue valueWithCGPoint:CGPointMake(g_width - margin, line_y)];
            
            [self drawline:context lineWidth:0.5f
                     color:[[UIColor whiteColor] colorWithAlphaComponent:0.2f]
                    points:@[start_pt, end_pt]];
        }
        
        
        NSArray *weekTimeCards = results[@"data"];
        
        //최대값 구함.
        float max_worktime = 8.f;  //default
        for (NSDictionary *card in weekTimeCards) {
            NSTimeInterval t = [[NSDate convDate2String:card[@"end_time"]]
                                timeIntervalSinceDate:[NSDate convDate2String:card[@"start_time"]]];
            
            float duration = (float)t - [card[@"rest_time"] floatValue];
            float work_time = (duration / (60*60)) - [card[@"rest_time"] floatValue];
            
            if (max_worktime < work_time) {
                max_worktime = work_time;
            }
        }
        
        //데이터 그래프 그리기
        NSMutableArray *data_points = [NSMutableArray new];
        int data_count = 0;
        CGPoint max_point = CGPointZero;
        
        for (NSDictionary *card in weekTimeCards) {
            NSTimeInterval t = [[NSDate convDate2String:card[@"end_time"]]
                                timeIntervalSinceDate:[NSDate convDate2String:card[@"start_time"]]];
            
            float duration = (float)t - [card[@"rest_time"] floatValue];
            float work_time = (duration / (60*60)) - [card[@"rest_time"] floatValue];
            
            //좌표로 변환
            float data_x = (((g_width - margin*2.f)/weekTimeCards.count) * data_count) + margin;
            float data_y = ((g_height - margin*2.f) - ((g_height - margin*2.f)*work_time)/max_worktime) + margin;
            [data_points addObject:[NSValue valueWithCGPoint:CGPointMake(data_x, data_y)]];
            
            data_count++;
            
            if (max_worktime == work_time) {
                //max label point
                max_point = CGPointMake(data_x, data_y);
            }
        }
        
        [self drawline:context lineWidth:2.f color:[UIColor whiteColor] points:data_points];
        
        //circle
        for (NSValue *val in data_points) {
            
            //drawCircle
            CGPoint pt = [val CGPointValue];
            [self drawCircle:context size:8.f point:pt color:[UIColor whiteColor]];
        }
        
        //text
        if (max_point.x > 0 && max_point.y > 0) {
            
            NSString *t = [NSString stringWithFormat:@"%.2f", max_worktime];
            UIColor *color = [UIColor whiteColor];
            UIColor *bcolor = [UIColor clearColor];
            NSDictionary *textAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:12.f],
                                             NSBackgroundColorAttributeName:bcolor,
                                             NSForegroundColorAttributeName:color};
            
            NSStringDrawingContext *drawingContext = [[NSStringDrawingContext alloc] init];
            drawingContext.minimumScaleFactor = 0.5; // Half the font size
            
            [t drawWithRect:CGRectMake(max_point.x, max_point.y - 16.f, g_width, g_height)
                    options:NSStringDrawingUsesLineFragmentOrigin
                 attributes:textAttributes
                    context:drawingContext];
            
        }
        
        // Convert to UIImage
        CGImageRef cgimage = CGBitmapContextCreateImage(context);
        UIImage *uiimage = [UIImage imageWithCGImage:cgimage];
        
        // End the graphics context
        UIGraphicsEndImageContext();
        
        [_graphImage setImage:uiimage];
        
        
    }];
    
}

- (void)drawline:(CGContextRef)ctx lineWidth:(float)lineWidth color:(UIColor *)color points:(NSArray *)points {
    
    CGContextBeginPath(ctx);
    
    for (int i=0;i<points.count;i++) {
        NSValue *val = points[i];
        CGPoint pt = [val CGPointValue];
        
        CGContextSetStrokeColorWithColor(ctx, color.CGColor);
        CGContextSetLineWidth(ctx, lineWidth);
        
        if (i==0) {
            //start point
            CGContextMoveToPoint(ctx, pt.x, pt.y);
            
        }else {
            CGContextAddLineToPoint(ctx, pt.x, pt.y);
        }
    }
    
    CGContextStrokePath(ctx);
}

- (void)drawCircle:(CGContextRef)ctx size:(float)size point:(CGPoint)pt color:(UIColor *)color {
    
    CGContextBeginPath(ctx);
    
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    UIBezierPath *aPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(pt.x-size/2.f, pt.y-size/2.f, size, size)];
    [aPath fill];
    
    CGContextFillPath(ctx);
    
}

@end



