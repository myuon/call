{-# LANGUAGE FlexibleContexts, GADTs #-}
module Call.Util where
import Control.Monad.Objective.Class
import Control.Object
import Call.System
import Call.Types
import Call.Event
import Call.Data.Wave
import Call.Picture
import qualified Call.Util.Deck as Deck
import Control.Lens
import Control.Monad.State
import qualified Call.Data.Bitmap as Bitmap

readBitmap :: MonadIO m => FilePath -> m Bitmap.Bitmap
readBitmap = Bitmap.readFile

animate :: Monad m => (Time -> Picture) -> Object Graphic m
animate f = go (0 :: Float) where
  go t = Object $ \(Request dt cont) -> return (cont $ f t, go (t + dt))

transit :: MonadPlus m => Time -> (Time -> Picture) -> Object Graphic m
transit len f = go 0 where
  go t
    | t >= len = Object $ const mzero
    | otherwise = Object $ \(Request dt cont) -> return (cont $ f (t / len), go (t + dt))

withSound :: Source Stereo -> System s a -> System s a
withSound src m = do
  deck <- new Deck.empty
  deck .& Deck.source ?= src
  deck .& Deck.playing .= True
  linkAudio deck
  r <- m
  unlinkAudio deck
  return r