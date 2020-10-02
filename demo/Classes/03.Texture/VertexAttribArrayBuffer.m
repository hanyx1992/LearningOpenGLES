//
//  VertexAttribArrayBuffer.m
//  demo
//
//  Created by 韩元旭 on 2020/10/2.
//

#import "VertexAttribArrayBuffer.h"

@interface VertexAttribArrayBuffer ()

@property (nonatomic, assign) GLuint name;
@property (nonatomic, assign) GLsizeiptr bufferSizeBytes;
@property (nonatomic, assign) GLsizei stride;
@end

@implementation VertexAttribArrayBuffer

- (instancetype)initWithAttribStribe:(GLsizei)stride numberOfVertices:(GLsizei)count data:(const GLvoid *)data usage:(GLenum)usage {
    self = [super init];
    if (self) {
        _stride = stride;
        _bufferSizeBytes = stride * count;
        glGenBuffers(1, &_name);
        glBindBuffer(GL_ARRAY_BUFFER, _name);
        glBufferData(GL_ARRAY_BUFFER, _bufferSizeBytes, data, usage);
    }
    return self;
}

- (void)dealloc {
    if (_name != 0) {
        glDeleteBuffers(1, &_name);
        _name = 0;
    }
}

- (void)updateDataWithAttribStribe:(GLsizei)stride numberOfVertices:(GLsizei)count data:(const GLvoid *)data usage:(GLenum)usage {
    _stride = stride;
    _bufferSizeBytes = stride * count;
    glBindBuffer(GL_ARRAY_BUFFER, _name);
    glBufferData(GL_ARRAY_BUFFER, _bufferSizeBytes, data, usage);
}

- (void)prepareToDrawWithAttrib:(GLuint)index numberOfVertices:(GLsizei)count attribOffset:(GLsizeiptr)offset shouldEnable:(BOOL)shouldEnable {
    glBindBuffer(GL_ARRAY_BUFFER, _name);
    if (shouldEnable) {
        glEnableVertexAttribArray(index);
    }
    glVertexAttribPointer(index, count, GL_FLOAT, GL_FALSE, _stride, NULL + offset);
}

- (void)drawArrayWithMode:(GLenum)mode startVertexIndex:(GLint)first numberOfVertices:(GLsizei)count {
    glDrawArrays(mode, first, count);
}

@end
