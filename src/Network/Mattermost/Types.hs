{-# LANGUAGE MultiWayIf #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Network.Mattermost.Types where

import           Control.Applicative
import           Text.Printf ( printf )
import           Data.Hashable ( Hashable )
import qualified Data.Aeson as A
import           Data.Aeson ( (.:), (.=), (.:?), (.!=) )
import           Data.Aeson.Types ( ToJSONKey
                                  , FromJSONKey
                                  , FromJSON
                                  , ToJSON
                                  , Parser
                                  , typeMismatch
                                  )
import           Data.HashMap.Strict ( HashMap )
import qualified Data.HashMap.Strict as HM
import           Data.Monoid ( (<>) )
import           Data.Ratio ( (%) )
import           Data.Sequence (Seq)
import qualified Data.Sequence as S
import           Data.Text (Text)
import qualified Data.Text as T
import           Data.Time.Clock ( UTCTime, getCurrentTime )
import           Data.Time.Clock.POSIX ( posixSecondsToUTCTime
                                       , utcTimeToPOSIXSeconds )
import           Network.Connection (ConnectionContext, initConnectionContext)
import           Network.HTTP.Base (RequestMethod)
import           Network.HTTP.Headers (Header, HeaderName(..), mkHeader)

-- | A 'Logger' is any function which responds to log events:
type Logger = LogEvent -> IO ()

-- | If there is a 'Logger' in the 'ConnectionData' struct, it will
--   be sporadically called with values of type 'LogEvent'.
data LogEvent = LogEvent
  { logFunction  :: String
  , logEventType :: LogEventType
  } deriving (Eq, Show)

-- | A 'LogEventType' describes the particular event that happened
data LogEventType
  = HttpRequest RequestMethod String (Maybe A.Value)
  | HttpResponse Int String (Maybe A.Value)
  | WebSocketRequest A.Value
  | WebSocketResponse A.Value
  | WebSocketPing
  | WebSocketPong
    deriving (Eq, Show)

runLogger :: ConnectionData -> String -> LogEventType -> IO ()
runLogger ConnectionData { cdLogger = Just l } n ev =
  l (LogEvent n ev)
runLogger _ _ _ = return ()

maybeFail :: Parser a -> Parser (Maybe a)
maybeFail p = (Just <$> p) <|> (return Nothing)

type Hostname = String
type Port     = Int

-- For now we don't support or expose the ability to reuse connections,
-- but we have this field in case we want to support that in the future.
-- Doing so will require some modifications to withConnection (and uses).
-- Note: don't export this until we support connection reuse.
data AutoClose = No | Yes
  deriving (Read, Show, Eq, Ord)

-- | We return a list of headers so that we can treat
-- the headers like a monoid.
autoCloseToHeader :: AutoClose -> [Header]
autoCloseToHeader No  = []
autoCloseToHeader Yes = [mkHeader HdrConnection "Close"]


data ConnectionData
  = ConnectionData
  { cdHostname      :: Hostname
  , cdPort          :: Port
  , cdAutoClose     :: AutoClose
  , cdConnectionCtx :: ConnectionContext
  , cdToken         :: Maybe Token
  , cdLogger        :: Maybe Logger
  , cdUseTLS        :: Bool
  }

-- | Creates a TLS connection to the server.
mkConnectionData :: Hostname -> Port -> ConnectionContext -> ConnectionData
mkConnectionData host port ctx = ConnectionData
  { cdHostname      = host
  , cdPort          = port
  , cdConnectionCtx = ctx
  , cdAutoClose     = Yes
  , cdToken         = Nothing
  , cdLogger        = Nothing
  , cdUseTLS        = True
  }

-- | Plaintext HTTP instead of a TLS connection.
mkConnectionDataInsecure :: Hostname -> Port -> ConnectionContext -> ConnectionData
mkConnectionDataInsecure host port ctx = ConnectionData
  { cdHostname      = host
  , cdPort          = port
  , cdConnectionCtx = ctx
  , cdAutoClose     = Yes
  , cdToken         = Nothing
  , cdLogger        = Nothing
  , cdUseTLS        = False
  }

initConnectionData :: Hostname -> Port -> IO ConnectionData
initConnectionData host port = do
  ctx <- initConnectionContext
  return (mkConnectionData host port ctx)

initConnectionDataInsecure :: Hostname -> Port -> IO ConnectionData
initConnectionDataInsecure host port = do
  ctx <- initConnectionContext
  return (mkConnectionDataInsecure host port ctx)

withLogger :: ConnectionData -> Logger -> ConnectionData
withLogger cd logger = cd { cdLogger = Just logger }

noLogger :: ConnectionData -> ConnectionData
noLogger cd = cd { cdLogger = Nothing }

data Token = Token String
  deriving (Read, Show, Eq, Ord)

getTokenString :: Token -> String
getTokenString (Token s) = s

--

data Login
  = Login
  { username :: Text
  , password :: Text
  }

instance A.ToJSON Login where
  toJSON l = A.object ["login_id" A..= username l
                      ,"password" A..= password l
                      -- XXX do we also need "token" -> "" like the web client?
                      ]


data SetChannelHeader = SetChannelHeader
  { setChannelHeaderChanId :: ChannelId
  , setChannelHeaderString :: Text
  }

instance A.ToJSON SetChannelHeader where
  toJSON (SetChannelHeader cId p) =
      A.object ["channel_id" A..= cId
               ,"channel_header" A..= p
               ]

data Type = Ordinary
          | Direct
          | Private
          | Unknown Text
  deriving (Read, Show, Ord, Eq)

instance A.FromJSON Type where
  parseJSON = A.withText "Type" $ \t ->
      return $ if | t == "O"  -> Ordinary
                  | t == "D"  -> Direct
                  | t == "P"  -> Private
                  | otherwise -> Unknown t

instance A.ToJSON Type where
  toJSON Direct    = A.toJSON ("D"::Text)
  toJSON Ordinary  = A.toJSON ("O"::Text)
  toJSON Private   = A.toJSON ("P"::Text)
  toJSON (Unknown t) = A.toJSON t

--

-- For converting from type specific Id to generic Id
class IsId x where
  toId   :: x  -> Id
  fromId :: Id -> x

class HasId x y | x -> y where
  getId :: x -> y

newtype Id = Id { unId :: Text }
  deriving (Read, Show, Eq, Ord, Hashable, ToJSON, ToJSONKey, FromJSONKey)

idString :: IsId x => x -> Text
idString x = unId i
  where i = toId x

instance A.FromJSON Id where
  parseJSON = A.withText "Id" $ \t ->
      case T.null t of
          False -> return $ Id t
          True -> fail "Empty ID"

instance IsId Id where
  toId   = id
  fromId = id

instance HasId Id Id where
  getId  = id

--

newtype TeamId = TI { unTI :: Id }
  deriving (Read, Show, Eq, Ord, Hashable, ToJSON, ToJSONKey, FromJSONKey, FromJSON)

instance IsId TeamId where
  toId   = unTI
  fromId = TI

data Team
  = Team
  { teamId              :: TeamId
  , teamCreateAt        :: UTCTime
  , teamUpdateAt        :: UTCTime
  , teamDeleteAt        :: UTCTime
  , teamDisplayName     :: Text
  , teamName            :: Text
  , teamEmail           :: Text
  , teamType            :: Type
  , teamCompanyName     :: Text
  , teamAllowedDomains  :: Text
  , teamInviteId        :: Id -- XXX: What type of Id is this?
  , teamAllowOpenInvite :: Bool
  }
  deriving (Read, Show, Eq, Ord)

instance HasId Team TeamId where
  getId = teamId

instance A.FromJSON Team where
  parseJSON = A.withObject "Team" $ \v -> do
    teamId              <- v .: "id"
    teamCreateAt        <- millisecondsToUTCTime <$> v .: "create_at"
    teamUpdateAt        <- millisecondsToUTCTime <$> v .: "update_at"
    teamDeleteAt        <- millisecondsToUTCTime <$> v .: "delete_at"
    teamDisplayName     <- v .: "display_name"
    teamName            <- v .: "name"
    teamEmail           <- v .: "email"
    teamType            <- v .: "type"
    teamCompanyName     <- v .: "company_name"
    teamAllowedDomains  <- v .: "allowed_domains"
    teamInviteId        <- v .: "invite_id"
    teamAllowOpenInvite <- v .: "allow_open_invite"
    return Team { .. }

--

newtype ChannelId = CI { unCI :: Id }
  deriving (Read, Show, Eq, Ord, Hashable, ToJSON, ToJSONKey, FromJSONKey, FromJSON)

instance IsId ChannelId where
  toId   = unCI
  fromId = CI

data Channel
  = Channel
  { channelId            :: ChannelId
  , channelCreateAt      :: UTCTime
  , channelUpdateAt      :: UTCTime
  , channelDeleteAt      :: UTCTime
  , channelTeamId        :: Maybe TeamId
  , channelType          :: Type
  , channelDisplayName   :: Text
  , channelName          :: Text
  , channelHeader        :: Text
  , channelPurpose       :: Text
  , channelLastPostAt    :: UTCTime
  , channelTotalMsgCount :: Int
  , channelExtraUpdateAt :: UTCTime
  , channelCreatorId     :: Maybe UserId
  } deriving (Read, Show, Eq, Ord)

instance HasId Channel ChannelId where
  getId = channelId

instance A.FromJSON Channel where
  parseJSON = A.withObject "Channel" $ \v -> do
    channelId              <- v .: "id"
    channelCreateAt        <- millisecondsToUTCTime <$> v .: "create_at"
    channelUpdateAt        <- millisecondsToUTCTime <$> v .: "update_at"
    channelDeleteAt        <- millisecondsToUTCTime <$> v .: "delete_at"
    channelTeamId          <- maybeFail (v .: "team_id")
    channelType            <- v .: "type"
    channelDisplayName     <- v .: "display_name"
    channelName            <- v .: "name"
    channelHeader          <- v .: "header"
    channelPurpose         <- v .: "purpose"
    channelLastPostAt      <- millisecondsToUTCTime <$> v .: "last_post_at"
    channelTotalMsgCount   <- v .: "total_msg_count"
    channelExtraUpdateAt   <- millisecondsToUTCTime <$> v .: "extra_update_at"
    channelCreatorId       <- maybeFail (v .: "creator_id")
    return Channel { .. }

-- This type only exists so that we can strip off the
-- outer most layer in mmGetChannel. See the
-- FromJSON instance.
newtype SingleChannel = SC Channel
  deriving (Read, Show, Eq, Ord)

instance A.FromJSON SingleChannel where
  parseJSON = A.withObject "SingleChannel" $ \v -> do
    channel <- v .: "channel"
    return (SC channel)

instance HasId ChannelData ChannelId where
  getId = channelDataChannelId

data ChannelData
  = ChannelData
  { channelDataChannelId    :: ChannelId
  , channelDataUserId       :: UserId
  , channelDataRoles        :: Text -- XXX: what goes here
  , channelDataLastViewedAt :: UTCTime
  , channelDataMsgCount     :: Int
  , channelDataMentionCount :: Int
  , channelDataNotifyProps  :: HashMap Text Text
  , channelDataLastUpdateAt :: UTCTime
  } deriving (Read, Show, Eq)

instance A.FromJSON ChannelData where
  parseJSON = A.withObject "ChanelData" $ \o -> do
    channelDataChannelId <- o .: "channel_id"
    channelDataUserId    <- o .: "user_id"
    channelDataRoles     <- o .: "roles"
    channelDataLastViewedAt <- millisecondsToUTCTime <$> o .: "last_viewed_at"
    channelDataMsgCount     <- o .: "msg_count"
    channelDataMentionCount <- o .: "mention_count"
    channelDataNotifyProps  <- o .: "notify_props"
    channelDataLastUpdateAt <- millisecondsToUTCTime <$> o .: "last_update_at"
    return ChannelData { .. }

data ChannelWithData = ChannelWithData Channel ChannelData
  deriving (Read, Show, Eq)

instance A.FromJSON ChannelWithData where
  parseJSON (A.Object v) =
      ChannelWithData <$> (v .: "channel")
                      <*> (v .: "member")
  parseJSON v = typeMismatch "Invalid channel/data pair " v

type Channels = Seq Channel

data MinChannel = MinChannel
  { minChannelName        :: Text
  , minChannelDisplayName :: Text
  , minChannelPurpose     :: Maybe Text
  , minChannelHeader      :: Maybe Text
  , minChannelType        :: Type
  } deriving (Read, Eq, Show)

instance A.ToJSON MinChannel where
  toJSON MinChannel { .. }  = A.object $
    [ "name"         .= minChannelName
    , "display_name" .= minChannelDisplayName
    , "type"         .= minChannelType
    ] ++
    [ "purpose" .= p | Just p <- [minChannelPurpose] ] ++
    [ "header"  .= h | Just h <- [minChannelHeader] ]
--

newtype UserId = UI { unUI :: Id }
  deriving (Read, Show, Eq, Ord, Hashable, ToJSON, ToJSONKey, FromJSONKey, FromJSON)

instance IsId UserId where
  toId   = unUI
  fromId = UI

data UserProfile
  = UserProfile
  { userProfileEmail          :: Text
  , userProfileRoles          :: Text
  , userProfileFirstName      :: Text
  , userProfileAuthService    :: Text
  , userProfileLocale         :: Text
  , userProfileUsername       :: Text
  , userProfileAuthData       :: Text
  , userProfileLastName       :: Text
  , userProfileId             :: UserId
  , userProfileNickname       :: Text
  , userProfileDeleteAt       :: UTCTime
  , userProfileCreateAt       :: UTCTime
  } deriving (Read, Show, Eq, Ord)

instance HasId UserProfile UserId where
  getId = userProfileId

instance A.FromJSON UserProfile where
  parseJSON = A.withObject "UserProfile" $ \v -> do
    userProfileEmail          <- v .: "email"
    userProfileRoles          <- v .: "roles"
    userProfileFirstName      <- v .: "first_name"
    userProfileAuthService    <- v .: "auth_service"
    userProfileLocale         <- v .: "locale"
    userProfileUsername       <- v .: "username"
    userProfileAuthData       <- v .: "auth_data"
    userProfileLastName       <- v .: "last_name"
    userProfileId             <- v .: "id"
    userProfileNickname       <- v .: "nickname"
    userProfileDeleteAt       <- millisecondsToUTCTime <$> v .: "delete_at"
    userProfileCreateAt       <- millisecondsToUTCTime <$> v .: "create_at"
    return UserProfile { .. }

--

-- Note: there's lots of other stuff in an initial_load response but
-- this is what we use for now.
data InitialLoad
  = InitialLoad
  { initialLoadUser :: User
  , initialLoadTeams :: Seq Team
  } deriving (Eq, Show)

instance A.FromJSON InitialLoad where
  parseJSON = A.withObject "InitialLoad" $ \o -> do
    initialLoadUser        <- o .: "user"
    initialLoadTeams       <- o .: "teams"
    return InitialLoad { .. }

--

instance HasId User UserId where
  getId = userId

data User
  = User
  { userId                 :: UserId
  , userCreateAt           :: UTCTime
  , userUpdateAt           :: UTCTime
  , userDeleteAt           :: UTCTime
  , userUsername           :: Text
  , userAuthData           :: Text
  , userAuthService        :: Text
  , userEmail              :: Text
  , userEmailVerified      :: Bool
  , userNickname           :: Text
  , userFirstName          :: Text
  , userLastName           :: Text
  , userRoles              :: Text -- XXX: what are the options?
  , userNotifyProps        :: HashMap Text Text -- See NotifyProps type below
  , userLastPasswordUpdate :: UTCTime
  , userLastPictureUpdate  :: Maybe UTCTime
  , userLocale             :: Text
  } deriving (Read, Show, Eq)

instance A.FromJSON User where
  parseJSON = A.withObject "User" $ \o -> do
    userId                 <- o .: "id"
    userCreateAt           <- millisecondsToUTCTime <$> o .: "create_at"
    userUpdateAt           <- millisecondsToUTCTime <$> o .: "update_at"
    userDeleteAt           <- millisecondsToUTCTime <$> o .: "delete_at"
    userUsername           <- o .:  "username"
    userAuthData           <- o .:  "auth_data"
    userAuthService        <- o .:  "auth_service"
    userEmail              <- o .:  "email"
    userEmailVerified      <- o .:? "email_verified" .!= False
    userNickname           <- o .:  "nickname"
    userFirstName          <- o .:  "first_name"
    userLastName           <- o .:  "last_name"
    userRoles              <- o .:  "roles"
    userNotifyProps        <- o .:  "notify_props"
    userLastPasswordUpdate <- millisecondsToUTCTime <$> o .: "last_password_update"
    userLastPictureUpdate  <- (millisecondsToUTCTime <$>) <$> (o .:? "last_picture_update")
    userLocale             <- o .: "locale"
    return User { .. }

-- XXX: Let's defer making a custom type for this until
-- we have more information about how we'll use it.
-- -- XXX: A bunch of these should be bools, but aeson is not
-- -- parsing them as such. So for now I'm just setting them as strings.
-- data NotifyProps
--   = NotifyProps
--   { notifyPropsAll          :: String -- bool
--   , notifyPropsChannel      :: String -- bool
--   , notifyPropsDesktop      :: String -- XXX: what goes here
--   , notifyPropsDesktopSound :: String -- bool
--   , notifyPropsEmail        :: String -- bool
--   , notifyPropsFirstName    :: String -- bool
--   , notifyPropsMentionKeys  :: [String]
--   , notifyPropsPush         :: String -- XXX: what goes here
--   } deriving (Read, Show, Eq, Ord)
--
-- instance A.FromJSON NotifyProps where
--   parseJSON = A.withObject "NotifyProps" $ \o -> do
--     notifyPropsAll          <- o .: "all"
--     notifyPropsChannel      <- o .: "channel"
--     notifyPropsDesktop      <- o .: "desktop"
--     notifyPropsDesktopSound <- o .: "desktop_sound"
--     notifyPropsEmail        <- o .: "email"
--     notifyPropsFirstName    <- o .: "first_name"
--     mentionKeys             <- T.splitOn "," <$> o .: "mention_keys"
--     let notifyPropsMentionKeys = map T.unpack mentionKeys
--     notifyPropsPush         <- o .: "push"
--     return NotifyProps { .. }

--

data PostPropAttachment
  = PostPropAttachment
  { ppaColor :: Text
  , ppaText  :: Text
  } deriving (Read, Show, Eq)

instance A.FromJSON PostPropAttachment where
  parseJSON = A.withObject "Attachment" $ \v -> do
    ppaColor <- v .: "color"
    ppaText  <- v .: "text"
    return PostPropAttachment { .. }

instance A.ToJSON PostPropAttachment where
  toJSON PostPropAttachment { .. } = A.object
    [ "color" .= ppaColor
    , "text"  .= ppaText
    ]

data PostProps
  = PostProps
  { postPropsOverrideIconUrl  :: Maybe Text
  , postPropsOverrideUsername :: Maybe Text
  , postPropsAttachments      :: Maybe (Seq PostPropAttachment) -- A.Value
  } deriving (Read, Show, Eq)

instance A.FromJSON PostProps where
  parseJSON = A.withObject "Props" $ \v -> do
    postPropsOverrideIconUrl  <- v .:? "override_icon_url"
    postPropsOverrideUsername <- v .:? "override_username"
    postPropsAttachments      <- v .:? "attachments"
    return PostProps { .. }

instance A.ToJSON PostProps where
  toJSON PostProps { .. } = A.object $
    [ "override_icon_url" .= v | Just v <- [postPropsOverrideIconUrl] ] ++
    [ "override_username" .= v | Just v <- [postPropsOverrideUsername] ] ++
    [ "attachments" .= v | Just v <- [postPropsAttachments] ]

newtype PostId = PI { unPI :: Id }
  deriving (Read, Show, Eq, Ord, Hashable, ToJSON, ToJSONKey, FromJSONKey, FromJSON)

instance IsId PostId where
  toId   = unPI
  fromId = PI

newtype FileId = FI { unFI :: Id }
  deriving (Read, Show, Eq, Ord, Hashable, ToJSON, ToJSONKey, FromJSONKey, FromJSON)

instance IsId FileId where
  toId = unFI
  fromId = FI

urlForFile :: FileId -> Text
urlForFile fId =
  "/api/v3/files/" <> idString fId <> "/get"

data Post
  = Post
  { postPendingPostId :: Maybe PostId
  , postOriginalId    :: Maybe PostId
  , postProps         :: PostProps
  , postRootId        :: Text
  , postFileIds       :: Seq FileId
  , postId            :: PostId
  , postType          :: Type
  , postMessage       :: Text
  , postDeleteAt      :: UTCTime
  , postHashtags      :: Text
  , postUpdateAt      :: UTCTime
  , postUserId        :: Maybe UserId
  , postCreateAt      :: UTCTime
  , postParentId      :: Maybe PostId
  , postChannelId     :: ChannelId
  , postHasReactions  :: Bool
  } deriving (Read, Show, Eq)

instance HasId Post PostId where
  getId = postId

instance A.FromJSON Post where
  parseJSON = A.withObject "Post" $ \v -> do
    postPendingPostId <- maybeFail (v .: "pending_post_id")
    postOriginalId    <- maybeFail (v .: "original_id")
    postProps         <- v .: "props"
    postRootId        <- v .: "root_id"
    postFileIds       <- (v .: "file_ids") <|> (return mempty)
    postId            <- v .: "id"
    postType          <- v .: "type"
    postMessage       <- v .: "message"
    postDeleteAt      <- millisecondsToUTCTime <$> v .: "delete_at"
    postHashtags      <- v .: "hashtags"
    postUpdateAt      <- millisecondsToUTCTime <$> v .: "update_at"
    postUserId        <- maybeFail (v .: "user_id")
    postCreateAt      <- millisecondsToUTCTime <$> v .: "create_at"
    postParentId      <- maybeFail (v .: "parent_id")
    postChannelId     <- v .: "channel_id"
    postHasReactions  <- (v .: "has_reactions") <|> (return False)
    return Post { .. }

instance A.ToJSON Post where
  toJSON Post { .. } = A.object
    [ "pending_post_id" .= postPendingPostId
    , "original_id"     .= postOriginalId
    , "props"           .= postProps
    , "root_id"         .= postRootId
    , "file_ids"        .= postFileIds
    , "id"              .= postId
    , "type"            .= postType
    , "message"         .= postMessage
    , "delete_at"       .= postDeleteAt
    , "hashtags"        .= postHashtags
    , "update_at"       .= postUpdateAt
    , "user_id"         .= postUserId
    , "create_at"       .= postCreateAt
    , "parent_id"       .= postParentId
    , "channel_id"      .= postChannelId
    , "has_reactions"   .= postHasReactions
    ]

data PendingPost
  = PendingPost
  { pendingPostChannelId :: ChannelId
  , pendingPostCreateAt  :: UTCTime
  , pendingPostFilenames :: Seq FilePath
  , pendingPostMessage   :: Text
  , pendingPostId        :: PendingPostId
  , pendingPostUserId    :: UserId
  } deriving (Read, Show, Eq)

instance A.ToJSON PendingPost where
  toJSON post = A.object
    [ "channel_id"      .= pendingPostChannelId post
    , "create_at"       .= utcTimeToMilliseconds (pendingPostCreateAt post)
    , "filenames"       .= pendingPostFilenames post
    , "message"         .= pendingPostMessage   post
    , "pending_post_id" .= pendingPostId        post
    , "user_id"         .= pendingPostUserId    post
    ]

newtype PendingPostId = PPI { unPPI :: Id }
  deriving (Read, Show, Eq, Ord, Hashable, ToJSON, ToJSONKey, FromJSONKey, FromJSON)

instance IsId PendingPostId where
  toId   = unPPI
  fromId = PPI

instance HasId PendingPost PendingPostId where
  getId = pendingPostId

mkPendingPost :: Text -> UserId -> ChannelId -> IO PendingPost
mkPendingPost msg userid channelid = do
  now <- getCurrentTime
  let ms  = utcTimeToMilliseconds now :: Int
      pid = T.pack $ printf "%s:%d" (idString userid) ms
  return PendingPost
    { pendingPostId        = PPI (Id pid)
    , pendingPostChannelId = channelid
    , pendingPostCreateAt  = now
    , pendingPostFilenames = S.empty
    , pendingPostMessage   = msg
    , pendingPostUserId    = userid
    }

data FileInfo
  = FileInfo
  { fileInfoId         :: FileId
  , fileInfoUserId     :: UserId
  , fileInfoPostId     :: Maybe PostId
  , fileInfoCreateAt   :: UTCTime
  , fileInfoUpdateAt   :: UTCTime
  , fileInfoDeleteAt   :: UTCTime
  , fileInfoName       :: Text
  , fileInfoExtension  :: Text
  , fileInfoSize       :: Int
  , fileInfoMimeType   :: Text
  , fileInfoWidth      :: Maybe Int
  , fileInfoHeight     :: Maybe Int
  , fileInfoHasPreview :: Bool
  } deriving (Read, Show, Eq)

instance FromJSON FileInfo where
  parseJSON = A.withObject "file_info" $ \o -> do
    fileInfoId         <- o .: "id"
    fileInfoUserId     <- o .: "user_id"
    fileInfoPostId     <- o .: "post_id"
    fileInfoCreateAt   <- o .: "create_at"
    fileInfoUpdateAt   <- o .: "update_at"
    fileInfoDeleteAt   <- o .: "delete_at"
    fileInfoName       <- o .: "name"
    fileInfoExtension  <- o .: "extension"
    fileInfoSize       <- o .: "size"
    fileInfoMimeType   <- o .: "mime_type"
    fileInfoWidth      <- o .: "width"
    fileInfoHeight     <- o .: "height"
    fileInfoHasPreview <- (o .: "has_preview_image") <|> pure False
    return FileInfo { .. }

--

data Posts
  = Posts
  { postsPosts :: HM.HashMap PostId Post
  , postsOrder :: Seq PostId
  } deriving (Read, Show, Eq)

instance A.FromJSON Posts where
  parseJSON = A.withObject "Posts" $ \v -> do
    postsPosts <- v .:? "posts" .!= HM.empty
    postsOrder <- v .:  "order"
    return Posts { .. }

--

millisecondsToUTCTime :: Integer -> UTCTime
millisecondsToUTCTime ms = posixSecondsToUTCTime (fromRational (ms%1000))

utcTimeToMilliseconds :: UTCTime -> Int
utcTimeToMilliseconds utc = truncate ((utcTimeToPOSIXSeconds utc)*1000)

--

data MinCommand
  = MinCommand
  { minComChannelId :: ChannelId
  , minComCommand   :: Text
  , minComSuggest   :: Bool -- XXX: really?
  } deriving (Read, Show, Eq)

instance A.ToJSON MinCommand where
  toJSON MinCommand { .. } = A.object
    [ "channelId" .= minComChannelId
    , "command"   .= minComCommand
    , "suggest"   .=
      if minComSuggest
        then ("true" :: Text)
        else ("false" :: Text)
    ]

--

data Command
  = Command
  { commandId               :: CommandId
  , commandToken            :: Token
  , commandCreateAt         :: UTCTime
  , commandUpdateAt         :: UTCTime
  , commandDeleteAt         :: UTCTime
  , commandCreatorId        :: UserId
  , commandTeamId           :: TeamId
  , commandTrigger          :: Text
  , commandMethod           :: Text
  , commandUsername         :: Text
  , commandIconURL          :: Text
  , commandAutoComplete     :: Bool
  , commandAutoCompleteDesc :: Text
  , commandAutoCompleteHint :: Text
  , commandDisplayName      :: Text
  , commandDescription      :: Text
  , commandURL              :: Text
  } deriving (Read, Show, Eq)

newtype CommandId = CmdI { unCmdI :: Id }
  deriving (Read, Show, Eq, Ord, Hashable, ToJSON, ToJSONKey, FromJSONKey, FromJSON)

instance IsId CommandId where
  toId   = unCmdI
  fromId = CmdI

instance HasId Command CommandId where
  getId = commandId

--

data UsersCreate
  = UsersCreate
  { usersCreateEmail          :: Text
  , usersCreatePassword       :: Text
  , usersCreateUsername       :: Text
  , usersCreateAllowMarketing :: Bool
  } deriving (Read, Show, Eq)

instance A.ToJSON UsersCreate where
  toJSON UsersCreate { .. } = A.object
    [ "email"           .= usersCreateEmail
    , "allow_marketing" .= usersCreateAllowMarketing
    , "password"        .= usersCreatePassword
    , "username"        .= usersCreateUsername
    ]

--

data TeamsCreate
  = TeamsCreate
  { teamsCreateDisplayName :: Text
  , teamsCreateName        :: Text
  , teamsCreateType        :: Type
  } deriving (Read, Show, Eq)

instance A.ToJSON TeamsCreate where
  toJSON TeamsCreate { .. } = A.object
    [ "display_name" .= teamsCreateDisplayName
    , "name"         .= teamsCreateName
    , "type"         .= teamsCreateType
    ]

--

data Reaction
  = Reaction
  { reactionUserId    :: UserId
  , reactionPostId    :: PostId
  , reactionEmojiName :: Text
  , reactionCreateAt  :: UTCTime
  } deriving (Read, Show, Eq)

instance A.FromJSON Reaction where
  parseJSON = A.withObject "Reaction" $ \v -> do
    reactionUserId    <- v .: "user_id"
    reactionPostId    <- v .: "post_id"
    reactionEmojiName <- v .: "emoji_name"
    reactionCreateAt  <- millisecondsToUTCTime <$> v .: "create_at"
    return Reaction { .. }

instance A.ToJSON Reaction where
  toJSON Reaction {.. } = A.object
    [ "user_id"    .= reactionUserId
    , "post_id"    .= reactionPostId
    , "emoji_name" .= reactionEmojiName
    , "create_at"  .= utcTimeToMilliseconds reactionCreateAt
    ]
