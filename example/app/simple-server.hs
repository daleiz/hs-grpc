{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import           Data.Either             (isRight)
import           Data.ProtoLens          (defMessage)
import           Lens.Micro

import           HsGrpc.Common.Log
import           HsGrpc.Server
import           Proto.Helloworld        as P
import           Proto.Helloworld_Fields as P

handlers :: [ServiceHandler]
handlers = [ unary (GRPC :: GRPC P.Greeter "echo") handleEcho
           , unary (GRPC :: GRPC P.Greeter "sayHello") handleSayHello
           , bidiStream (GRPC :: GRPC P.Greeter "sayHelloBiDiStream") handleBiDiSayHello
           ]

handleEcho :: UnaryHandler P.EchoMsg P.EchoMsg
handleEcho _ctx = pure

handleSayHello :: UnaryHandler P.HelloRequest P.HelloReply
handleSayHello _ctx req = pure $ defMessage & P.msg .~ (req ^. P.name)

handleBiDiSayHello :: BiDiStreamHandler P.HelloRequest P.HelloReply ()
handleBiDiSayHello _ctx stream = whileM $ do
  m_req <- streamRead stream
  case m_req of
    Just req -> do
      let reply = defMessage & P.msg .~ ("hi, " <> req ^. P.name)
      isRight <$> streamWrite stream (Just reply)
    Nothing -> putStrLn "Client closed" >> pure False

onStarted :: IO ()
onStarted = putStrLn "Server listening on 0.0.0.0:50051"

main :: IO ()
main = do
  let opts = ServerOptions { serverHost = "0.0.0.0"
                           , serverPort = 50051
                           , serverParallelism = 0
                           , serverSslOptions = Nothing
                           , serverOnStarted = Just onStarted
                           }
  gprSetLogVerbosity GprLogSeverityInfo
  runServer opts handlers
