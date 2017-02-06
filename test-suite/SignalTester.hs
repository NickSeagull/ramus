module SignalTester
    ( shouldYield
    , tick
    )
where

import Ramus.Signal
import Data.IORef
import Control.Monad (unless)
import System.IO.Unsafe
import Control.Concurrent

shouldYield :: (Eq a, Show a)
              => Signal a
              -> [a]
              -> IO ()
shouldYield sig vals = do
    remaining <- newIORef vals
    let getNext val = do
            nextValues <- readIORef remaining
            case nextValues of
                (x : xs) ->
                    if x /= val
                        then error $ "Expected " ++ show x ++ " but got " ++ show val
                        else case xs of
                            [] -> return ()
                            _ -> writeIORef remaining xs
                [] -> error "Unexpected emptiness"
    runSignal $ sig ~> getNext

tick :: Show a
     => Int
     -> Int
     -> [a]
     -> Signal a
tick initial interval values = unsafePerformIO $ do
    vals <- newIORef values
    valsShift <- shift vals
    let out = constant valsShift
    let pop = do
            shifted <- shift vals
            out `set` valsShift
            v <- readIORef vals
            unless (null v) (setTimeout interval pop)
    unless (null values) (setTimeout initial pop)
    return out

shift :: Show a => IORef [a] -> IO a
shift ref = do
    (x:xs) <- readIORef ref
    writeIORef ref xs
    return x


setTimeout :: Int -> IO () -> IO ()
setTimeout ms action = do
    threadDelay (ms * 1000)
    action