//
//  FilterViewController.m
//  demo
//
//  Created by 韩元旭 on 2020/10/3.
//

#import "FilterViewController.h"
#import <GLKit/GLKit.h>
#import "GLSLReader.h"
#import "TextureLoader.h"

typedef struct {
    GLKVector3 positionCoord;
    GLKVector2 textureCoord;
} SenceVertex;

@interface FilterViewController ()

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, assign) SenceVertex *vertices;

@property (nonatomic, assign) GLuint program;
@property (nonatomic, assign) GLuint textureId;
@property (nonatomic, assign) GLuint vertexBuffer;

@property (nonatomic, strong) CADisplayLink *timer;
@property (nonatomic, assign) NSTimeInterval startTimeInterval;

@end

@implementation FilterViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self commonInit];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self startFilterAnimation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopFilterAnimationIfNeeded];
}

- (void)dealloc {
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    if (_vertexBuffer) {
        glDeleteBuffers(1, &_vertexBuffer);
        _vertexBuffer = 0;
    }
    
    if (_vertices) {
        free(_vertices);
        _vertices = nil;
    }
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

#pragma mark - Common Init

- (void)commonInit {
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:self.context];
    
    // 顶点数据
    [self setupVertexs];
    
    // 渲染层绑定
    CAEAGLLayer *layer = [self buildRenderLayer];
    [self.view.layer addSublayer:layer];
    [self bindRenderLayer:layer];
    
    // 加载纹理
    [self setupTexture];
    
    // 设置 ViewPort
    [self setupViewPort];
    
    // 顶点缓存
    [self setupVertexBuffer];
    
    // 链接 Shader
    [self setupShaderProgramNamed:@"default"];
}

- (CAEAGLLayer *)buildRenderLayer {
    CAEAGLLayer *layer = [[CAEAGLLayer alloc] init];
    layer.frame = CGRectMake(0, 200, self.view.frame.size.width, self.view.frame.size.width);
    layer.contentsScale = [UIScreen mainScreen].scale;
    return layer;
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

// 顶点数据
- (void)setupVertexs {
    self.vertices = malloc(sizeof(SenceVertex) * 4);
    self.vertices[0] = (SenceVertex){{-1, 1, 0}, {0, 1}};   // 左上角
    self.vertices[1] = (SenceVertex){{-1, -1, 0}, {0, 0}};  // 左下角
    self.vertices[2] = (SenceVertex){{1, 1, 0}, {1, 1}};    // 右上角
    self.vertices[3] = (SenceVertex){{1, -1, 0}, {1, 0}};   // 右下角
}

// 加载纹理
- (void)setupTexture {
    NSString *imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"test.jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    GLuint textureId = [TextureLoader createTextureWithImage:image];
    self.textureId = textureId;
}

// 设置 ViewPort
- (void)setupViewPort {
    GLint backingWidth;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    GLint backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    glViewport(0, 0, backingWidth, backingHeight);
}

// 顶点缓存
- (void)setupVertexBuffer {
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    GLsizeiptr bufferSizeBytes = sizeof(SenceVertex) * 4;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_STATIC_DRAW);
    self.vertexBuffer = vertexBuffer;
}

#pragma mark - Timer

- (void)startFilterAnimation {
    [self stopFilterAnimationIfNeeded];
    
    self.timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleTimeAction)];
    [self.timer addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopFilterAnimationIfNeeded {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    self.startTimeInterval = 0;
}

- (void)handleTimeAction {
    if (self.startTimeInterval == 0) {
        self.startTimeInterval = self.timer.timestamp;
    }
    
    glUseProgram(self.program);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBuffer);
    
    // 传入时间
    CGFloat currentTime = self.timer.timestamp - self.startTimeInterval;
    GLuint time = glGetUniformLocation(self.program, "Time");
    glUniform1f(time, currentTime);
    
    // 清除画布
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(1, 1, 1, 1);
    
    // 重绘制
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - Programs

- (void)setupShaderProgramNamed:(NSString *)name {
    // 链接 Shader
    GLuint program = [GLSLReader programWithShaderName:name];
    glUseProgram(program);
    self.program = program;
    
    // 获取参数位置
    GLuint positionSlot = glGetAttribLocation(program, "Position");
    GLuint textureSlot = glGetUniformLocation(program, "Texture");
    GLuint textureCoordsSlot = glGetAttribLocation(program, "TextureCoords");
    
    // 传入纹理
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureId);
    glUniform1i(textureSlot, 0); //0和GL_TEXTURE0对应
    
    // 设置顶点数据
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, positionCoord));
    
    // 设置纹理数据
    glEnableVertexAttribArray(textureCoordsSlot);
    glVertexAttribPointer(textureCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, textureCoord));
}

#pragma mark - Actions

- (IBAction)handleButtonActions:(UIButton *)sender {
    static NSArray *names;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        names = @[@"default", @"scale", @"soul", @"shake", @"blink",
                  @"glitch", @"vertigo", @"default", @"default", @"default"];
    });
    
    if (sender.tag >= names.count) {
        return;
    }
    
    [self setupShaderProgramNamed:names[sender.tag]];
}


@end

