-----------------------------------------------------------------------------
--
-- Module      :  Graphics.WebGLTexture
-- Copyright   :  Jürgen Nicklisch-Franken
-- License     :  Apache-2.0
--
-- Maintainer  :  jnf@arcor.de
-- Stability   :
-- Portability :
--
-- | Textures for the WebGL binding for purescript
--
-----------------------------------------------------------------------------

module Graphics.WebGLTexture
(
    TargetType(..)
  , InternalFormat(..)
  , TextureType(..)
  , SymbolicParameter(..)
  , TexTarget(..)
  , TexParName(..)
  , WebGLTex(..)
  , TexFilterSpec(..)

  , texture2DFor
  , withTexture2D
  , activeTexture
  , bindTexture
  , unbindTexture
  , handleLoad2D
  , createTexture
  , newTexture

  , targetTypeToConst

)where

import Prelude
import Control.Monad.Eff.WebGL
import Graphics.WebGL
import Graphics.WebGLRaw

import Data.Int.Bits ((.&.),(.|.))
import Control.Monad.Eff
import Control.Monad (when)
import Extensions (Image(), fail)
import Data.Function

newtype WebGLTex = WebGLTex WebGLTexture

data TargetType =     TEXTURE_2D
                    | TEXTURE_CUBE_MAP_POSITIVE_X
                    | TEXTURE_CUBE_MAP_NEGATIVE_X
                    | TEXTURE_CUBE_MAP_POSITIVE_Y
                    | TEXTURE_CUBE_MAP_NEGATIVE_Y
                    | TEXTURE_CUBE_MAP_POSITIVE_Z
                    | TEXTURE_CUBE_MAP_NEGATIVE_Z

targetTypeToConst :: TargetType -> GLenum
targetTypeToConst TEXTURE_2D = _TEXTURE_2D
targetTypeToConst TEXTURE_CUBE_MAP_POSITIVE_X = _TEXTURE_CUBE_MAP_POSITIVE_X
targetTypeToConst TEXTURE_CUBE_MAP_NEGATIVE_X = _TEXTURE_CUBE_MAP_NEGATIVE_X
targetTypeToConst TEXTURE_CUBE_MAP_POSITIVE_Y = _TEXTURE_CUBE_MAP_POSITIVE_Y
targetTypeToConst TEXTURE_CUBE_MAP_NEGATIVE_Y = _TEXTURE_CUBE_MAP_NEGATIVE_Y
targetTypeToConst TEXTURE_CUBE_MAP_POSITIVE_Z = _TEXTURE_CUBE_MAP_POSITIVE_Z
targetTypeToConst TEXTURE_CUBE_MAP_NEGATIVE_Z = _TEXTURE_CUBE_MAP_NEGATIVE_Z

data InternalFormat =
  IF_ALPHA
  | IF_LUMINANCE
  | IF_LUMINANCE_ALPHA
  | IF_RGB
  | IF_RGBA

internalFormatToConst :: InternalFormat -> GLenum
internalFormatToConst IF_ALPHA     = _ALPHA
internalFormatToConst IF_LUMINANCE = _LUMINANCE
internalFormatToConst IF_LUMINANCE_ALPHA = _LUMINANCE_ALPHA
internalFormatToConst IF_RGB       = _RGB
internalFormatToConst IF_RGBA      = _RGBA

data TextureType =
  UNSIGNED_BYTE
  | RGBA
  | FLOAT
  | UNSIGNED_SHORT_5_6_5
  | UNSIGNED_SHORT_4_4_4_4
  | UNSIGNED_SHORT_5_5_5_1

textureTypeToConst :: TextureType -> GLenum
textureTypeToConst UNSIGNED_BYTE = _UNSIGNED_BYTE
textureTypeToConst RGBA = _RGBA
textureTypeToConst FLOAT = _FLOAT
textureTypeToConst UNSIGNED_SHORT_5_6_5 = _UNSIGNED_SHORT_5_6_5
textureTypeToConst UNSIGNED_SHORT_4_4_4_4 = _UNSIGNED_SHORT_4_4_4_4
textureTypeToConst UNSIGNED_SHORT_5_5_5_1 = _UNSIGNED_SHORT_5_5_5_1

data SymbolicParameter =
    PACK_ALIGNMENT
  | UNPACK_ALIGNMENT
  | UNPACK_FLIP_Y_WEBGL
  | UNPACK_PREMULTIPLY_ALPHA_WEBGL
  | UNPACK_COLORSPACE_CONVERSION_WEBGL

symbolicParameterToConst :: SymbolicParameter -> GLenum
symbolicParameterToConst PACK_ALIGNMENT = _PACK_ALIGNMENT
symbolicParameterToConst UNPACK_ALIGNMENT = _UNPACK_ALIGNMENT
symbolicParameterToConst UNPACK_FLIP_Y_WEBGL = _UNPACK_FLIP_Y_WEBGL
symbolicParameterToConst UNPACK_PREMULTIPLY_ALPHA_WEBGL = _UNPACK_PREMULTIPLY_ALPHA_WEBGL
symbolicParameterToConst UNPACK_COLORSPACE_CONVERSION_WEBGL = _UNPACK_COLORSPACE_CONVERSION_WEBGL

data TexTarget =
  TTEXTURE_2D
  | TTEXTURE_CUBE_MAP

texTargetToConst :: TexTarget -> GLenum
texTargetToConst TTEXTURE_2D = _TEXTURE_2D
texTargetToConst TTEXTURE_CUBE_MAP = _TEXTURE_CUBE_MAP

data TexParName =
  TEXTURE_MIN_FILTER
  | TEXTURE_MAG_FILTER
  | TEXTURE_WRAP_S
  | TEXTURE_WRAP_T
--  | TEXTURE_MAX_ANISOTROPY_EXT

texParNameToConst :: TexParName -> GLenum
texParNameToConst TEXTURE_MIN_FILTER = _TEXTURE_MIN_FILTER
texParNameToConst TEXTURE_MAG_FILTER = _TEXTURE_MAG_FILTER
texParNameToConst TEXTURE_WRAP_S = _TEXTURE_WRAP_S
texParNameToConst TEXTURE_WRAP_T = _TEXTURE_WRAP_T
-- texParNameToConst TEXTURE_MAX_ANISOTROPY_EXT = _TEXTURE_MAX_ANISOTROPY_EXT

data TexFilterSpec =
  NEAREST
  | LINEAR
  | MIPMAP

texFilterSpecToMagConst :: TexFilterSpec -> GLenum
texFilterSpecToMagConst NEAREST = _NEAREST
texFilterSpecToMagConst LINEAR = _LINEAR
texFilterSpecToMagConst MIPMAP = _LINEAR

texFilterSpecToMinConst :: TexFilterSpec -> GLenum
texFilterSpecToMinConst NEAREST = _NEAREST
texFilterSpecToMinConst LINEAR = _LINEAR
texFilterSpecToMinConst MIPMAP = _LINEAR_MIPMAP_NEAREST

texture2DFor :: forall a eff. String -> TexFilterSpec -> (WebGLTex -> EffWebGL eff a) -> EffWebGL eff Unit
texture2DFor name filterSpec continuation = do
  texture <- createTexture
  runFn2 loadImage_ name \image -> do
    handleLoad2D texture filterSpec image
    continuation texture

handleLoad2D :: forall eff a. WebGLTex -> TexFilterSpec -> a -> EffWebGL eff Unit
handleLoad2D texture filterSpec whatever = do
  bindTexture TEXTURE_2D texture
  pixelStorei UNPACK_FLIP_Y_WEBGL 1
  texImage2D TEXTURE_2D 0 IF_RGBA IF_RGBA UNSIGNED_BYTE whatever
  texParameteri TTEXTURE_2D TEXTURE_MAG_FILTER (texFilterSpecToMagConst filterSpec)
  texParameteri TTEXTURE_2D TEXTURE_MIN_FILTER (texFilterSpecToMinConst filterSpec)
  case filterSpec of
    MIPMAP -> runFn1 generateMipmap_ _TEXTURE_2D
    _ -> return unit
  unbindTexture TEXTURE_2D

newTexture :: forall eff. Int -> Int -> TexFilterSpec -> EffWebGL eff WebGLTex
newTexture width height filterSpec = do
  texture <- createTexture
  bindTexture TEXTURE_2D texture
  texParameteri TTEXTURE_2D TEXTURE_MAG_FILTER (texFilterSpecToMagConst filterSpec)
  texParameteri TTEXTURE_2D TEXTURE_MIN_FILTER (texFilterSpecToMinConst filterSpec)
  when (((width .|. height) .&. 1) == 1) $ do
    texParameteri TTEXTURE_2D TEXTURE_WRAP_S _CLAMP_TO_EDGE
    texParameteri TTEXTURE_2D TEXTURE_WRAP_T _CLAMP_TO_EDGE
  texImage2DNull TEXTURE_2D 0 IF_RGBA width height IF_RGBA UNSIGNED_BYTE
  case filterSpec of
    MIPMAP -> runFn1 generateMipmap_ _TEXTURE_2D
    _ -> return unit
  unbindTexture TEXTURE_2D
  return texture

texParameteri :: forall eff. TexTarget -> TexParName -> GLint -> EffWebGL eff Unit
texParameteri target pname param = runFn3 texParameteri_ (texTargetToConst target) (texParNameToConst pname) param

pixelStorei :: forall eff. SymbolicParameter -> Int -> EffWebGL eff Unit
pixelStorei symbolicParameter num = runFn2 pixelStorei_ (symbolicParameterToConst symbolicParameter) num

withTexture2D :: forall eff typ. WebGLTex -> Int -> Uniform typ -> Int -> EffWebGL eff Unit
withTexture2D texture index (Uniform sampler) pos = do
  activeTexture index
  bindTexture TEXTURE_2D texture
  uniform1i sampler.uLocation pos

bindTexture :: forall eff. TargetType -> WebGLTex -> EffWebGL eff Unit
bindTexture tt (WebGLTex texture) = runFn2 bindTexture_ (targetTypeToConst tt) texture

unbindTexture :: forall eff. TargetType -> EffWebGL eff Unit
unbindTexture tt = runFn1 bindTexture__ (targetTypeToConst tt)

texImage2D :: forall eff a. TargetType -> GLint -> InternalFormat -> InternalFormat -> TextureType -> a
                    -> EffWebGL eff Unit
texImage2D target level internalFormat format typ pixels =
  runFn6 texImage2D__ (targetTypeToConst target) level (internalFormatToConst internalFormat)
    (internalFormatToConst format) (textureTypeToConst typ) pixels

texImage2DNull :: forall eff. TargetType -> GLint -> InternalFormat -> GLsizei -> GLsizei -> InternalFormat -> TextureType
                    -> EffWebGL eff Unit
texImage2DNull target level internalFormat width height format typ =
  runFn8 texImage2DNull_ (targetTypeToConst target) level (internalFormatToConst internalFormat)
    width height 0 (internalFormatToConst format) (textureTypeToConst typ)

activeTexture :: forall eff. Int -> Eff (webgl :: WebGl | eff) Unit
activeTexture n | n < _MAX_COMBINED_TEXTURE_IMAGE_UNITS = runFn1 activeTexture_ (_TEXTURE0 + n)
                | otherwise                             = fail "WebGLTexture>>activeTexture: wrong argument!"

createTexture :: forall eff. Eff (webgl :: WebGl | eff) WebGLTex
createTexture = do
          texture <- runFn0 createTexture_
          return (WebGLTex texture)

uniform1i :: forall eff. WebGLUniformLocation -> GLint -> Eff (webgl :: WebGl | eff) Unit
uniform1i = runFn2 uniform1i_

foreign import loadImage_ :: forall a eff. Fn2 String
                     (Image -> EffWebGL eff a)
                     (EffWebGL eff Unit)

foreign import texImage2D__ :: forall a eff. Fn6 GLenum
                   GLint
                   GLenum
                   GLenum
                   GLenum
                   a
                   (EffWebGL eff Unit)

foreign import texImage2DNull_ :: forall eff. Fn8 GLenum
                   GLint
                   GLenum
                   GLsizei
                   GLsizei
                   GLint
                   GLenum
                   GLenum
                   (Eff (webgl :: WebGl | eff) Unit)

foreign import bindTexture__ :: forall eff. Fn1 GLenum
                   (Eff (webgl :: WebGl | eff) Unit)
