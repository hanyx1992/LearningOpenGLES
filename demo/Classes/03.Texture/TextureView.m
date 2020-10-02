//
//  TextureView.m
//  demo
//
//  Created by 韩元旭 on 2020/10/2.
//

#import "TextureView.h"
#import "VertexAttribArrayBuffer.h"
#import "GLSLReader.h"

typedef struct {
    GLKVector3 positionCoord;
    GLKVector2 textureCoord;
} SenceVertex;

static NSInteger const kVerticesCount = 8;

@interface TextureView () <GLKViewDelegate>

@property (nonatomic, assign) SenceVertex *vertices;
@property (nonatomic, strong) GLKBaseEffect *baseEffect;

@property (nonatomic, strong) VertexAttribArrayBuffer *buffer;

@property (nonatomic, assign) BOOL hasChange;
@property (nonatomic, assign) CGSize imageSize;
@property (nonatomic, assign) CGFloat textureWidthPercent;
@property (nonatomic, assign) CGFloat defaultHeightPercent;
@property (nonatomic, assign) CGFloat currentStartY;
@property (nonatomic, assign) CGFloat currentEndY;
@property (nonatomic, assign) CGFloat currentNewHeight;

@property (nonatomic, assign) GLuint tmpTexture;
@property (nonatomic, assign) GLuint tmpFrameBuffer;
@end

@implementation TextureView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc {
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    if (_vertices) {
        free(_vertices);
        _vertices = nil;
    }
    if (_tmpFrameBuffer) {
        glDeleteFramebuffers(1, &_tmpFrameBuffer);
        _tmpFrameBuffer = 0;
    }
    if (_tmpTexture) {
        glDeleteTextures(1, &_tmpTexture);
        _tmpTexture = 0;
    }
}

- (void)commonInit {
    self.vertices = malloc(sizeof(SenceVertex) * kVerticesCount);

    self.backgroundColor = [UIColor whiteColor];
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    self.delegate = self;
    [EAGLContext setCurrentContext:self.context];
    glClearColor(0, 0, 0, 0);
    
    self.defaultHeightPercent = 0.7;
    self.buffer = [[VertexAttribArrayBuffer alloc] initWithAttribStribe:sizeof(SenceVertex)
                                                       numberOfVertices:kVerticesCount
                                                                   data:self.vertices
                                                                  usage:GL_STATIC_DRAW];
}

#pragma mark - Public

- (void)setImage:(UIImage *)image {
    self.hasChange = NO;
    
    NSDictionary *options = @{ GLKTextureLoaderOriginBottomLeft : @(YES) };
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:image.CGImage options:options error:nil];
    
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.texture2d0.name = textureInfo.name;
//    self.baseEffect.texture2d0.target = textureInfo.target;
    
    self.imageSize = image.size;
    CGFloat ratio = (self.imageSize.height / self.imageSize.width) * (self.bounds.size.width / self.bounds.size.height);
    CGFloat textureHeightPercent = MIN(ratio, self.defaultHeightPercent);
    self.textureWidthPercent = textureHeightPercent / ratio;
    
    [self calcTextureCoordsWithSize:self.imageSize startY:0 endY:0 newHeight:0];

    [self.buffer updateDataWithAttribStribe:sizeof(SenceVertex) numberOfVertices:kVerticesCount data:self.vertices usage:GL_STATIC_DRAW];
    
    [self display];
}

- (void)stretchingFromStartY:(CGFloat)startY toEndY:(CGFloat)endY withNewHeight:(CGFloat)newHeight {
    self.hasChange = YES;
    [self calcTextureCoordsWithSize:self.imageSize startY:startY endY:endY newHeight:newHeight];
    [self.buffer updateDataWithAttribStribe:sizeof(SenceVertex) numberOfVertices:kVerticesCount data:self.vertices usage:GL_STATIC_DRAW];
    [self display];
}

#pragma mark - Calculate Layout

- (void)calcTextureCoordsWithSize:(CGSize)size startY:(CGFloat)startY endY:(CGFloat)endY newHeight:(CGFloat)newHeight {
    CGFloat ratio = (size.height / size.width) * (self.bounds.size.width / self.bounds.size.height);
    CGFloat textureWidth = self.textureWidthPercent;
    CGFloat textureHeight = textureWidth * ratio;
    
    // 拉伸量
    CGFloat delta = (newHeight - (endY - startY)) * textureHeight;
    
    // 最大值
    if (textureHeight + delta >= 1) {
        delta = 1 - textureHeight;
        newHeight = delta / textureHeight + (endY - startY);
    }
    
    // 纹理的顶点
    GLKVector3 pointLT = {-textureWidth, textureHeight + delta, 0};     // 左上角
    GLKVector3 pointRT = {textureWidth, textureHeight + delta, 0};      // 右上角
    GLKVector3 pointLB = {-textureWidth, -textureHeight - delta, 0};    // 左下角
    GLKVector3 pointRB = {textureWidth, -textureHeight - delta, 0};     // 右下角
    
    // 中间区域
    CGFloat startYCoord = MIN(textureHeight - 2 * textureHeight * startY, textureHeight);
    CGFloat endYCoord = MAX(textureHeight - 2 * textureHeight * endY, -textureHeight);
    GLKVector3 centerPointLT = {-textureWidth, startYCoord + delta, 0};  // 左上角
    GLKVector3 centerPointRT = {textureWidth, startYCoord + delta, 0};   // 右上角
    GLKVector3 centerPointLB = {-textureWidth, endYCoord - delta, 0};    // 左下角
    GLKVector3 centerPointRB = {textureWidth, endYCoord - delta, 0};     // 右下角
    
    // top
    self.vertices[0] = (SenceVertex){pointLT, {0, 1}};                  // 左上角
    self.vertices[1] = (SenceVertex){pointRT, {1, 1}};                  // 右上角
    
    // center
    self.vertices[2] = (SenceVertex){centerPointLT, {0, 1 - startY}};   // 左上角
    self.vertices[3] = (SenceVertex){centerPointRT, {1, 1 - startY}};   // 右上角
    self.vertices[4] = (SenceVertex){centerPointLB, {0, 1 - endY}};     // 左上角
    self.vertices[5] = (SenceVertex){centerPointRB, {1, 1 - endY}};     // 右上角
    
    // bottom
    self.vertices[6] = (SenceVertex){pointLB, {0, 0}};                  // 左下角
    self.vertices[7] = (SenceVertex){pointRB, {1, 0}};                  // 右下角
    
    //
    self.currentStartY = startY;
    self.currentEndY = endY;
    self.currentNewHeight = newHeight;
}

#pragma mark - Update

- (void)updateTextureIfNeeded {
    if (!self.hasChange) {
        return;
    }
    
    [self resetTextureOriginWidth:self.imageSize.width
                     originHeight:self.imageSize.height
                           startY:self.currentStartY
                             endY:self.currentEndY
                        newHeight:self.currentNewHeight];
    
    if (self.baseEffect.texture2d0.name != 0) {
        GLuint textureName = self.baseEffect.texture2d0.name;
        glDeleteTextures(1, &textureName);
    }
    self.baseEffect.texture2d0.name = self.tmpTexture;
    self.imageSize = [self currentImageSize];
    self.hasChange = NO;
    
    [self calcTextureCoordsWithSize:self.imageSize startY:0 endY:0 newHeight:0];
    [self.buffer updateDataWithAttribStribe:sizeof(SenceVertex) numberOfVertices:kVerticesCount data:self.vertices usage:GL_STATIC_DRAW];
    [self display];
}

- (void)resetTextureOriginWidth:(CGFloat)width
                   originHeight:(CGFloat)height
                         startY:(CGFloat)startY
                           endY:(CGFloat)endY
                      newHeight:(CGFloat)newHeight {
    // 新尺寸
    GLsizei textureWidth = width;
    GLsizei textureHeight = height * (newHeight - (endY - startY)) + height;
        
    // 缩放大小
    CGFloat heightScale = textureHeight / height;
    
    // 新尺寸下重新计算顶点坐标
    CGFloat newStartY = startY / heightScale;
    CGFloat newEndY = (startY + newHeight) / heightScale;
    
    SenceVertex *vertices = malloc(sizeof(SenceVertex) * kVerticesCount);
    // top
    vertices[0] = (SenceVertex){{-1, 1, 0}, {0, 1}};    // 左上角
    vertices[1] = (SenceVertex){{1, 1, 0}, {1, 1}};     // 右上角
    
    // center
    vertices[2] = (SenceVertex){{-1, -2 * newStartY + 1, 0}, {0, 1 - startY}};      // 左上角
    vertices[3] = (SenceVertex){{1, -2 * newStartY + 1, 0}, {1, 1 - startY}};       // 右上角
    vertices[4] = (SenceVertex){{-1, -2 * newEndY + 1, 0}, {0, 1 - endY}};          // 左上角
    vertices[5] = (SenceVertex){{1, -2 * newEndY + 1, 0}, {1, 1 - endY}};           // 右上角
    
    // bottom
    vertices[6] = (SenceVertex){{-1, -1, 0}, {0, 0}};   // 左下角
    vertices[7] = (SenceVertex){{1, -1, 0}, {1, 0}};   // 右下角
    
    // [渲染到纹理]
    GLuint frameBuffer;
    GLuint texture;
    
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, textureWidth, textureHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
    
    //
    glViewport(0, 0, textureWidth, textureHeight);
    
    //
    GLuint program = [GLSLReader programWithShaderName:@"second"];
    glUseProgram(program);
    
    //
    GLuint positionSlot = glGetAttribLocation(program, "Position");
    GLuint textureSlot = glGetUniformLocation(program, "Texture");
    GLuint textureCoordsSlot = glGetAttribLocation(program, "TextureCoords");
    
    //
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.baseEffect.texture2d0.name);
    glUniform1i(textureSlot, 0);
    
    VertexAttribArrayBuffer *buffer = [[VertexAttribArrayBuffer alloc] initWithAttribStribe:sizeof(SenceVertex)
                                                                           numberOfVertices:kVerticesCount
                                                                                       data:vertices
                                                                                      usage:GL_STATIC_DRAW];
    
    [buffer prepareToDrawWithAttrib:positionSlot
                   numberOfVertices:3
                       attribOffset:offsetof(SenceVertex, positionCoord)
                       shouldEnable:YES];
    
    [buffer prepareToDrawWithAttrib:textureCoordsSlot
                   numberOfVertices:2
                       attribOffset:offsetof(SenceVertex, textureCoord)
                       shouldEnable:YES];
    
    [buffer drawArrayWithMode:GL_TRIANGLE_STRIP startVertexIndex:0 numberOfVertices:kVerticesCount];
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    free(vertices);
    
    self.tmpTexture = texture;
    self.tmpFrameBuffer = frameBuffer;
}

#pragma mark - Export

- (UIImage *)buildImage {
    [self resetTextureOriginWidth:self.imageSize.width
                     originHeight:self.imageSize.height
                           startY:self.currentStartY
                             endY:self.currentEndY
                        newHeight:self.currentNewHeight];
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.tmpFrameBuffer);
    CGSize imageSize = [self currentImageSize];
    UIImage *image = [self imageFromTextureSize:imageSize];
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    return image;
}

- (UIImage *)imageFromTextureSize:(CGSize)size {
    int byteSize = size.width * size.height * 4;
    GLubyte *buffer = malloc(byteSize);
    glReadPixels(0, 0, size.width, size.height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, byteSize, NULL);
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * size.width;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef imageRef = CGImageCreate(size.width, size.height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpace, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), imageRef);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    free(buffer);
    return image;
}


#pragma mark - Private

- (CGSize)currentImageSize {
    CGFloat height = self.imageSize.height * ((self.currentNewHeight - (self.currentEndY - self.currentStartY)) + 1);
    return CGSizeMake(self.imageSize.width, height);
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.baseEffect prepareToDraw];
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.buffer prepareToDrawWithAttrib:GLKVertexAttribPosition
                        numberOfVertices:3
                            attribOffset:offsetof(SenceVertex, positionCoord) shouldEnable:YES];
    
    [self.buffer prepareToDrawWithAttrib:GLKVertexAttribTexCoord0
                        numberOfVertices:2
                            attribOffset:offsetof(SenceVertex, textureCoord) shouldEnable:YES];
    
    [self.buffer drawArrayWithMode:GL_TRIANGLE_STRIP startVertexIndex:0 numberOfVertices:kVerticesCount];
}

#pragma mark - Setters

- (void)setTmpFrameBuffer:(GLuint)tmpFrameBuffer {
    if (_tmpFrameBuffer) {
        glDeleteFramebuffers(1, &_tmpFrameBuffer);
    }
    _tmpFrameBuffer = tmpFrameBuffer;
}

@end
