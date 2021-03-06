{-# LANGUAGE TypeFamilies #-}

import qualified Graphics.Formats.Collada as Collada
import qualified Graphics.UI.GLUT as GLUT
import qualified Graphics.Rendering.OpenGL.GL as GL
import qualified Graphics.Rendering.OpenGL.GLU as GLU
import System.IO
import Control.Applicative
import Data.VectorSpace
import Data.IORef

instance AdditiveGroup GL.GLdouble where
    zeroV = 0
    (^+^) = (+)
    negateV = negate

instance VectorSpace GL.GLdouble where
    type Scalar GL.GLdouble = GL.GLdouble
    (*^) = (*)

instance InnerSpace GL.GLdouble where
    (<.>) = (*)

main = do
    hSetBuffering stdout NoBuffering

    GLUT.initialDisplayMode GL.$= [GLUT.RGBAMode, GLUT.DoubleBuffered, GLUT.WithDepthBuffer]

    GLUT.getArgsAndInitialize
    GLUT.createWindow "Hello!"

    putStrLn "Loading"
    action <- Collada.load Collada.defaultConfig =<< getContents
    putStrLn "Done"

    GL.matrixMode GL.$= GL.Projection
    GL.loadIdentity
    GLU.perspective 45 1 1 1000
    GL.matrixMode GL.$= GL.Modelview 0
    GL.loadIdentity

    GL.lighting GL.$= GL.Enabled
    GL.light (GL.Light 0) GL.$= GL.Enabled
    GL.position (GL.Light 0) GL.$= GL.Vertex4 0 0 10 1
    GL.depthFunc GL.$= Nothing
    GL.depthFunc GL.$= Just GL.Lequal
    GL.depthMask GL.$= GL.Enabled
    GL.normalize GL.$= GL.Enabled

    GLUT.displayCallback GLUT.$= (do
        GL.clearColor GL.$= GL.Color4 0 0 0 0
        GL.clear [GL.ColorBuffer, GL.DepthBuffer]
        GL.preservingMatrix $ do
            GL.loadIdentity
            GLU.lookAt (uncurry3 GL.Vertex3 eye) (uncurry3 GL.Vertex3 object) (uncurry3 GL.Vector3 up)
            GL.renderPrimitive GL.Lines $ do
                vertex (-200) 0 0
                vertex 200 0 0
                vertex 0 (-200) 0
                vertex 0 200 0
                vertex 0 0 (-200)
                vertex 0 0 200
            action
        GLUT.swapBuffers)
    GLUT.mainLoop

    where
    eye = (10, 10, 10)
    object = (0, 0, 0)
    up = normalized $ (object ^-^ eye) `cross` ((object ^-^ eye) `cross` (0,0,-1))
    cross (bx,by,bz) (cx,cy,cz) = (by*cz - cy*bz, bz*cx - bx*cz, bx*cy - by*cx)

    uncurry3 f (x,y,z) = f x y z

    vertex :: GL.GLfloat -> GL.GLfloat -> GL.GLfloat -> IO ()
    vertex x y z = GL.vertex $ GL.Vertex3 x y z
