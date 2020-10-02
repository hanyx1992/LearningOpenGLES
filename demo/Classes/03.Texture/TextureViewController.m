//
//  TextureViewController.m
//  demo
//
//  Created by 韩元旭 on 2020/10/2.
//

#import "TextureViewController.h"
#import "TextureView.h"
#import <Photos/Photos.h>

@interface TextureViewController ()

@property (nonatomic, strong) TextureView *textureView;

@property (nonatomic, strong) CALayer *selectionLayer;

@property (weak, nonatomic) IBOutlet UISlider *slider0;
@property (weak, nonatomic) IBOutlet UISlider *slider1;
@property (weak, nonatomic) IBOutlet UISlider *slider2;

@end

@implementation TextureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupTextureView];
    [self setupSelectionLayer];
    [self layoutSelectionLayer];
}

- (void)setupTextureView {
    self.textureView = [[TextureView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.height - 300)];
    [self.view addSubview:self.textureView];
    
    NSString *imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"joker.jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    [self.textureView setImage:image];
}

- (void)setupSelectionLayer {
    self.selectionLayer = [CALayer layer];
    self.selectionLayer.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.17].CGColor;
    [self.view.layer addSublayer:self.selectionLayer];
}

- (void)layoutSelectionLayer {
    CGFloat y = CGRectGetMinY(self.textureView.frame) + CGRectGetHeight(self.textureView.frame) * self.slider0.value;
    CGFloat h = (self.slider1.value - self.slider0.value) * CGRectGetHeight(self.textureView.frame);
    self.selectionLayer.frame = CGRectMake(0, y, CGRectGetWidth(self.view.frame), h);
}

- (IBAction)handleSliderValueChanged:(UISlider *)sender {
    if (sender == self.slider2) {
        CGFloat height = (self.slider1.value - self.slider0.value) * (0.5 + self.slider2.value);
        [self.textureView stretchingFromStartY:self.slider0.value toEndY:self.slider1.value withNewHeight:height];
        return;
    }
    
    [self.textureView updateTextureIfNeeded];
    self.slider2.value = 0.5;
    
    self.slider0.value = MIN(self.slider0.value, self.slider1.value);
    self.slider1.value = MAX(self.slider0.value, self.slider1.value);
    [self layoutSelectionLayer];
}

- (IBAction)handleSaveAction:(UIBarButtonItem *)sender {
    UIImage *image = [self.textureView buildImage];
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImage:image];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        NSLog(@"saved: %@", success ? @"success" : @"failed");
    }];
}


@end
