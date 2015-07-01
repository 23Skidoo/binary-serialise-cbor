module Data.Binary.Serialise.CBOR.Encoding where

import Data.Word
import Data.Int
import qualified Data.Text as T
import qualified Data.ByteString as B
import Data.Monoid


-- | An intermediate form used during serialisation. It supports efficient
-- concatenation.
--
-- It is used for the stage in serialisation where we flatten out the Haskell
-- data structure but it is independent of any specific external binary or text
-- format.
--
newtype Encoding = Encoding (Tokens -> Tokens)

-- | A flattened representation of a term
--
data Tokens =

    -- Positive and negative integers (type 0,1)
      TkWord     {-# UNPACK #-} !Word         Tokens
    | TkWord64   {-# UNPACK #-} !Word64       Tokens
    | TkNegInt64 {-# UNPACK #-} !Word64       Tokens
      -- convenience for either positive or negative
    | TkInt      {-# UNPACK #-} !Int          Tokens
    | TkInt64    {-# UNPACK #-} !Int64        Tokens

    -- Bytes and string (type 2,3)
    | TkBytes    {-# UNPACK #-} !B.ByteString Tokens
    | TkBytesBegin                            Tokens
    | TkString   {-# UNPACK #-} !T.Text       Tokens
    | TkStringBegin                           Tokens

    -- Structures (type 4,5)
    | TkListLen  {-# UNPACK #-} !Word         Tokens
    | TkListBegin                             Tokens
    | TkMapLen   {-# UNPACK #-} !Word         Tokens
    | TkMapBegin                              Tokens

    -- Tagged values (type 6)
    | TkTag      {-# UNPACK #-} !Word         Tokens
    | TkTag64    {-# UNPACK #-} !Word64       Tokens
    | TkInteger                 !Integer      Tokens

    -- Simple and floats (type 7)
    | TkNull                                  Tokens
    | TkUndef                                 Tokens
    | TkBool                    !Bool         Tokens
    | TkSimple   {-# UNPACK #-} !Word8        Tokens
    | TkFloat16  {-# UNPACK #-} !Float        Tokens
    | TkFloat32  {-# UNPACK #-} !Float        Tokens
    | TkFloat64  {-# UNPACK #-} !Double       Tokens
    | TkBreak                                 Tokens

    | TkEnd

instance Monoid Encoding where
  {-# INLINE mempty #-}
  mempty = Encoding (\ts -> ts)
  {-# INLINE mappend #-}
  Encoding b1 `mappend` Encoding b2 = Encoding (\ts -> b1 (b2 ts))
  {-# INLINE mconcat #-}
  mconcat = foldr mappend mempty

encodeWord :: Word -> Encoding
encodeWord = Encoding . TkWord

encodeWord64 :: Word64 -> Encoding
encodeWord64 = Encoding . TkWord64

encodeInt :: Int -> Encoding
encodeInt = Encoding . TkInt

encodeInt64 :: Int64 -> Encoding
encodeInt64 = Encoding . TkInt64

--TODO: move this check into the encoder side
encodeInteger :: Integer -> Encoding
encodeInteger n
  | n >= 0 && n <= fromIntegral (maxBound :: Word64)
                          = Encoding (TkWord64 (fromIntegral n))
  | n <  0 && n >= -1 - fromIntegral (maxBound :: Word64)
                          = Encoding (TkNegInt64 (fromIntegral (-1 - n)))
  | otherwise             = Encoding (TkInteger n)

encodeBytes :: B.ByteString -> Encoding
encodeBytes = Encoding . TkBytes

encodeBytesIndef :: Encoding
encodeBytesIndef = Encoding TkBytesBegin

encodeString :: T.Text -> Encoding
encodeString = Encoding . TkString

encodeStringIndef :: Encoding
encodeStringIndef = Encoding TkStringBegin

encodeListLen :: Word -> Encoding
encodeListLen = Encoding . TkListLen

encodeListLenIndef :: Encoding
encodeListLenIndef = Encoding TkListBegin

encodeMapLen :: Word -> Encoding
encodeMapLen = Encoding . TkMapLen

encodeMapLenIndef :: Encoding
encodeMapLenIndef = Encoding TkMapBegin

encodeBreak :: Encoding 
encodeBreak = Encoding TkBreak

encodeTag :: Word -> Encoding
encodeTag = Encoding . TkTag

encodeTag64 :: Word64 -> Encoding
encodeTag64 = Encoding . TkTag64

encodeBool :: Bool -> Encoding
encodeBool b = Encoding (TkBool b)

encodeUndef :: Encoding
encodeUndef = Encoding TkUndef

encodeNull :: Encoding
encodeNull = Encoding TkNull

encodeSimple :: Word8 -> Encoding
encodeSimple = Encoding . TkSimple

encodeFloat16 :: Float -> Encoding
encodeFloat16 = Encoding . TkFloat16

encodeFloat :: Float -> Encoding
encodeFloat = Encoding . TkFloat32

encodeDouble :: Double -> Encoding
encodeDouble = Encoding . TkFloat64

