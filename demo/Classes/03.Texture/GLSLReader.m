//
//  GLSLReader.m
//  demo
//
//  Created by 韩元旭 on 2020/10/2.
//

#import "GLSLReader.h"

@implementation GLSLReader

+ (GLuint)programWithShaderName:(NSString *)shaderName {
    // 编译两个着色器
    GLuint vertexShader = [self compileShaderWithName:shaderName type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShaderWithName:shaderName type:GL_FRAGMENT_SHADER];
    
    // 挂载至 program
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
    // 链接 program
    glLinkProgram(program);
    
    // 检查链接结果
    GLint linkSuccess;
    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar message[256];
        glGetProgramInfoLog(program, sizeof(message), 0, &message[0]);
        NSString *msg = [NSString stringWithUTF8String:message];
        NSAssert(NO, msg);
    }
    
    return program;
}

+ (GLuint)compileShaderWithName:(NSString *)name type:(GLenum)shaderType {
    NSString *fileType = shaderType == GL_VERTEX_SHADER ? @"vsh" : @"fsh";
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:name ofType:fileType];
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:nil];
    NSAssert(shaderString.length, @"could not load shader file: %@", name);
    
    // 创建 shader 对象
    GLuint shader = glCreateShader(shaderType);
    
    // 获取 shader 内容
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLenght = (int)shaderString.length;
    glShaderSource(shader, 1, &shaderStringUTF8, &shaderStringLenght);
    
    // 编译 shader
    glCompileShader(shader);
    
    // 查询编译结果
    GLint compileSuccess;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar message[256];
        glGetShaderInfoLog(shader, sizeof(message), 0, &message[0]);
        NSString *msg = [NSString stringWithUTF8String:message];
        NSAssert(NO, msg);
    }
    
    return shader;
}

@end
