//
//  VertexAttribArrayBuffer.h
//  demo
//
//  Created by 韩元旭 on 2020/10/2.
//

#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VertexAttribArrayBuffer : NSObject

- (instancetype)initWithAttribStribe:(GLsizei)stride
                    numberOfVertices:(GLsizei)count
                                data:(const GLvoid *)data
                               usage:(GLenum)usage;

- (void)prepareToDrawWithAttrib:(GLuint)index
               numberOfVertices:(GLsizei)count
                   attribOffset:(GLsizeiptr)offset
                   shouldEnable:(BOOL)shouldEnable;

- (void)drawArrayWithMode:(GLenum)mode
         startVertexIndex:(GLint)first
         numberOfVertices:(GLsizei)count;

- (void)updateDataWithAttribStribe:(GLsizei)stride
                  numberOfVertices:(GLsizei)count
                              data:(const GLvoid *)data
                             usage:(GLenum)usage;

@end

NS_ASSUME_NONNULL_END
