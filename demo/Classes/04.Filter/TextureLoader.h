//
//  GLTextureLoader.h
//  demo
//
//  Created by 韩元旭 on 2020/10/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TextureLoader : NSObject

+ (GLuint)createTextureWithImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
