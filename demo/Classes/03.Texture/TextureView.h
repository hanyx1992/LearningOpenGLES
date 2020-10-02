//
//  TextureView.h
//  demo
//
//  Created by 韩元旭 on 2020/10/2.
//

#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TextureView : GLKView

- (void)setImage:(UIImage *)image;

- (void)stretchingFromStartY:(CGFloat)startY toEndY:(CGFloat)endY withNewHeight:(CGFloat)newHeight;

- (void)updateTextureIfNeeded;

- (UIImage *)buildImage;

@end

NS_ASSUME_NONNULL_END
