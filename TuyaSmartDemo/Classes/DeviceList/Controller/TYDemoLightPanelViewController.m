//
//  TYDemoLightPanelViewController.m
//  TuyaSmartDemo
//
//  Created by XuChengcheng on 2020/12/2.
//

#import "TYDemoLightPanelViewController.h"
#import "TPDemoProgressUtils.h"
#import "TPDemoUtils.h"
#import "RSColorPickerView.h"
#import "TYLightColorUtils.h"
#import "UIColor+TYHex.h"
#import "TYFeitSliderView.h"
#import "UILabel+TYFactory.h"

NSString * const kFeitSwtichDpId = @"1";/* 控制 Feit 灯开关的 dp 点 */

NSString * const kFeitWhiteBrightDpId = @"2";/* 控制 Feit 单色灯亮度的 dp 点 */
NSString * const kFeitWhiteTempDpId = @"3";/* 控制 Feit 单色灯 temp 的 dp 点 */

NSString * const kFeitColorBrightDpId = @"3";/* 控制 Feit 彩灯亮度的 dp 点 */
NSString * const kFeitColorTypeDpId = @"2";/* 控制 Feit 灯类型的 dp 点 */
NSString * const kFeitColorTempDpId = @"4";/* 控制 Feit 彩灯 temp 的 dp 点 */
NSString * const kFeitColorDpId = @"5";/* 控制 Feit 灯色彩的 dp 点 */

NSString * const kFeitScene1DpId = @"7";/* scene_1 dp点 */
NSString * const kFeitScene2DpId = @"8";/* scene_2 dp点 */
NSString * const kFeitScene3DpId = @"9";/* scene_3 dp点 */
NSString * const kFeitScene4DpId = @"10";/* scene_4 dp点 */

typedef struct {float b, s, f;} BSFType;  //brightness satutation frequency

@interface TYDemoLightPanelViewController () <RSColorPickerViewDelegate, TYFeitSliderViewDelegate>
{
    HSVType _hsvValue;
    double _currentH;
}

@property (nonatomic, strong) UIButton        *powerButton;
@property (nonatomic, assign) BOOL            isOn;
@property (nonatomic, strong) RSColorPickerView *colorPicker;
@property (nonatomic, assign) NSInteger minValue;
@property (nonatomic, assign) NSInteger maxValue;
@property (nonatomic, assign) NSInteger tempMinValue;
@property (nonatomic, assign) NSInteger tempMaxValue;
@property (nonatomic, strong) TYFeitSliderView *saturationSliderView;
@property (nonatomic, strong) TYFeitSliderView *brightSliderView;
@property (nonatomic, strong) TYFeitSliderView *tempSliderView;
@property (nonatomic, strong) UISwitch         *switchButton;

@end

@implementation TYDemoLightPanelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initView];
    [self reloadData];
}

- (void)initView {
    self.topBarView.centerItem = self.centerTitleItem;
    self.topBarView.leftItem = self.leftBackItem;
    self.rightTitleItem.title = TYSDKDemoLocalizedString(@"action_more", @"");
    self.topBarView.rightItem = self.rightTitleItem;
    self.topBarView.bottomLineHidden = YES;
    [self.view addSubview:self.topBarView];
    // 开关
    [self.view addSubview:self.switchButton];
    UILabel *label = [UILabel ty_labelWithText:TYSDKDemoLocalizedString(@"ty_timer_switch", nil) font:[UIFont systemFontOfSize:14] textColor:TY_HexColor(0x6480B3)frame:CGRectMake(self.switchButton.left - 60, self.switchButton.top, 60, self.switchButton.height)];
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
    
    // 亮度
    [self.view addSubview:self.brightSliderView];
    // 冷暖
    [self.view addSubview:self.tempSliderView];
    
    // 彩光和饱和度
    [self.view addSubview:self.colorPicker];
    [self.view addSubview:self.saturationSliderView];
    
    self.view.backgroundColor = MAIN_BACKGROUND_COLOR;
    [self getMinAndMaxValue:kFeitColorBrightDpId];
    [self getTempMinAndMaxValue:kFeitColorTempDpId];
}

- (void)reloadData {
    
    NSDictionary *dps = self.device.deviceModel.dps;
    BOOL isSwitch = [[dps objectForKey:kFeitSwtichDpId] boolValue];
    [self.switchButton setOn:isSwitch];
    
    double brightnessValue = [self getBrightness:dps];
    [self.brightSliderView setSliderValue:brightnessValue];
    
    double tempValue = [self getTempValue:[[dps objectForKey:kFeitColorTempDpId] doubleValue]];
    [self.tempSliderView setSliderValue:tempValue];
    
    HSVType hsv = [self getHSVFromDpId:kFeitColorDpId];
    UIColor *color = [self getColorFromDpId:kFeitColorDpId];
    
    self.colorPicker.selectionColor = color;
    self.colorPicker.brightness = 1;
    self.colorPicker.opaque = YES;
    [self.saturationSliderView setSliderValue:hsv.s];
    
    
}

- (double)getTempValue:(double)temp {
    
    double tempValue = (temp - self.tempMinValue) / (self.tempMaxValue - self.tempMinValue);
    tempValue = MIN(MAX(0, tempValue), 1);
    
//    tempValue = 1 - tempValue;
    
    return tempValue;
}

- (double)getBrightness:(NSDictionary *)dps {
    
    double value = 0;
    
    if ([[dps objectForKey:kFeitColorTypeDpId] isEqualToString:@"colour"]) {
        
        HSVType hsv = [self getHSVFromDpId:kFeitColorDpId];
        value = hsv.v;
        
    } else {
         //   1+(x-25)/230*(100-1) 同首页百分比
        value = [[dps objectForKey:kFeitColorBrightDpId] tysdk_toDouble];
        value = (1 + (value - self.minValue) / (self.maxValue - self.minValue) * (100-1)) / 100.0;
        value = MIN(MAX(0, value), 1);
    }
    
    return value;
}

- (UISwitch *)switchButton {
    if (!_switchButton) {
        _switchButton = [[UISwitch alloc] initWithFrame:CGRectMake((APP_SCREEN_WIDTH - 51) / 2.0, APP_TOP_BAR_HEIGHT + 16, 51, 36)];
        [_switchButton addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _switchButton;
}

- (TYFeitSliderView *)brightSliderView {
    if (!_brightSliderView) {
        _brightSliderView = [[TYFeitSliderView alloc] initWithFrame:CGRectMake(40, self.switchButton.bottom, APP_CONTENT_WIDTH - 80, 44)];
        _brightSliderView.tipsLabel.text = TYSDKDemoLocalizedString(@"Bright", nil);
        _brightSliderView.delegate = self;
        _brightSliderView.tag = 1;
    }
    
    return _brightSliderView;
}

- (TYFeitSliderView *)tempSliderView {
    if (!_tempSliderView) {
        _tempSliderView = [[TYFeitSliderView alloc] initWithFrame:CGRectMake(40, self.brightSliderView.bottom + 16, APP_CONTENT_WIDTH - 80, 44)];
        _tempSliderView.tipsLabel.text = TYSDKDemoLocalizedString(@"Temperature", nil);
        _tempSliderView.delegate = self;
        _tempSliderView.tag = 2;
    }
    
    return _tempSliderView;
}

- (RSColorPickerView *)colorPicker {
    if (!_colorPicker) {
        _colorPicker = [[RSColorPickerView alloc] initWithFrame:CGRectMake((APP_SCREEN_WIDTH - 250)/2, self.tempSliderView.bottom + 16, 250, 250)];
        _colorPicker.delegate = self;
        _colorPicker.cropToCircle = YES;
        _colorPicker.showLoupe = NO;
    }
    return _colorPicker;
}

- (TYFeitSliderView *)saturationSliderView {
    if (!_saturationSliderView) {
        _saturationSliderView = [[TYFeitSliderView alloc] initWithFrame:CGRectMake(40, self.colorPicker.bottom + 16, APP_CONTENT_WIDTH - 80, 44)];
        _saturationSliderView.tipsLabel.text = TYSDKDemoLocalizedString(@"saturation", nil);
        _saturationSliderView.delegate = self;
        _saturationSliderView.tag = 3;
    }
    return _saturationSliderView;
}

- (void)switchAction:(UISwitch *)sender {
    // 开关操作
    WEAKSELF_AT
    [TPDemoProgressUtils showMessag:TYSDKDemoLocalizedString(@"loading", @"") toView:self.view];
    
    [self.device publishDps:@{kFeitSwtichDpId:@(sender.isOn)} success:^{
        [TPDemoProgressUtils hideHUDForView:weakSelf_AT.view animated:NO];
    } failure:^(NSError *error) {
        [TPDemoProgressUtils hideHUDForView:weakSelf_AT.view animated:NO];
        [TPDemoProgressUtils showError:error.localizedDescription];
    }];
}

//
//- (void)powerButtonClicked {
//
//    WEAKSELF_AT
//    [TPDemoProgressUtils showMessag:TYSDKDemoLocalizedString(@"loading", @"") toView:self.view];
//
//    NSDictionary *dps = @{@"1": _isOn ? @(NO): @(YES)};
//    [self.device publishDps:dps success:^{
//        [TPDemoProgressUtils hideHUDForView:weakSelf_AT.view animated:NO];
//        [weakSelf_AT reloadData];
//    } failure:^(NSError *error) {
//        [TPDemoProgressUtils hideHUDForView:weakSelf_AT.view animated:NO];
//        [TPDemoProgressUtils showError:error.localizedDescription];
//    }];
//}

#pragma mark - RSColorPickerViewDelegate
- (void)colorPickerDidChangeSelection:(RSColorPickerView *)colorPicker {

    NSDictionary *dps = self.device.deviceModel.dps;
    
    BOOL isSwitch = [[dps objectForKey:kFeitSwtichDpId] tysdk_toBool];
    
    if (!isSwitch) {
        return;
    }

    HSVType hsv = [self.class getHSVFromUIColor:colorPicker.selectionColor];
    
    _hsvValue.h = hsv.h;
    
    _currentH = hsv.h;
    
    if (_hsvValue.v == 0) {
        _hsvValue.v = 1;
    }

//    if (self.isFirstCreatGroupResult) {
//        _hsvValue.s = 1;
//    }

    int r, g, b;
    
    HSVToRGB(_hsvValue.h, _hsvValue.s, _hsvValue.v, &r, &g, &b);
    
    NSString *dpsString = [NSString stringWithFormat:@"%02x%02x%02x%@",
                           (unsigned int)r,
                           (unsigned int)g,
                           (unsigned int)b,
                           [self getHexStringFromHSV:_hsvValue]];
    NSDictionary *publishDps = @{
                                 kFeitColorDpId:dpsString,
                                 kFeitColorTypeDpId:@"colour",
                                 };
//    [self publishDps:publishDps success:^{
//
//        [TPNotification postNotificationName:kNotificationClearSelectType];
//        [TPNotification postNotificationName:kSHLightNeedRefreshNotification];
//
//    } failure:^(NSError *error) {
//
//    }];
    [self.device publishDps:publishDps success:^{
            
    } failure:^(NSError *error) {
        
    }];
}


#pragma mark - TYFeitSliderViewDelegate
- (void)didChangeSliderValue:(TYFeitSliderView *)slider value:(double)value {
    
    
}

#pragma mark - TuyaSmartDeviceDelegate

/// dp数据更新
- (void)device:(TuyaSmartDevice *)device dpsUpdate:(NSDictionary *)dps {
    [self reloadData];
}

/// 设备基本信息（例如名字，在线状态等）变化代理回调
- (void)deviceInfoUpdate:(TuyaSmartDevice *)device {
    
    // 设备名字变化刷新
    self.centerTitleItem.title = self.device.deviceModel.name;
    self.topBarView.centerItem = self.centerTitleItem;
    
    // 在线状态变化刷新
    [self updateOfflineView];
}


#pragma mark - #pragma mark - Color Light

- (UIColor *)getColorFromDpId:(NSString *)dpId {
    
    NSDictionary *dps = self.device.deviceModel.dps;
    
    NSString *res = [[dps objectForKey:dpId] tysdk_toString];
    
    UIColor *color;
    
    if (res.length >= 6) {
        color = [UIColor ty_colorWithHexString:[[dps objectForKey:dpId] substringToIndex:6]];
    }
    return color;
    
}

- (NSArray<UIColor *> *)getColorsFromDpId:(NSString *)dpId {
    NSDictionary *dps = self.device.deviceModel.dps;

    if ([[dps objectForKey:dpId] tysdk_toString].length < 14) {
        dps = [self defaultData];
    }
    
    NSString *res = [[dps objectForKey:dpId] tysdk_toString];
    
    UIColor *color;
    
    NSString *stringToConvert = [[dps objectForKey:dpId] substringFromIndex:8];
    
    NSMutableArray *stringArray = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *colorArray = [NSMutableArray arrayWithCapacity:0];
    
    NSString *colorString;
    for (int i = 0; i < stringToConvert.length/6; i ++) {
        colorString = [stringToConvert substringWithRange:NSMakeRange(i* 6, 6)];
        [stringArray addObject:colorString];
    }
    for (NSString *hexString in stringArray) {
        color = [UIColor ty_colorWithHexString:hexString];
        [colorArray addObject:color];
    }
    
    return colorArray;
    
}

- (NSDictionary *)defaultData{
 
    NSDictionary *defaultDps = @{
                                 @"7":@"ffff320100ff00",
                                 @"8":@"ffff50040000ffff0000ff0000ff0000ff0000ff0000",
                                 @"9":@"ffff3201ff0000",
                                 @"10":@"ffff050200fff24d00ff4d00ff4d00ffff0000ff0000",
                                 };
    
    return defaultDps;
}

- (HSVType)getHSVFromDpId:(NSString *)dpId {
    
    NSDictionary *dps = self.device.deviceModel.dps;
    
    NSString *res = [[dps objectForKey:dpId] tysdk_toString];
    
    if (res.length == 14) {
        
        NSString *stringToConvert = [[dps objectForKey:dpId] substringWithRange:NSMakeRange(6, 8)];
        
        NSString *cString = [[stringToConvert stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
        
        NSRange range;
        range.location = 0;
        range.length = 4;
        
        NSString *hString = [cString substringWithRange:range];
        
        range.location = 4;
        range.length = 2;
        NSString *sString = [cString substringWithRange:range];
        
        range.location = 6;
        range.length = 2;
        NSString *vString = [cString substringWithRange:range];
        
        unsigned int h, s ,v;
        
        [[NSScanner scannerWithString:hString] scanHexInt:&h];
        [[NSScanner scannerWithString:sString] scanHexInt:&s];
        [[NSScanner scannerWithString:vString] scanHexInt:&v];
        
        double sValue = (float) s / 255.0f;
        
        double vValue = (float) (v - 25)/ (255.0f - 25.f);
        
        HSVType hsv = {h,sValue,vValue};
        return hsv;
        
    } else {
        return [self.class getHSVFromUIColor:[self getColorFromDpId:dpId]];
    }
}

//从场景的dp中取值
- (BSFType)getBTFFromDpId:(NSString *)dpId {
    
    NSDictionary *dps = self.device.deviceModel.dps;

    if ([[dps objectForKey:dpId] tysdk_toString].length < 14) {
        dps = [self defaultData];
    }
    
    NSString *res = [[dps objectForKey:dpId] tysdk_toString];
    
    NSString *stringToConvert = [[dps objectForKey:dpId] substringWithRange:NSMakeRange(0, 6)];
    
    NSString *cString = [[stringToConvert stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    NSRange range;
    range.location = 0;
    range.length = 2;
    
    NSString *bString = [cString substringWithRange:range];
    
    range.location = 2;
    range.length = 2;
    NSString *tString = [cString substringWithRange:range];
    
    range.location = 4;
    range.length = 2;
    NSString *fString = [cString substringWithRange:range];
    
    unsigned int b, s ,f;
    
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    [[NSScanner scannerWithString:tString] scanHexInt:&s];
    [[NSScanner scannerWithString:fString] scanHexInt:&f];
    
    
    double bValue = (float) (b - self.minValue)/ (self.maxValue - self.minValue);
    
    double sValue = (float) (s / 255.0);
    
    double fValue = (float) (100 - ((f > 100)?100:f)) / (100.0 * 0.99) ;
    
    BSFType bsf = {bValue,sValue,fValue};
    return bsf;
    
}

+ (HSVType)getHSVFromUIColor:(UIColor *)color {
    
    CGFloat r, g, b, a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    
    double H,S,V;
    
    int ir = r * 255;
    int ig = g * 255;
    int ib = b * 255;
    
    RGBToHSV(ir, ig, ib, &H, &S, &V);
    
    HSVToRGB(H, S, V, &ir, &ig, &ib);
    
    HSVType res = {H, S, V};
    
    return res;
}

- (NSString *)getHexStringFromHSV:(HSVType)hsv {
    
    int h = (int)floorl(hsv.h);
    int s = (int)floorl(hsv.s * 255.0);
    int v = (int)floorl(hsv.v * (255 - 25) + 25);
    
    return [NSString stringWithFormat:@"%04lX%02lX%02lX", h, s, v];
}

- (NSString *)getHexStringFromBTF:(BSFType)bsf colors:(NSArray *)colors {

    int b = (int)floorl(bsf.b * (self.maxValue - self.minValue) + self.minValue);
    int s = (int)floorl(bsf.s * 255.0);
    int f = 100 - (int)floorl(bsf.f * 100.0 * 0.99);

    NSString *hexStringColor = @"";
    for (UIColor *color in colors) {
        UIColor *newColor;
        CGFloat hue, saturation, brightness, alpha;
        BOOL ok = [color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
        if (ok) {
            saturation = bsf.s;
            brightness = bsf.b;
            newColor = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
        }
        hexStringColor = [hexStringColor stringByAppendingString:[newColor hexStringFromColor]];
    }
    hexStringColor = [hexStringColor stringByReplacingOccurrencesOfString:@"#" withString:@""];

    return [NSString stringWithFormat:@"%02lX%02lX%02lX%02X%@", b, s, f, colors.count, hexStringColor];

}


- (int)round:(CGFloat)percent {
    if (percent <= 0) {
        return 0;
    }
    CGFloat tempPercent = percent;
    int result = (int)(tempPercent + 0.5);
    return result;
}

- (void)getMinAndMaxValue:(NSString *)dpId {
    
    for (TuyaSmartSchemaModel *model in self.device.deviceModel.schemaArray) {
        if ([model.dpId isEqualToString:dpId]) {
            
            self.minValue = (int)model.property.min;
            self.maxValue = (int)model.property.max;
            
            break;
        }
    }
}

- (void)getTempMinAndMaxValue:(NSString *)dpId {
    
    for (TuyaSmartSchemaModel *model in self.device.deviceModel.schemaArray) {
        if ([model.dpId isEqualToString:dpId]) {
            
            self.tempMinValue = (int)model.property.min;
            self.tempMaxValue = (int)model.property.max;
            break;
        }
    }
}


@end