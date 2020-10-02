//
//  GLSLReader.h
//  demo
//
//  Created by 韩元旭 on 2020/10/2.
//

#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GLSLReader : NSObject
+ (GLuint)compileShaderWithName:(NSString *)name type:(GLenum)shaderType;
+ (GLuint)programWithShaderName:(NSString *)shaderName;
@end

NS_ASSUME_NONNULL_END
