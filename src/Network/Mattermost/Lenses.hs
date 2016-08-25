{-# LANGUAGE RankNTypes #-}

module Network.Mattermost.Lenses
(
  Lens'
-- * Mattermost Types
, cdHostnameL
, cdPortL
, cdAutoCloseL
, cdConnectionCtxL
, cdTokenL
, usernameL
, passwordL
, teamIdL
, teamCreateAtL
, teamUpdateAtL
, teamDeleteAtL
, teamDisplayNameL
, teamNameL
, teamEmailL
, teamTypeL
, teamCompanyNameL
, teamAllowedDomainsL
, teamInviteIdL
, teamAllowOpenInviteL
, channelIdL
, channelCreateAtL
, channelUpdateAtL
, channelDeleteAtL
, channelTeamIdL
, channelTypeL
, channelDisplayNameL
, channelNameL
, channelHeaderL
, channelPurposeL
, channelLastPostAtL
, channelTotalMsgCountL
, channelExtraUpdateAtL
, channelCreatorIdL
, channelDataChannelIdL
, channelDataUserIdL
, channelDataRolesL
, channelDataLastViewedAtL
, channelDataMsgCountL
, channelDataMentionCountL
, channelDataNotifyPropsL
, channelDataLastUpdateAtL
, userProfileEmailL
, userProfileRolesL
, userProfileFirstNameL
, userProfileAuthServiceL
, userProfileLocaleL
, userProfileUsernameL
, userProfileAuthDataL
, userProfileLastNameL
, userProfileIdL
, userProfileNicknameL
, userProfileDeleteAtL
, userProfileCreateAtL
, userIdL
, userCreateAtL
, userUpdateAtL
, userDeleteAtL
, userUsernameL
, userAuthDataL
, userAuthServiceL
, userEmailL
, userEmailVerifiedL
, userNicknameL
, userFirstNameL
, userLastNameL
, userRolesL
, userNotifyPropsL
, userLastPasswordUpdateL
, userLastPictureUpdateL
, userLocaleL
, postPendingPostIdL
, postOriginalIdL
, postPropsL
, postRootIdL
, postFilenamesL
, postIdL
, postTypeL
, postMessageL
, postDeleteAtL
, postHashtagsL
, postUpdateAtL
, postUserIdL
, postCreateAtL
, postParentIdL
, postChannelIdL
, pendingPostChannelIdL
, pendingPostCreateAtL
, pendingPostFilenamesL
, pendingPostMessageL
, pendingPostIdL
, pendingPostUserIdL
, postsPostsL
, postsOrderL
-- * Websocket Types
-- ** WebsocketEvent Lenses
, weTeamIdL
, weEventL
, weUserIdL
, weChannelIdL
, weDataL
-- ** WEProps Lenses
, wepChannelIdL
, wepTeamIdL
, wepSenderNameL
, wepChannelDisplayNameL
, wepPostL
) where

import Data.Aeson (Value)
import Data.HashMap.Strict (HashMap)
import Data.Text (Text)
import Data.Time.Clock (UTCTime)
import Network.Connection (ConnectionContext)

import Network.Mattermost.Types
import Network.Mattermost.WebSocket.Types

-- This is all we need to create a Lens: the type and a trivial
-- @makeLens@ function:

-- This is the same type alias as in @Control.Lens@, and so can be used
-- anywhere lenses are needed.
type Lens' a b = forall f. Functor f => (b -> f b) -> (a -> f a)

-- Create a lens by combining a getter and a setter.
makeLens :: (a -> b) -> (b -> a -> a) -> Lens' a b
makeLens get set f a = (`set` a) `fmap` f (get a)


cdHostnameL :: Lens' ConnectionData Hostname
cdHostnameL = makeLens cdHostname (\ t s -> s { cdHostname = t })

cdPortL :: Lens' ConnectionData Port
cdPortL = makeLens cdPort (\ t s -> s { cdPort = t })

cdAutoCloseL :: Lens' ConnectionData AutoClose
cdAutoCloseL = makeLens cdAutoClose (\ t s -> s { cdAutoClose = t })

cdConnectionCtxL :: Lens' ConnectionData ConnectionContext
cdConnectionCtxL = makeLens cdConnectionCtx (\ t s -> s { cdConnectionCtx = t })

cdTokenL :: Lens' ConnectionData (Maybe Token)
cdTokenL = makeLens cdToken (\ t s -> s { cdToken = t })

--


usernameL :: Lens' Login Text
usernameL = makeLens username (\ t s -> s { username = t })

passwordL :: Lens' Login Text
passwordL = makeLens password (\ t s -> s { password = t })

--


teamIdL :: Lens' Team TeamId
teamIdL = makeLens teamId (\ t s -> s { teamId = t })

teamCreateAtL :: Lens' Team UTCTime
teamCreateAtL = makeLens teamCreateAt (\ t s -> s { teamCreateAt = t })

teamUpdateAtL :: Lens' Team UTCTime
teamUpdateAtL = makeLens teamUpdateAt (\ t s -> s { teamUpdateAt = t })

teamDeleteAtL :: Lens' Team UTCTime
teamDeleteAtL = makeLens teamDeleteAt (\ t s -> s { teamDeleteAt = t })

teamDisplayNameL :: Lens' Team String
teamDisplayNameL = makeLens teamDisplayName (\ t s -> s { teamDisplayName = t })

teamNameL :: Lens' Team String
teamNameL = makeLens teamName (\ t s -> s { teamName = t })

teamEmailL :: Lens' Team String
teamEmailL = makeLens teamEmail (\ t s -> s { teamEmail = t })

teamTypeL :: Lens' Team Type
teamTypeL = makeLens teamType (\ t s -> s { teamType = t })

teamCompanyNameL :: Lens' Team String
teamCompanyNameL = makeLens teamCompanyName (\ t s -> s { teamCompanyName = t })

teamAllowedDomainsL :: Lens' Team String
teamAllowedDomainsL = makeLens teamAllowedDomains (\ t s -> s { teamAllowedDomains = t })

teamInviteIdL :: Lens' Team Id
teamInviteIdL = makeLens teamInviteId (\ t s -> s { teamInviteId = t })

teamAllowOpenInviteL :: Lens' Team Bool
teamAllowOpenInviteL = makeLens teamAllowOpenInvite (\ t s -> s { teamAllowOpenInvite = t })

--


channelIdL :: Lens' Channel ChannelId
channelIdL = makeLens channelId (\ t s -> s { channelId = t })

channelCreateAtL :: Lens' Channel UTCTime
channelCreateAtL = makeLens channelCreateAt (\ t s -> s { channelCreateAt = t })

channelUpdateAtL :: Lens' Channel UTCTime
channelUpdateAtL = makeLens channelUpdateAt (\ t s -> s { channelUpdateAt = t })

channelDeleteAtL :: Lens' Channel UTCTime
channelDeleteAtL = makeLens channelDeleteAt (\ t s -> s { channelDeleteAt = t })

channelTeamIdL :: Lens' Channel TeamId
channelTeamIdL = makeLens channelTeamId (\ t s -> s { channelTeamId = t })

channelTypeL :: Lens' Channel Type
channelTypeL = makeLens channelType (\ t s -> s { channelType = t })

channelDisplayNameL :: Lens' Channel String
channelDisplayNameL =
  makeLens channelDisplayName (\ t s -> s { channelDisplayName = t })

channelNameL :: Lens' Channel String
channelNameL = makeLens channelName (\ t s -> s { channelName = t })

channelHeaderL :: Lens' Channel String
channelHeaderL = makeLens channelHeader (\ t s -> s { channelHeader = t })

channelPurposeL :: Lens' Channel String
channelPurposeL = makeLens channelPurpose (\ t s -> s { channelPurpose = t })

channelLastPostAtL :: Lens' Channel UTCTime
channelLastPostAtL =
  makeLens channelLastPostAt (\ t s -> s { channelLastPostAt = t })

channelTotalMsgCountL :: Lens' Channel Int
channelTotalMsgCountL =
  makeLens channelTotalMsgCount (\ t s -> s { channelTotalMsgCount = t })

channelExtraUpdateAtL :: Lens' Channel UTCTime
channelExtraUpdateAtL =
  makeLens channelExtraUpdateAt (\ t s -> s { channelExtraUpdateAt = t })

channelCreatorIdL :: Lens' Channel UserId
channelCreatorIdL = makeLens channelCreatorId (\ t s -> s { channelCreatorId = t })

--


channelDataChannelIdL :: Lens' ChannelData ChannelId
channelDataChannelIdL = makeLens channelDataChannelId (\ t s -> s { channelDataChannelId = t })

channelDataUserIdL :: Lens' ChannelData UserId
channelDataUserIdL = makeLens channelDataUserId (\ t s -> s { channelDataUserId = t })

channelDataRolesL :: Lens' ChannelData String
channelDataRolesL = makeLens channelDataRoles (\ t s -> s { channelDataRoles = t })

channelDataLastViewedAtL :: Lens' ChannelData UTCTime
channelDataLastViewedAtL = makeLens channelDataLastViewedAt (\ t s -> s { channelDataLastViewedAt = t })

channelDataMsgCountL :: Lens' ChannelData Int
channelDataMsgCountL = makeLens channelDataMsgCount (\ t s -> s { channelDataMsgCount = t })

channelDataMentionCountL :: Lens' ChannelData Int
channelDataMentionCountL = makeLens channelDataMentionCount (\ t s -> s { channelDataMentionCount = t })

channelDataNotifyPropsL :: Lens' ChannelData (HashMap String String)
channelDataNotifyPropsL =
  makeLens channelDataNotifyProps (\ t s -> s { channelDataNotifyProps = t })

channelDataLastUpdateAtL :: Lens' ChannelData UTCTime
channelDataLastUpdateAtL =
  makeLens channelDataLastUpdateAt (\ t s -> s { channelDataLastUpdateAt = t })

--


userProfileEmailL :: Lens' UserProfile String
userProfileEmailL = makeLens userProfileEmail (\ t s -> s { userProfileEmail = t })

userProfileRolesL :: Lens' UserProfile String
userProfileRolesL = makeLens userProfileRoles (\ t s -> s { userProfileRoles = t })

userProfileFirstNameL :: Lens' UserProfile String
userProfileFirstNameL = makeLens userProfileFirstName (\ t s -> s { userProfileFirstName = t })

userProfileAuthServiceL :: Lens' UserProfile String
userProfileAuthServiceL = makeLens userProfileAuthService (\ t s -> s { userProfileAuthService = t })

userProfileLocaleL :: Lens' UserProfile String
userProfileLocaleL = makeLens userProfileLocale (\ t s -> s { userProfileLocale = t })

userProfileUsernameL :: Lens' UserProfile String
userProfileUsernameL = makeLens userProfileUsername (\ t s -> s { userProfileUsername = t })

userProfileAuthDataL :: Lens' UserProfile String
userProfileAuthDataL = makeLens userProfileAuthData (\ t s -> s { userProfileAuthData = t })

userProfileLastNameL :: Lens' UserProfile String
userProfileLastNameL = makeLens userProfileLastName (\ t s -> s { userProfileLastName = t })

userProfileIdL :: Lens' UserProfile UserId
userProfileIdL = makeLens userProfileId (\ t s -> s { userProfileId = t })

userProfileNicknameL :: Lens' UserProfile String
userProfileNicknameL = makeLens userProfileNickname (\ t s -> s { userProfileNickname = t })

userProfileDeleteAtL :: Lens' UserProfile UTCTime
userProfileDeleteAtL = makeLens userProfileDeleteAt (\ t s -> s { userProfileDeleteAt = t })

userProfileCreateAtL :: Lens' UserProfile UTCTime
userProfileCreateAtL = makeLens userProfileCreateAt (\ t s -> s { userProfileCreateAt = t })

--


userIdL :: Lens' User UserId
userIdL = makeLens userId (\ t s -> s { userId = t })

userCreateAtL :: Lens' User UTCTime
userCreateAtL = makeLens userCreateAt (\ t s -> s { userCreateAt = t })

userUpdateAtL :: Lens' User UTCTime
userUpdateAtL = makeLens userUpdateAt (\ t s -> s { userUpdateAt = t })

userDeleteAtL :: Lens' User UTCTime
userDeleteAtL = makeLens userDeleteAt (\ t s -> s { userDeleteAt = t })

userUsernameL :: Lens' User String
userUsernameL = makeLens userUsername (\ t s -> s { userUsername = t })

userAuthDataL :: Lens' User String
userAuthDataL = makeLens userAuthData (\ t s -> s { userAuthData = t })

userAuthServiceL :: Lens' User String
userAuthServiceL = makeLens userAuthService (\ t s -> s { userAuthService = t })

userEmailL :: Lens' User String
userEmailL = makeLens userEmail (\ t s -> s { userEmail = t })

userEmailVerifiedL :: Lens' User Bool
userEmailVerifiedL = makeLens userEmailVerified (\ t s -> s { userEmailVerified = t })

userNicknameL :: Lens' User String
userNicknameL = makeLens userNickname (\ t s -> s { userNickname = t })

userFirstNameL :: Lens' User String
userFirstNameL = makeLens userFirstName (\ t s -> s { userFirstName = t })

userLastNameL :: Lens' User String
userLastNameL = makeLens userLastName (\ t s -> s { userLastName = t })

userRolesL :: Lens' User String
userRolesL = makeLens userRoles (\ t s -> s { userRoles = t })

userNotifyPropsL :: Lens' User (HashMap String String)
userNotifyPropsL = makeLens userNotifyProps (\ t s -> s { userNotifyProps = t })

userLastPasswordUpdateL :: Lens' User UTCTime
userLastPasswordUpdateL = makeLens userLastPasswordUpdate (\ t s -> s { userLastPasswordUpdate = t })

userLastPictureUpdateL :: Lens' User (Maybe UTCTime)
userLastPictureUpdateL = makeLens userLastPictureUpdate (\ t s -> s { userLastPictureUpdate = t })

userLocaleL :: Lens' User String
userLocaleL = makeLens userLocale (\ t s -> s { userLocale = t })

--


postPendingPostIdL :: Lens' Post PostId
postPendingPostIdL = makeLens postPendingPostId (\ t s -> s { postPendingPostId = t })

postOriginalIdL :: Lens' Post PostId
postOriginalIdL = makeLens postOriginalId (\ t s -> s { postOriginalId = t })

postPropsL :: Lens' Post Value
postPropsL = makeLens postProps (\ t s -> s { postProps = t })

postRootIdL :: Lens' Post String
postRootIdL = makeLens postRootId (\ t s -> s { postRootId = t })

postFilenamesL :: Lens' Post Value
postFilenamesL = makeLens postFilenames (\ t s -> s { postFilenames = t })

postIdL :: Lens' Post PostId
postIdL = makeLens postId (\ t s -> s { postId = t })

postTypeL :: Lens' Post Type
postTypeL = makeLens postType (\ t s -> s { postType = t })

postMessageL :: Lens' Post String
postMessageL = makeLens postMessage (\ t s -> s { postMessage = t })

postDeleteAtL :: Lens' Post UTCTime
postDeleteAtL = makeLens postDeleteAt (\ t s -> s { postDeleteAt = t })

postHashtagsL :: Lens' Post String
postHashtagsL = makeLens postHashtags (\ t s -> s { postHashtags = t })

postUpdateAtL :: Lens' Post UTCTime
postUpdateAtL = makeLens postUpdateAt (\ t s -> s { postUpdateAt = t })

postUserIdL :: Lens' Post UserId
postUserIdL = makeLens postUserId (\ t s -> s { postUserId = t })

postCreateAtL :: Lens' Post UTCTime
postCreateAtL = makeLens postCreateAt (\ t s -> s { postCreateAt = t })

postParentIdL :: Lens' Post PostId
postParentIdL = makeLens postParentId (\ t s -> s { postParentId = t })

postChannelIdL :: Lens' Post ChannelId
postChannelIdL = makeLens postChannelId (\ t s -> s { postChannelId = t })

--

pendingPostChannelIdL :: Lens' PendingPost ChannelId
pendingPostChannelIdL = makeLens pendingPostChannelId (\ t s -> s { pendingPostChannelId = t })

pendingPostCreateAtL :: Lens' PendingPost UTCTime
pendingPostCreateAtL = makeLens pendingPostCreateAt (\ t s -> s { pendingPostCreateAt = t })

pendingPostFilenamesL :: Lens' PendingPost [FilePath]
pendingPostFilenamesL = makeLens pendingPostFilenames (\ t s -> s { pendingPostFilenames = t })

pendingPostMessageL :: Lens' PendingPost String
pendingPostMessageL = makeLens pendingPostMessage (\ t s -> s { pendingPostMessage = t })

pendingPostIdL :: Lens' PendingPost PendingPostId
pendingPostIdL = makeLens pendingPostId (\ t s -> s { pendingPostId = t })

pendingPostUserIdL :: Lens' PendingPost UserId
pendingPostUserIdL = makeLens pendingPostUserId (\ t s -> s { pendingPostUserId = t })

--

postsPostsL :: Lens' Posts (HashMap PostId Post)
postsPostsL = makeLens postsPosts (\ t s -> s { postsPosts = t })

postsOrderL :: Lens' Posts [PostId]
postsOrderL = makeLens postsOrder (\ t s -> s { postsOrder = t })

--

weTeamIdL :: Lens' WebsocketEvent TeamId
weTeamIdL = makeLens weTeamId (\ t s -> s { weTeamId = t })

weEventL :: Lens' WebsocketEvent WebsocketEventType
weEventL = makeLens weEvent (\ t s -> s { weEvent = t })

weUserIdL :: Lens' WebsocketEvent UserId
weUserIdL = makeLens weUserId (\ t s -> s { weUserId = t })

weChannelIdL :: Lens' WebsocketEvent ChannelId
weChannelIdL = makeLens weChannelId (\ t s -> s { weChannelId = t })

weDataL :: Lens' WebsocketEvent WEData
weDataL = makeLens weData (\ t s -> s { weData = t })

--

wepChannelIdL :: Lens' WEData (Maybe ChannelId)
wepChannelIdL = makeLens wepChannelId (\ t s -> s { wepChannelId = t })

wepTeamIdL :: Lens' WEData (Maybe TeamId)
wepTeamIdL = makeLens wepTeamId (\ t s -> s { wepTeamId = t })

wepSenderNameL :: Lens' WEData (Maybe Text)
wepSenderNameL = makeLens wepSenderName (\ t s -> s { wepSenderName = t })

wepChannelDisplayNameL :: Lens' WEData (Maybe Text)
wepChannelDisplayNameL = makeLens wepChannelDisplayName
                                  (\ t s -> s { wepChannelDisplayName = t })

wepPostL :: Lens' WEData (Maybe Post)
wepPostL = makeLens wepPost (\ t s -> s { wepPost = t })
