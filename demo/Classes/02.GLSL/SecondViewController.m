//
//  SecondViewController.m
//  demo
//
//  Created by 韩元旭 on 2020/10/2.
//

#import "SecondViewController.h"
#import <GLKit/GLKit.h>

typedef struct {
    GLKVector3 positionCoord;
    GLKVector2 textureCoord;
} SenceVertex;

@interface SecondViewController ()

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, assign) SenceVertex *vertices;

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:self.context];
    
    // 顶点数据
    self.vertices = malloc(sizeof(SenceVertex) * 4);
    self.vertices[0] = (SenceVertex){{-1, 1, 0}, {0, 1}};   // 左上角
    self.vertices[1] = (SenceVertex){{-1, -1, 0}, {0, 0}};  // 左下角
    self.vertices[2] = (SenceVertex){{1, 1, 0}, {1, 1}};    // 右上角
    self.vertices[3] = (SenceVertex){{1, -1, 0}, {1, 0}};   // 右下角
    
    // 渲染层绑定
    CAEAGLLayer *layer = [[CAEAGLLayer alloc] init];
    layer.frame = CGRectMake(0, 200, self.view.frame.size.width, self.view.frame.size.width);
    layer.contentsScale = [UIScreen mainScreen].scale;
    [self.view.layer addSublayer:layer];
    [self bindRenderLayer:layer];
    
    // 加载纹理
    NSString *imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"test.jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    GLuint textureId = [self createTextureWithImage:image];
    
    // 设置 ViewPort
    GLint backingWidth;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    GLint backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    glViewport(0, 0, backingWidth, backingHeight);
    
    // 链接 Shader
    GLuint program = [self programWithShaderName:@"second"];
    glUseProgram(program);
    
    // 获取参数位置
    GLuint positionSlot = glGetAttribLocation(program, "Position");
    GLuint textureSlot = glGetUniformLocation(program, "Texture");
    GLuint textureCoordsSlot = glGetAttribLocation(program, "TextureCoords");
    
    // 传入纹理
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureId);
    glUniform1i(textureSlot, 0); //0和GL_TEXTURE0对应
    
    // 顶点缓存
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    GLsizeiptr bufferSizeBytes = sizeof(SenceVertex) * 4;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_STATIC_DRAW);
    
    // 设置顶点数据
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, positionCoord));
    
    // 设置纹理数据
    glEnableVertexAttribArray(textureCoordsSlot);
    glVertexAttribPointer(textureCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, textureCoord));
    
    // 开始绘制
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // 展现
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
    
    // 删除顶点缓存
    glDeleteBuffers(1, &vertexBuffer);
    vertexBuffer = 0;
}

- (void)dealloc {
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    if (_vertices) {
        free(_vertices);
        _vertices = nil;
    }
}

- (void)bindRenderLayer:(CALayer<EAGLDrawable> *)layer {
    GLuint renderBuffer;    // 渲染缓存
    GLuint frameBuffer;     // 帧缓存
    
    // 绑定渲染缓存要输出的 Layer
    glGenRenderbuffers(1, &renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    
    // 将渲染缓存绑定到帧缓存
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer);
    
}

- (GLuint)createTextureWithImage:(UIImage *)image {
    // 获取 CGImage
    CGImageRef cgImageRef = [image CGImage];
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
    CGRect rect = CGRectMake(0, 0, width, height);
    
    // 绘制图片并且反转坐标
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc(width * height * 4);
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.f, -1.f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, cgImageRef);
    
    // 生成纹理
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    // 纹理映射成像素
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    // 解绑
    glBindTexture(GL_TEXTURE_2D, 0);
    
    // free
    CGContextRelease(context);
    free(imageData);
    
    return textureID;
}

- (GLuint)compileShaderWithName:(NSString *)name type:(GLenum)shaderType {
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

- (GLuint)programWithShaderName:(NSString *)shaderName {
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

@end
