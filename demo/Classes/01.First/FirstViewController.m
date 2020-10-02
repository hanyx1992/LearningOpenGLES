//
//  FirstViewController.m
//  demo
//
//  Created by 韩元旭 on 2020/10/2.
//

#import "FirstViewController.h"
#import <GLKit/GLKit.h>

typedef struct {
    GLKVector3 positionCoord;
    GLKVector2 textureCoord;
} SenceVertex;

@interface FirstViewController () <GLKViewDelegate>

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) GLKView *glView;
@property (nonatomic, strong) GLKBaseEffect *baseEffect;

@property (nonatomic, assign) SenceVertex *vertices;

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    CGRect frame = CGRectMake(0, 200, self.view.frame.size.width, self.view.frame.size.width);
    self.glView = [[GLKView alloc] initWithFrame:frame context:self.context];
    self.glView.backgroundColor = [UIColor clearColor];
    self.glView.delegate = self;
    
    [self.view addSubview:self.glView];
    
    [EAGLContext setCurrentContext:self.context];
    
    NSString *imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"test.jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    
    NSDictionary *options = @{ GLKTextureLoaderOriginBottomLeft : @(YES) };
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:[image CGImage] options:options error:nil];
    
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.texture2d0.name = textureInfo.name;
    self.baseEffect.texture2d0.target = textureInfo.target;
    
    self.vertices = malloc(sizeof(SenceVertex) * 4);
    self.vertices[0] = (SenceVertex){{-1, 1, 0}, {0, 1}};   // 左上角
    self.vertices[1] = (SenceVertex){{-1, -1, 0}, {0, 0}};  // 左下角
    self.vertices[2] = (SenceVertex){{1, 1, 0}, {1, 1}};    // 右上角
    self.vertices[3] = (SenceVertex){{1, -1, 0}, {1, 0}};   // 右下角
    
    [self.glView display];
}

- (void)dealloc {
    
    if ([EAGLContext currentContext] == self.glView.context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    if (_vertices) {
        free(_vertices);
        _vertices = nil;
    }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.baseEffect prepareToDraw];
    
    // 顶点缓存
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    GLsizeiptr bufferSizeBytes = sizeof(SenceVertex) * 4;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_STATIC_DRAW);
    
    // 设置顶点数据
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, positionCoord));
    
    // 设置纹理数据
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, textureCoord));
    
    // 开始绘制
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // 删除顶点缓存
    glDeleteBuffers(1, &vertexBuffer);
    vertexBuffer = 0;
}


@end
