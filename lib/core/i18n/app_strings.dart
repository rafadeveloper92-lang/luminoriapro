import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class AppStrings {
  final Locale locale;
  final Map<String, String> _localizedValues;

  AppStrings(this.locale, this._localizedValues);

  static AppStrings? of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings);
  }

  static const LocalizationsDelegate<AppStrings> delegate = _AppStringsDelegate();

  // ---------------------------------------------------------------------------
  // GETTERS
  // ---------------------------------------------------------------------------

  String get lotusIptv => _localizedValues['lotusIptv']!;
  String get professionalIptvPlayer => _localizedValues['professionalIptvPlayer']!;
  String get loading => _localizedValues['loading']!;
  String get error => _localizedValues['error']!;
  String get success => _localizedValues['success']!;
  String get cancel => _localizedValues['cancel']!;
  String get delete => _localizedValues['delete']!;
  String get save => _localizedValues['save']!;
  String get close => _localizedValues['close']!;
  String get more => _localizedValues['more']!;
  String get search => _localizedValues['search']!;
  String get unknown => _localizedValues['unknown']!;
  String get processing => _localizedValues['processing']!;
  String get apply => _localizedValues['apply']!;
  String get or => _localizedValues['or']!;
  String get playlistManager => _localizedValues['playlistManager']!;
  String get playlistList => _localizedValues['playlistList']!;
  String get goToHomeToAdd => _localizedValues['goToHomeToAdd']!;
  String get addNewPlaylist => _localizedValues['addNewPlaylist']!;
  String get playlistName => _localizedValues['playlistName']!;
  String get playlistUrl => _localizedValues['playlistUrl']!;
  String get addFromUrl => _localizedValues['addFromUrl']!;
  String get fromFile => _localizedValues['fromFile']!;
  String get importing => _localizedValues['importing']!;
  String get noPlaylists => _localizedValues['noPlaylists']!;
  String get deletePlaylist => _localizedValues['deletePlaylist']!;
  String get deleteConfirmation => _localizedValues['deleteConfirmation']!;
  String get pleaseEnterPlaylistName => _localizedValues['pleaseEnterPlaylistName']!;
  String get pleaseEnterPlaylistUrl => _localizedValues['pleaseEnterPlaylistUrl']!;
  String get playlistAdded => _localizedValues['playlistAdded']!;
  String get playlistRefreshed => _localizedValues['playlistRefreshed']!;
  String get playlistRefreshFailed => _localizedValues['playlistRefreshFailed']!;
  String get playlistDeleted => _localizedValues['playlistDeleted']!;
  String get playlistImported => _localizedValues['playlistImported']!;
  String get errorPickingFile => _localizedValues['errorPickingFile']!;
  String get managePlaylists => _localizedValues['managePlaylists']!;
  String get noPlaylistsYet => _localizedValues['noPlaylistsYet']!;
  String get addFirstPlaylistHint => _localizedValues['addFirstPlaylistHint']!;
  String get addPlaylist => _localizedValues['addPlaylist']!;
  String get scanToImport => _localizedValues['scanToImport']!;
  String get playlistUrlHint => _localizedValues['playlistUrlHint']!;
  String get selectM3uFile => _localizedValues['selectM3uFile']!;
  String get noFileSelected => _localizedValues['noFileSelected']!;
  String get addFirstPlaylistTV => _localizedValues['addFirstPlaylistTV']!;
  String get importingPlaylist => _localizedValues['importingPlaylist']!;
  String get importSuccess => _localizedValues['importSuccess']!;
  String get importFailed => _localizedValues['importFailed']!;
  String get serverStartFailed => _localizedValues['serverStartFailed']!;
  String get startingServer => _localizedValues['startingServer']!;
  String get scanQrToImport => _localizedValues['scanQrToImport']!;
  String get qrStep1 => _localizedValues['qrStep1']!;
  String get qrStep2 => _localizedValues['qrStep2']!;
  String get qrStep3 => _localizedValues['qrStep3']!;
  String get playlistNameOptional => _localizedValues['playlistNameOptional']!;
  String get fileNameOptional => _localizedValues['fileNameOptional']!;
  String get enterPlaylistUrl => _localizedValues['enterPlaylistUrl']!;
  String get importUrlButton => _localizedValues['importUrlButton']!;
  String get selectFile => _localizedValues['selectFile']!;
  String get fileUploadButton => _localizedValues['fileUploadButton']!;
  String get pleaseEnterUrl => _localizedValues['pleaseEnterUrl']!;
  String get sentToTV => _localizedValues['sentToTV']!;
  String get sendFailed => _localizedValues['sendFailed']!;
  String get networkError => _localizedValues['networkError']!;
  String get uploading => _localizedValues['uploading']!;
  String get importPlaylistTitle => _localizedValues['importPlaylistTitle']!;
  String get importPlaylistSubtitle => _localizedValues['importPlaylistSubtitle']!;
  String get importFromUrlTitle => _localizedValues['importFromUrlTitle']!;
  String get importFromFileTitle => _localizedValues['importFromFileTitle']!;
  String get importFromUsb => _localizedValues['importFromUsb']!;
  String get addPlaylistSubtitle => _localizedValues['addPlaylistSubtitle']!;
  String get localFile => _localizedValues['localFile']!;
  String get channels => _localizedValues['channels']!;
  String get allChannels => _localizedValues['allChannels']!;
  String get noChannelsFound => _localizedValues['noChannelsFound']!;
  String get channelInfo => _localizedValues['channelInfo']!;
  String get totalChannels => _localizedValues['totalChannels']!;
  String get categories => _localizedValues['categories']!;
  String get testChannel => _localizedValues['testChannel']!;
  String get unavailable => _localizedValues['unavailable']!;
  String get searchChannels => _localizedValues['searchChannels']!;
  String get searchHint => _localizedValues['searchHint']!;
  String get typeToSearch => _localizedValues['typeToSearch']!;
  String get popularCategories => _localizedValues['popularCategories']!;
  String get sports => _localizedValues['sports']!;
  String get movies => _localizedValues['movies']!;
  String get news => _localizedValues['news']!;
  String get music => _localizedValues['music']!;
  String get kids => _localizedValues['kids']!;
  String get noResultsFound => _localizedValues['noResultsFound']!;
  String get noChannelsMatch => _localizedValues['noChannelsMatch']!;
  String get resultsFor => _localizedValues['resultsFor']!;
  String get scanToSearch => _localizedValues['scanToSearch']!;
  String get qrSearchStep1 => _localizedValues['qrSearchStep1']!;
  String get qrSearchStep2 => _localizedValues['qrSearchStep2']!;
  String get qrSearchStep3 => _localizedValues['qrSearchStep3']!;
  String get favorites => _localizedValues['favorites']!;
  String get addFavorites => _localizedValues['addFavorites']!;
  String get removeFavorites => _localizedValues['removeFavorites']!;
  String get clearAll => _localizedValues['clearAll']!;
  String get noFavoritesYet => _localizedValues['noFavoritesYet']!;
  String get favoritesHint => _localizedValues['favoritesHint']!;
  String get browseChannels => _localizedValues['browseChannels']!;
  String get removedFromFavorites => _localizedValues['removedFromFavorites']!;
  String get undo => _localizedValues['undo']!;
  String get clearAllFavorites => _localizedValues['clearAllFavorites']!;
  String get clearFavoritesConfirm => _localizedValues['clearFavoritesConfirm']!;
  String get allFavoritesCleared => _localizedValues['allFavoritesCleared']!;
  String get myFavorites => _localizedValues['myFavorites']!;
  String get playback => _localizedValues['playback']!;
  String get live => _localizedValues['live']!;
  String get buffering => _localizedValues['buffering']!;
  String get paused => _localizedValues['paused']!;
  String get playbackError => _localizedValues['playbackError']!;
  String get retry => _localizedValues['retry']!;
  String get goBack => _localizedValues['goBack']!;
  String get playbackSettings => _localizedValues['playbackSettings']!;
  String get playbackSpeed => _localizedValues['playbackSpeed']!;
  String get shortcutsHint => _localizedValues['shortcutsHint']!;
  String get nextChannel => _localizedValues['nextChannel']!;
  String get previousChannel => _localizedValues['previousChannel']!;
  String get source => _localizedValues['source']!;
  String get nowPlaying => _localizedValues['nowPlaying']!;
  String get endsInMinutes => _localizedValues['endsInMinutes']!;
  String get upNext => _localizedValues['upNext']!;
  String get playerHintTV => _localizedValues['playerHintTV']!;
  String get playerHintDesktop => _localizedValues['playerHintDesktop']!;
  String get settings => _localizedValues['settings']!;
  String get language => _localizedValues['language']!;
  String get general => _localizedValues['general']!;
  String get theme => _localizedValues['theme']!;
  String get active => _localizedValues['active']!;
  String get refresh => _localizedValues['refresh']!;
  String get updated => _localizedValues['updated']!;
  String get version => _localizedValues['version']!;
  String get autoPlay => _localizedValues['autoPlay']!;
  String get autoPlaySubtitle => _localizedValues['autoPlaySubtitle']!;
  String get hardwareDecoding => _localizedValues['hardwareDecoding']!;
  String get hardwareDecodingSubtitle => _localizedValues['hardwareDecodingSubtitle']!;
  String get bufferSize => _localizedValues['bufferSize']!;
  String get seconds => _localizedValues['seconds']!;
  String get playlists => _localizedValues['playlists']!;
  String get autoRefresh => _localizedValues['autoRefresh']!;
  String get autoRefreshSubtitle => _localizedValues['autoRefreshSubtitle']!;
  String get refreshInterval => _localizedValues['refreshInterval']!;
  String get hours => _localizedValues['hours']!;
  String get days => _localizedValues['days']!;
  String get day => _localizedValues['day']!;
  String get rememberLastChannel => _localizedValues['rememberLastChannel']!;
  String get rememberLastChannelSubtitle => _localizedValues['rememberLastChannelSubtitle']!;
  String get epg => _localizedValues['epg']!;
  String get enableEpg => _localizedValues['enableEpg']!;
  String get enableEpgSubtitle => _localizedValues['enableEpgSubtitle']!;
  String get epgUrl => _localizedValues['epgUrl']!;
  String get notConfigured => _localizedValues['notConfigured']!;
  String get parentalControl => _localizedValues['parentalControl']!;
  String get enableParentalControl => _localizedValues['enableParentalControl']!;
  String get enableParentalControlSubtitle => _localizedValues['enableParentalControlSubtitle']!;
  String get changePin => _localizedValues['changePin']!;
  String get changePinSubtitle => _localizedValues['changePinSubtitle']!;
  String get about => _localizedValues['about']!;
  String get platform => _localizedValues['platform']!;
  String get resetAllSettings => _localizedValues['resetAllSettings']!;
  String get resetSettingsSubtitle => _localizedValues['resetSettingsSubtitle']!;
  String get enterEpgUrl => _localizedValues['enterEpgUrl']!;
  String get setPin => _localizedValues['setPin']!;
  String get enterPin => _localizedValues['enterPin']!;
  String get resetSettings => _localizedValues['resetSettings']!;
  String get resetConfirm => _localizedValues['resetConfirm']!;
  String get reset => _localizedValues['reset']!;
  String get bufferStrength => _localizedValues['bufferStrength']!;
  String get showFps => _localizedValues['showFps']!;
  String get showFpsSubtitle => _localizedValues['showFpsSubtitle']!;
  String get showClock => _localizedValues['showClock']!;
  String get showClockSubtitle => _localizedValues['showClockSubtitle']!;
  String get showNetworkSpeed => _localizedValues['showNetworkSpeed']!;
  String get showNetworkSpeedSubtitle => _localizedValues['showNetworkSpeedSubtitle']!;
  String get showVideoInfo => _localizedValues['showVideoInfo']!;
  String get showVideoInfoSubtitle => _localizedValues['showVideoInfoSubtitle']!;
  String get enableMultiScreen => _localizedValues['enableMultiScreen']!;
  String get enableMultiScreenSubtitle => _localizedValues['enableMultiScreenSubtitle']!;
  String get showMultiScreenChannelName => _localizedValues['showMultiScreenChannelName']!;
  String get showMultiScreenChannelNameSubtitle => _localizedValues['showMultiScreenChannelNameSubtitle']!;
  String get defaultScreenPosition => _localizedValues['defaultScreenPosition']!;
  String get screenPositionDesc => _localizedValues['screenPositionDesc']!;
  String get followSystem => _localizedValues['followSystem']!;
  String get languageFollowSystem => _localizedValues['languageFollowSystem']!;
  String get themeDark => _localizedValues['themeDark']!;
  String get themeLight => _localizedValues['themeLight']!;
  String get themeSystem => _localizedValues['themeSystem']!;
  String get themeChanged => _localizedValues['themeChanged']!;
  String get fontFamily => _localizedValues['fontFamily']!;
  String get fontFamilyDesc => _localizedValues['fontFamilyDesc']!;
  String get fontChanged => _localizedValues['fontChanged']!;
  String get noProgramInfo => _localizedValues['noProgramInfo']!;
  String get chinese => _localizedValues['chinese']!;
  String get english => _localizedValues['english']!;
  String get languageSwitchedToChinese => _localizedValues['languageSwitchedToChinese']!;
  String get languageSwitchedToEnglish => _localizedValues['languageSwitchedToEnglish']!;
  String get themeChangedMessage => _localizedValues['themeChangedMessage']!;
  String get simpleMenu => _localizedValues['simpleMenu']!;
  String get simpleMenuSubtitle => _localizedValues['simpleMenuSubtitle']!;
  String get simpleMenuEnabled => _localizedValues['simpleMenuEnabled']!;
  String get simpleMenuDisabled => _localizedValues['simpleMenuDisabled']!;
  String get autoPlayEnabled => _localizedValues['autoPlayEnabled']!;
  String get autoPlayDisabled => _localizedValues['autoPlayDisabled']!;
  String get decodingMode => _localizedValues['decodingMode']!;
  String get fpsEnabled => _localizedValues['fpsEnabled']!;
  String get fpsDisabled => _localizedValues['fpsDisabled']!;
  String get clockEnabled => _localizedValues['clockEnabled']!;
  String get clockDisabled => _localizedValues['clockDisabled']!;
  String get networkSpeedEnabled => _localizedValues['networkSpeedEnabled']!;
  String get networkSpeedDisabled => _localizedValues['networkSpeedDisabled']!;
  String get videoInfoEnabled => _localizedValues['videoInfoEnabled']!;
  String get videoInfoDisabled => _localizedValues['videoInfoDisabled']!;
  String get progressBarMode => _localizedValues['progressBarMode']!;
  String get multiScreenEnabled => _localizedValues['multiScreenEnabled']!;
  String get multiScreenDisabled => _localizedValues['multiScreenDisabled']!;
  String get multiScreenChannelNameEnabled => _localizedValues['multiScreenChannelNameEnabled']!;
  String get multiScreenChannelNameDisabled => _localizedValues['multiScreenChannelNameDisabled']!;
  String get volumeBoost => _localizedValues['volumeBoost']!;
  String get noBoost => _localizedValues['noBoost']!;
  String get rememberLastChannelEnabled => _localizedValues['rememberLastChannelEnabled']!;
  String get rememberLastChannelDisabled => _localizedValues['rememberLastChannelDisabled']!;
  String get epgEnabledAndLoaded => _localizedValues['epgEnabledAndLoaded']!;
  String get epgEnabledButFailed => _localizedValues['epgEnabledButFailed']!;
  String get epgEnabledPleaseConfigure => _localizedValues['epgEnabledPleaseConfigure']!;
  String get epgDisabled => _localizedValues['epgDisabled']!;
  String get dlnaCasting => _localizedValues['dlnaCasting']!;
  String get enableDlnaService => _localizedValues['enableDlnaService']!;
  String get dlnaServiceStarted => _localizedValues['dlnaServiceStarted']!;
  String get allowOtherDevicesToCast => _localizedValues['allowOtherDevicesToCast']!;
  String get dlnaServiceStartedMsg => _localizedValues['dlnaServiceStartedMsg']!;
  String get dlnaServiceStoppedMsg => _localizedValues['dlnaServiceStoppedMsg']!;
  String get dlnaServiceStartFailed => _localizedValues['dlnaServiceStartFailed']!;
  String get developerAndDebug => _localizedValues['developerAndDebug']!;
  String get logLevel => _localizedValues['logLevel']!;
  String get exportLogs => _localizedValues['exportLogs']!;
  String get exportLogsSubtitle => _localizedValues['exportLogsSubtitle']!;
  String get clearLogs => _localizedValues['clearLogs']!;
  String get clearLogsSubtitle => _localizedValues['clearLogsSubtitle']!;
  String get logFileLocation => _localizedValues['logFileLocation']!;
  String get checkUpdate => _localizedValues['checkUpdate']!;
  String get checkUpdateSubtitle => _localizedValues['checkUpdateSubtitle']!;
  String get checkingUpdate => _localizedValues['checkingUpdate']!;
  String get launcherCheckingResources => _localizedValues['launcherCheckingResources']!;
  String get launcherDownloadingUpdate => _localizedValues['launcherDownloadingUpdate']!;
  String get launcherSyncingAccount => _localizedValues['launcherSyncingAccount']!;
  String get launcherReady => _localizedValues['launcherReady']!;
  String get launcherEnter => _localizedValues['launcherEnter']!;
  String get colorScheme => _localizedValues['colorScheme']!;
  String get selectColorScheme => _localizedValues['selectColorScheme']!;
  String get customColorPicker => _localizedValues['customColorPicker']!;
  String get colorSchemeChanged => _localizedValues['colorSchemeChanged']!;
  String get colorSchemeCustom => _localizedValues['colorSchemeCustom']!;
  String get colorSchemeLotus => _localizedValues['colorSchemeLotus']!;
  String get colorSchemeOcean => _localizedValues['colorSchemeOcean']!;
  String get colorSchemeForest => _localizedValues['colorSchemeForest']!;
  String get colorSchemeSunset => _localizedValues['colorSchemeSunset']!;
  String get colorSchemeLavender => _localizedValues['colorSchemeLavender']!;
  String get colorSchemeMidnight => _localizedValues['colorSchemeMidnight']!;
  String get colorSchemeLotusLight => _localizedValues['colorSchemeLotusLight']!;
  String get colorSchemeSky => _localizedValues['colorSchemeSky']!;
  String get colorSchemeSpring => _localizedValues['colorSchemeSpring']!;
  String get colorSchemeCoral => _localizedValues['colorSchemeCoral']!;
  String get colorSchemeViolet => _localizedValues['colorSchemeViolet']!;
  String get colorSchemeClassic => _localizedValues['colorSchemeClassic']!;
  String get colorSchemeDescLotus => _localizedValues['colorSchemeDescLotus']!;
  String get colorSchemeDescOcean => _localizedValues['colorSchemeDescOcean']!;
  String get colorSchemeDescForest => _localizedValues['colorSchemeDescForest']!;
  String get colorSchemeDescSunset => _localizedValues['colorSchemeDescSunset']!;
  String get colorSchemeDescLavender => _localizedValues['colorSchemeDescLavender']!;
  String get colorSchemeDescMidnight => _localizedValues['colorSchemeDescMidnight']!;
  String get colorSchemeDescLotusLight => _localizedValues['colorSchemeDescLotusLight']!;
  String get colorSchemeDescSky => _localizedValues['colorSchemeDescSky']!;
  String get colorSchemeDescSpring => _localizedValues['colorSchemeDescSpring']!;
  String get colorSchemeDescCoral => _localizedValues['colorSchemeDescCoral']!;
  String get colorSchemeDescViolet => _localizedValues['colorSchemeDescViolet']!;
  String get colorSchemeDescClassic => _localizedValues['colorSchemeDescClassic']!;
  String get decodingModeHardware => _localizedValues['decodingModeHardware']!;
  String get decodingModeSoftware => _localizedValues['decodingModeSoftware']!;
  String get decodingModeAuto => _localizedValues['decodingModeAuto']!;
  String get decodingModeSet => _localizedValues['decodingModeSet']!;
  String get decodingModeHardwareDesc => _localizedValues['decodingModeHardwareDesc']!;
  String get decodingModeSoftwareDesc => _localizedValues['decodingModeSoftwareDesc']!;
  String get decodingModeAutoDesc => _localizedValues['decodingModeAutoDesc']!;
  String get fastBuffer => _localizedValues['fastBuffer']!;
  String get balancedBuffer => _localizedValues['balancedBuffer']!;
  String get stableBuffer => _localizedValues['stableBuffer']!;
  String get progressBarModeAuto => _localizedValues['progressBarModeAuto']!;
  String get progressBarModeAlways => _localizedValues['progressBarModeAlways']!;
  String get progressBarModeNever => _localizedValues['progressBarModeNever']!;
  String get progressBarModeAutoDesc => _localizedValues['progressBarModeAutoDesc']!;
  String get progressBarModeAlwaysDesc => _localizedValues['progressBarModeAlwaysDesc']!;
  String get progressBarModeNeverDesc => _localizedValues['progressBarModeNeverDesc']!;
  String get progressBarModeSet => _localizedValues['progressBarModeSet']!;
  String get noBoostValue => _localizedValues['noBoostValue']!;
  String get volumeBoostSet => _localizedValues['volumeBoostSet']!;
  String get volumeBoostLow => _localizedValues['volumeBoostLow']!;
  String get volumeBoostSlightLow => _localizedValues['volumeBoostSlightLow']!;
  String get volumeBoostNormal => _localizedValues['volumeBoostNormal']!;
  String get volumeBoostSlightHigh => _localizedValues['volumeBoostSlightHigh']!;
  String get volumeBoostHigh => _localizedValues['volumeBoostHigh']!;
  String get epgUrlSavedAndLoaded => _localizedValues['epgUrlSavedAndLoaded']!;
  String get epgUrlSavedButFailed => _localizedValues['epgUrlSavedButFailed']!;
  String get epgUrlCleared => _localizedValues['epgUrlCleared']!;
  String get epgUrlSaved => _localizedValues['epgUrlSaved']!;
  String get allSettingsReset => _localizedValues['allSettingsReset']!;
  String get logLevelDebug => _localizedValues['logLevelDebug']!;
  String get logLevelRelease => _localizedValues['logLevelRelease']!;
  String get logLevelOff => _localizedValues['logLevelOff']!;
  String get logLevelDebugDesc => _localizedValues['logLevelDebugDesc']!;
  String get logLevelReleaseDesc => _localizedValues['logLevelReleaseDesc']!;
  String get logLevelOffDesc => _localizedValues['logLevelOffDesc']!;
  String get screenPosition1 => _localizedValues['screenPosition1']!;
  String get screenPosition2 => _localizedValues['screenPosition2']!;
  String get screenPosition3 => _localizedValues['screenPosition3']!;
  String get screenPosition4 => _localizedValues['screenPosition4']!;
  String get screenPositionSet => _localizedValues['screenPositionSet']!;
  String get backToPlayer => _localizedValues['backToPlayer']!;
  String get miniMode => _localizedValues['miniMode']!;
  String get exitMultiScreen => _localizedValues['exitMultiScreen']!;
  String get screenNumber => _localizedValues['screenNumber']!;
  String get clickToAddChannel => _localizedValues['clickToAddChannel']!;
  String get selectedColor => _localizedValues['selectedColor']!;
  String get customColorApplied => _localizedValues['customColorApplied']!;
  String get newVersionAvailable => _localizedValues['newVersionAvailable']!;
  String get whatsNew => _localizedValues['whatsNew']!;
  String get updateLater => _localizedValues['updateLater']!;
  String get updateNow => _localizedValues['updateNow']!;
  String get downloadComplete => _localizedValues['downloadComplete']!;
  String get logsCleared => _localizedValues['logsCleared']!;
  String get clearLogsConfirm => _localizedValues['clearLogsConfirm']!;
  String get clearLogsConfirmMessage => _localizedValues['clearLogsConfirmMessage']!;
  String get home => _localizedValues['home']!;
  String get watchHistory => _localizedValues['watchHistory']!;
  String get recommendedChannels => _localizedValues['recommendedChannels']!;
  String get continueWatching => _localizedValues['continueWatching']!;
  String get channelStats => _localizedValues['channelStats']!;
  String get noPlaylistYet => _localizedValues['noPlaylistYet']!;
  String get addM3uToStart => _localizedValues['addM3uToStart']!;
  String get minutesAgo => _localizedValues['minutesAgo']!;
  String get hoursAgo => _localizedValues['hoursAgo']!;
  String get daysAgo => _localizedValues['daysAgo']!;
  String get epgAutoApplied => _localizedValues['epgAutoApplied']!;

  // Social / friends / profile / chat
  String get chat => _localizedValues['chat']!;
  String get removeFriend => _localizedValues['removeFriend']!;
  String get sendFriendRequest => _localizedValues['sendFriendRequest']!;
  String get noMessagesYet => _localizedValues['noMessagesYet']!;
  String get viewFullProfile => _localizedValues['viewFullProfile']!;
  String get removeFromFavorites => _localizedValues['removeFromFavorites']!;
  String get requestSent => _localizedValues['requestSent']!;
  String get couldNotSendRequest => _localizedValues['couldNotSendRequest']!;
  String get deleteFriendConfirm => _localizedValues['deleteFriendConfirm']!;
  String get deleteFriendConfirmMessage => _localizedValues['deleteFriendConfirmMessage']!;
  String get loadFailed => _localizedValues['loadFailed']!;
  String get friendCountLabel => _localizedValues['friendCountLabel']!;
  String get friendsCountLabel => _localizedValues['friendsCountLabel']!;
  String get addFriend => _localizedValues['addFriend']!;
  String get pending => _localizedValues['pending']!;
  String get suggestMovie => _localizedValues['suggestMovie']!;
  String get messageHint => _localizedValues['messageHint']!;
  String get routeNotDefined => _localizedValues['routeNotDefined']!;
  String get noTitle => _localizedValues['noTitle']!;
  String get profileLabel => _localizedValues['profileLabel']!;
  String get acceptLabel => _localizedValues['acceptLabel']!;
  String get rejectLabel => _localizedValues['rejectLabel']!;
  String get userLabel => _localizedValues['userLabel']!;
  String get filterAll => _localizedValues['filterAll']!;
  String get filterOnline => _localizedValues['filterOnline']!;
  String get filterPending => _localizedValues['filterPending']!;
  String get myProfile => _localizedValues['myProfile']!;
  String get myFriendsCount => _localizedValues['myFriendsCount']!;
  String get noPendingRequests => _localizedValues['noPendingRequests']!;
  String get noFriendsFound => _localizedValues['noFriendsFound']!;

  // Accessor to safely get string or key
  String operator [](String key) => _localizedValues[key] ?? key;
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh', 'pt'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) {
    return SynchronousFuture<AppStrings>(
        AppStrings(locale, _getValues(locale)));
  }

  @override
  bool shouldReload(_AppStringsDelegate old) => false;

  Map<String, String> _getValues(Locale locale) {
    if (locale.languageCode == 'zh') return _zhValues;
    if (locale.languageCode == 'pt') return _ptBrValues;
    return _enValues;
  }

  static const Map<String, String> _zhValues = {
    'lotusIptv': 'Luminora',
    'professionalIptvPlayer': '专业 IPTV 播放器',
    'loading': '加载中...',
    'error': '错误',
    'success': '成功',
    'cancel': '取消',
    'delete': '删除',
    'save': '保存',
    'close': '关闭',
    'more': '更多',
    'search': '搜索',
    'unknown': '未知',
    'processing': '正在处理...',
    'apply': '应用',
    'or': '或者',
    'playlistManager': '播放列表管理',
    'playlistList': '直播源',
    'goToHomeToAdd': '前往首页添加播放列表',
    'addNewPlaylist': '添加新播放列表',
    'playlistName': '播放列表名称',
    'playlistUrl': 'M3U/M3U8/TXT 链接',
    'addFromUrl': '从链接添加',
    'fromFile': '从文件导入',
    'importing': '导入中...',
    'noPlaylists': '暂无播放列表',
    'deletePlaylist': '删除播放列表',
    'deleteConfirmation': '确定要删除 "{name}" 吗？',
    'pleaseEnterPlaylistName': '请输入播放列表名称',
    'pleaseEnterPlaylistUrl': '请输入播放列表链接',
    'playlistAdded': '已添加播放列表',
    'playlistRefreshed': '播放列表刷新成功',
    'playlistRefreshFailed': '播放列表刷新失败',
    'playlistDeleted': '播放列表已删除',
    'playlistImported': '播放列表导入成功',
    'errorPickingFile': '选择文件出错',
    'managePlaylists': '管理播放列表',
    'noPlaylistsYet': '暂无播放列表',
    'addFirstPlaylistHint': '添加您的第一个播放列表',
    'addPlaylist': '添加播放列表',
    'scanToImport': '扫码导入',
    'playlistUrlHint': '链接提示',
    'selectM3uFile': '选择 M3U 文件',
    'noFileSelected': '未选择文件',
    'addFirstPlaylistTV': '通过 TV 添加',
    'importingPlaylist': '正在导入...',
    'importSuccess': '导入成功',
    'importFailed': '导入失败',
    'serverStartFailed': '服务器启动失败',
    'startingServer': '启动中...',
    'scanQrToImport': '扫码导入',
    'qrStep1': '步骤 1',
    'qrStep2': '步骤 2',
    'qrStep3': '步骤 3',
    'playlistNameOptional': '名称 (可选)',
    'fileNameOptional': '文件名 (可选)',
    'enterPlaylistUrl': '输入链接',
    'importUrlButton': '导入',
    'selectFile': '选择文件',
    'fileUploadButton': '上传',
    'pleaseEnterUrl': '请输入链接',
    'sentToTV': '已发送到 TV',
    'sendFailed': '发送失败',
    'networkError': '网络错误',
    'uploading': '上传中...',
    'importPlaylistTitle': '导入播放列表',
    'importPlaylistSubtitle': '副标题',
    'importFromUrlTitle': '链接导入',
    'importFromFileTitle': '文件导入',
    'importFromUsb': 'USB 导入',
    'addPlaylistSubtitle': '添加副标题',
    'localFile': '本地文件',
    'channels': '频道',
    'allChannels': '所有频道',
    'noChannelsFound': '未找到频道',
    'channelInfo': '信息',
    'totalChannels': '总计',
    'categories': '分类',
    'testChannel': '测试',
    'unavailable': '不可用',
    'searchChannels': '搜索',
    'searchHint': '提示',
    'typeToSearch': '输入...',
    'popularCategories': '热门',
    'sports': '体育',
    'movies': '电影',
    'news': '新闻',
    'music': '音乐',
    'kids': '少儿',
    'noResultsFound': '无结果',
    'noChannelsMatch': '无匹配',
    'resultsFor': '结果',
    'scanToSearch': '扫码搜索',
    'qrSearchStep1': '搜索 1',
    'qrSearchStep2': '搜索 2',
    'qrSearchStep3': '搜索 3',
    'favorites': '收藏',
    'addFavorites': '添加',
    'removeFavorites': '移除',
    'clearAll': '清空',
    'noFavoritesYet': '暂无收藏',
    'favoritesHint': '提示',
    'browseChannels': '浏览',
    'removedFromFavorites': '已移除',
    'undo': '撤销',
    'clearAllFavorites': '清空',
    'clearFavoritesConfirm': '确定?',
    'allFavoritesCleared': '已清空',
    'myFavorites': '我的收藏',
    'playback': '播放',
    'live': '直播',
    'buffering': '缓冲中...',
    'paused': '暂停',
    'playbackError': '错误',
    'retry': '重试',
    'goBack': '返回',
    'playbackSettings': '设置',
    'playbackSpeed': '速度',
    'shortcutsHint': '快捷键',
    'nextChannel': '下一个',
    'previousChannel': '上一个',
    'source': '源',
    'nowPlaying': '正在播放',
    'endsInMinutes': '结束',
    'upNext': '即将',
    'playerHintTV': 'TV 提示',
    'playerHintDesktop': '桌面提示',
    'settings': '设置',
    'language': '语言',
    'general': '通用',
    'theme': '主题',
    'active': '激活',
    'refresh': '刷新',
    'updated': '更新',
    'version': '版本',
    'autoPlay': '自动播放',
    'autoPlaySubtitle': '副标题',
    'hardwareDecoding': '硬解',
    'hardwareDecodingSubtitle': '副标题',
    'bufferSize': '缓冲',
    'seconds': '秒',
    'playlists': '播放列表',
    'autoRefresh': '自动刷新',
    'autoRefreshSubtitle': '副标题',
    'refreshInterval': '间隔',
    'hours': '小时',
    'days': '天',
    'day': '天',
    'rememberLastChannel': '记忆',
    'rememberLastChannelSubtitle': '副标题',
    'epg': 'EPG',
    'enableEpg': '启用',
    'enableEpgSubtitle': '副标题',
    'epgUrl': 'EPG 链接',
    'notConfigured': '未配置',
    'parentalControl': '家长',
    'enableParentalControl': '启用',
    'enableParentalControlSubtitle': '副标题',
    'changePin': '修改 PIN',
    'changePinSubtitle': '副标题',
    'about': '关于',
    'platform': '平台',
    'resetAllSettings': '全部重置',
    'resetSettingsSubtitle': '副标题',
    'enterEpgUrl': '输入 URL',
    'setPin': '设置 PIN',
    'enterPin': '输入 PIN',
    'resetSettings': '重置',
    'resetConfirm': '确定?',
    'reset': '重置',
    'bufferStrength': '缓冲',
    'showFps': 'FPS',
    'showFpsSubtitle': '副标题',
    'showClock': '时钟',
    'showClockSubtitle': '副标题',
    'showNetworkSpeed': '网速',
    'showNetworkSpeedSubtitle': '副标题',
    'showVideoInfo': '视频信息',
    'showVideoInfoSubtitle': '副标题',
    'enableMultiScreen': '多屏',
    'enableMultiScreenSubtitle': '副标题',
    'showMultiScreenChannelName': '名称',
    'showMultiScreenChannelNameSubtitle': '副标题',
    'defaultScreenPosition': '位置',
    'screenPositionDesc': '描述',
    'followSystem': '系统',
    'languageFollowSystem': '系统语言',
    'themeDark': '深色',
    'themeLight': '浅色',
    'themeSystem': '系统',
    'themeChanged': '已更改',
    'fontFamily': '字体',
    'fontFamilyDesc': '描述',
    'fontChanged': '已更改',
    'noProgramInfo': '无信息',
    'chinese': '中文',
    'english': '英语',
    'languageSwitchedToChinese': '已切到中文',
    'languageSwitchedToEnglish': '已切到英语',
    'themeChangedMessage': '消息',
    'simpleMenu': '简易菜单',
    'simpleMenuSubtitle': '副标题',
    'simpleMenuEnabled': '启用',
    'simpleMenuDisabled': '禁用',
    'autoPlayEnabled': '启用',
    'autoPlayDisabled': '禁用',
    'decodingMode': '解码模式',
    'fpsEnabled': '启用',
    'fpsDisabled': '禁用',
    'clockEnabled': '启用',
    'clockDisabled': '禁用',
    'networkSpeedEnabled': '启用',
    'networkSpeedDisabled': '禁用',
    'videoInfoEnabled': '启用',
    'videoInfoDisabled': '禁用',
    'progressBarMode': '进度条',
    'multiScreenEnabled': '启用',
    'multiScreenDisabled': '禁用',
    'multiScreenChannelNameEnabled': '启用',
    'multiScreenChannelNameDisabled': '禁用',
    'volumeBoost': '增益',
    'noBoost': '无',
    'rememberLastChannelEnabled': '启用',
    'rememberLastChannelDisabled': '禁用',
    'epgEnabledAndLoaded': '成功',
    'epgEnabledButFailed': '失败',
    'epgEnabledPleaseConfigure': '失败',
    'epgDisabled': '关闭',
    'dlnaCasting': 'DLNA',
    'enableDlnaService': '开启',
    'dlnaServiceStarted': '成功',
    'allowOtherDevicesToCast': '允许',
    'dlnaServiceStartedMsg': '成功',
    'dlnaServiceStoppedMsg': '关闭',
    'dlnaServiceStartFailed': '失败',
    'developerAndDebug': '开发者',
    'logLevel': '日志',
    'exportLogs': '导出',
    'exportLogsSubtitle': '副标题',
    'clearLogs': '清除',
    'clearLogsSubtitle': '副标题',
    'logFileLocation': '位置',
    'checkUpdate': '更新',
    'checkUpdateSubtitle': '副标题',
    'checkingUpdate': '正在检查更新...',
    'launcherCheckingResources': '正在验证资源...',
    'launcherDownloadingUpdate': '正在下载更新...',
    'launcherSyncingAccount': '正在同步账户...',
    'launcherReady': '准备就绪。',
    'launcherEnter': '进入',
    'colorScheme': '配色',
    'selectColorScheme': '选择',
    'customColorPicker': '拾色器',
    'colorSchemeChanged': '已更改',
    'colorSchemeCustom': '自定义',
    'colorSchemeLotus': '莲花',
    'colorSchemeOcean': '海洋',
    'colorSchemeForest': '森林',
    'colorSchemeSunset': '日落',
    'colorSchemeLavender': '薰衣草',
    'colorSchemeMidnight': '午夜',
    'colorSchemeLotusLight': '莲花明亮',
    'colorSchemeSky': '天空',
    'colorSchemeSpring': '春天',
    'colorSchemeCoral': '珊瑚',
    'colorSchemeViolet': '罗兰',
    'colorSchemeClassic': '经典',
    'colorSchemeDescLotus': '描述',
    'colorSchemeDescOcean': '描述',
    'colorSchemeDescForest': '描述',
    'colorSchemeDescSunset': '描述',
    'colorSchemeDescLavender': '描述',
    'colorSchemeDescMidnight': '描述',
    'colorSchemeDescLotusLight': '描述',
    'colorSchemeDescSky': '描述',
    'colorSchemeDescSpring': '描述',
    'colorSchemeDescCoral': '描述',
    'colorSchemeDescViolet': '描述',
    'colorSchemeDescClassic': '描述',
    'decodingModeHardware': '硬解',
    'decodingModeSoftware': '软解',
    'decodingModeAuto': '自动',
    'decodingModeSet': '设置',
    'decodingModeHardwareDesc': '描述',
    'decodingModeSoftwareDesc': '描述',
    'decodingModeAutoDesc': '描述',
    'fastBuffer': '快',
    'balancedBuffer': '平',
    'stableBuffer': '稳',
    'progressBarModeAuto': '自动',
    'progressBarModeAlways': '始终',
    'progressBarModeNever': '从不',
    'progressBarModeAutoDesc': '描述',
    'progressBarModeAlwaysDesc': '描述',
    'progressBarModeNeverDesc': '描述',
    'progressBarModeSet': '设置',
    'noBoostValue': '无',
    'volumeBoostSet': '设置',
    'volumeBoostLow': '低',
    'volumeBoostSlightLow': '微低',
    'volumeBoostNormal': '正常',
    'volumeBoostSlightHigh': '微高',
    'volumeBoostHigh': '高',
    'epgUrlSavedAndLoaded': '成功',
    'epgUrlSavedButFailed': '失败',
    'epgUrlCleared': '清除',
    'epgUrlSaved': '保存',
    'allSettingsReset': '重置',
    'logLevelDebug': '调试',
    'logLevelRelease': '发布',
    'logLevelOff': '关闭',
    'logLevelDebugDesc': '描述',
    'logLevelReleaseDesc': '描述',
    'logLevelOffDesc': '描述',
    'screenPosition1': '1',
    'screenPosition2': '2',
    'screenPosition3': '3',
    'screenPosition4': '4',
    'screenPositionSet': '设置',
    'backToPlayer': '返回',
    'miniMode': '迷你',
    'exitMultiScreen': '退出',
    'screenNumber': '屏幕',
    'clickToAddChannel': '添加',
    'selectedColor': '颜色',
    'customColorApplied': '应用',
    'newVersionAvailable': '新版',
    'whatsNew': '内容',
    'updateLater': '稍后',
    'updateNow': '现在',
    'downloadComplete': '下载完成',
    'logsCleared': '清除',
    'clearLogsConfirm': '清除',
    'clearLogsConfirmMessage': '确定?',
    'home': '首页',
    'watchHistory': '历史',
    'recommendedChannels': '推荐',
    'continueWatching': '继续',
    'channelStats': '统计',
    'noPlaylistYet': '无列表',
    'addM3uToStart': '添加',
    'minutesAgo': '分前',
    'hoursAgo': '时前',
    'daysAgo': '天前',
    'epgAutoApplied': '成功',
    'chat': '聊天',
    'removeFriend': '删除好友',
    'sendFriendRequest': '发送好友请求',
    'noMessagesYet': '暂无消息',
    'viewFullProfile': '查看完整资料',
    'removeFromFavorites': '从收藏移除',
    'requestSent': '已发送！',
    'couldNotSendRequest': '无法发送',
    'deleteFriendConfirm': '删除好友？',
    'deleteFriendConfirmMessage': '此人将从您的好友列表移除。',
    'loadFailed': '加载失败',
    'friendCountLabel': '1 位好友',
    'friendsCountLabel': '{count} 位好友',
    'addFriend': '添加',
    'pending': '待处理',
    'suggestMovie': '推荐电影或剧集',
    'messageHint': '消息...',
    'routeNotDefined': '未定义路由：',
    'noTitle': '无标题',
    'profileLabel': '资料',
    'filterAll': '全部',
    'filterOnline': '在线',
    'filterPending': '待处理',
    'myProfile': '我的资料',
    'myFriendsCount': '好友',
    'noPendingRequests': '暂无待处理请求',
    'noFriendsFound': '暂无好友',
    'acceptLabel': '接受',
    'rejectLabel': '拒绝',
    'userLabel': '用户',
  };

  static const Map<String, String> _enValues = {
    'lotusIptv': 'Luminora',
    'professionalIptvPlayer': 'Professional IPTV Player',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'save': 'Save',
    'close': 'Close',
    'more': 'More',
    'search': 'Search',
    'unknown': 'Unknown',
    'processing': 'Processing...',
    'apply': 'Apply',
    'or': 'or',
    'playlistManager': 'Playlist Manager',
    'playlistList': 'Sources',
    'goToHomeToAdd': 'Go to Home to add playlists',
    'addNewPlaylist': 'Add New Playlist',
    'playlistName': 'Playlist Name',
    'playlistUrl': 'M3U/M3U8/TXT URL',
    'addFromUrl': 'Add from URL',
    'fromFile': 'From File',
    'importing': 'Importing...',
    'noPlaylists': 'No Playlists',
    'deletePlaylist': 'Delete Playlist',
    'deleteConfirmation': 'Are you sure you want to delete "{name}"?',
    'pleaseEnterPlaylistName': 'Please enter a playlist name',
    'pleaseEnterPlaylistUrl': 'Please enter a playlist URL',
    'playlistAdded': 'Playlist added',
    'playlistRefreshed': 'Playlist refreshed',
    'playlistRefreshFailed': 'Failed to refresh playlist',
    'playlistDeleted': 'Playlist deleted',
    'playlistImported': 'Playlist imported',
    'errorPickingFile': 'Error picking file',
    'managePlaylists': 'Manage Playlists',
    'noPlaylistsYet': 'No Playlists Yet',
    'addFirstPlaylistHint': 'Add your first playlist',
    'addPlaylist': 'Add Playlist',
    'scanToImport': 'Scan to Import',
    'playlistUrlHint': 'URL Hint',
    'selectM3uFile': 'Select M3U file',
    'noFileSelected': 'No file selected',
    'addFirstPlaylistTV': 'Add on TV',
    'importingPlaylist': 'Importing...',
    'importSuccess': 'Import successful',
    'importFailed': 'Import failed',
    'serverStartFailed': 'Server start failed',
    'startingServer': 'Starting...',
    'scanQrToImport': 'Scan QR to Import',
    'qrStep1': 'Step 1',
    'qrStep2': 'Step 2',
    'qrStep3': 'Step 3',
    'playlistNameOptional': 'Name (Optional)',
    'fileNameOptional': 'Filename (Optional)',
    'enterPlaylistUrl': 'Enter URL',
    'importUrlButton': 'Import',
    'selectFile': 'Select File',
    'fileUploadButton': 'Upload',
    'pleaseEnterUrl': 'Please enter URL',
    'sentToTV': 'Sent to TV',
    'sendFailed': 'Send failed',
    'networkError': 'Network error',
    'uploading': 'Uploading...',
    'importPlaylistTitle': 'Import Playlist',
    'importPlaylistSubtitle': 'Subtitle',
    'importFromUrlTitle': 'From URL',
    'importFromFileTitle': 'From File',
    'importFromUsb': 'From USB',
    'addPlaylistSubtitle': 'Subtitle',
    'localFile': 'Local File',
    'channels': 'channels',
    'allChannels': 'All Channels',
    'noChannelsFound': 'No channels found',
    'channelInfo': 'Info',
    'totalChannels': 'Total',
    'categories': 'Categories',
    'testChannel': 'Test',
    'unavailable': 'Unavailable',
    'searchChannels': 'Search',
    'searchHint': 'Search hint',
    'typeToSearch': 'Type...',
    'popularCategories': 'Popular',
    'sports': 'Sports',
    'movies': 'Movies',
    'news': 'News',
    'music': 'Music',
    'kids': 'Kids',
    'noResultsFound': 'No results',
    'noChannelsMatch': 'No match',
    'resultsFor': 'Results for',
    'scanToSearch': 'Scan Search',
    'qrSearchStep1': 'Search 1',
    'qrSearchStep2': 'Search 2',
    'qrSearchStep3': 'Search 3',
    'favorites': 'Favorites',
    'addFavorites': 'Add',
    'removeFavorites': 'Remove',
    'clearAll': 'Clear',
    'noFavoritesYet': 'No favs',
    'favoritesHint': 'Fav hint',
    'browseChannels': 'Browse',
    'removedFromFavorites': 'Removed',
    'undo': 'Undo',
    'clearAllFavorites': 'Clear all',
    'clearFavoritesConfirm': 'Confirm?',
    'allFavoritesCleared': 'Cleared',
    'myFavorites': 'My Favs',
    'playback': 'Playback',
    'live': 'LIVE',
    'buffering': 'Buffering...',
    'paused': 'Paused',
    'playbackError': 'Error',
    'retry': 'Retry',
    'goBack': 'Go Back',
    'playbackSettings': 'Settings',
    'playbackSpeed': 'Speed',
    'shortcutsHint': 'Shortcuts',
    'nextChannel': 'Next',
    'previousChannel': 'Prev',
    'source': 'Source',
    'nowPlaying': 'Playing',
    'endsInMinutes': 'Ends in',
    'upNext': 'Up next',
    'playerHintTV': 'TV Hint',
    'playerHintDesktop': 'Desktop Hint',
    'settings': 'Settings',
    'language': 'Language',
    'general': 'General',
    'theme': 'Theme',
    'active': 'Active',
    'refresh': 'Refresh',
    'updated': 'Updated',
    'version': 'Version',
    'autoPlay': 'Auto Play',
    'autoPlaySubtitle': 'Subtitle',
    'hardwareDecoding': 'HW Dec',
    'hardwareDecodingSubtitle': 'Subtitle',
    'bufferSize': 'Buffer',
    'seconds': 'seconds',
    'playlists': 'Playlists',
    'autoRefresh': 'Auto Refresh',
    'autoRefreshSubtitle': 'Subtitle',
    'refreshInterval': 'Interval',
    'hours': 'hours',
    'days': 'days',
    'day': 'day',
    'rememberLastChannel': 'Remember',
    'rememberLastChannelSubtitle': 'Subtitle',
    'epg': 'EPG',
    'enableEpg': 'Enable',
    'enableEpgSubtitle': 'Subtitle',
    'epgUrl': 'EPG URL',
    'notConfigured': 'Not set',
    'parentalControl': 'Parental',
    'enableParentalControl': 'Enable',
    'enableParentalControlSubtitle': 'Subtitle',
    'changePin': 'Change PIN',
    'changePinSubtitle': 'Subtitle',
    'about': 'About',
    'platform': 'Platform',
    'resetAllSettings': 'Reset all',
    'resetSettingsSubtitle': 'Subtitle',
    'enterEpgUrl': 'Enter URL',
    'setPin': 'Set PIN',
    'enterPin': 'Enter PIN',
    'resetSettings': 'Reset',
    'resetConfirm': 'Confirm?',
    'reset': 'Reset',
    'bufferStrength': 'Buffer',
    'showFps': 'FPS',
    'showFpsSubtitle': 'Subtitle',
    'showClock': 'Clock',
    'showClockSubtitle': 'Subtitle',
    'showNetworkSpeed': 'Speed',
    'showNetworkSpeedSubtitle': 'Subtitle',
    'showVideoInfo': 'Video Info',
    'showVideoInfoSubtitle': 'Subtitle',
    'enableMultiScreen': 'Multi',
    'enableMultiScreenSubtitle': 'Subtitle',
    'showMultiScreenChannelName': 'Name',
    'showMultiScreenChannelNameSubtitle': 'Subtitle',
    'defaultScreenPosition': 'Position',
    'screenPositionDesc': 'Description',
    'followSystem': 'System',
    'languageFollowSystem': 'System Lang',
    'themeDark': 'Dark',
    'themeLight': 'Light',
    'themeSystem': 'System',
    'themeChanged': 'Changed',
    'fontFamily': 'Font',
    'fontFamilyDesc': 'Description',
    'fontChanged': 'Changed',
    'noProgramInfo': 'No info',
    'chinese': '中文',
    'english': 'English',
    'languageSwitchedToChinese': 'ZH',
    'languageSwitchedToEnglish': 'EN',
    'themeChangedMessage': 'Message',
    'simpleMenu': 'Simple Menu',
    'simpleMenuSubtitle': 'Subtitle',
    'simpleMenuEnabled': 'Enabled',
    'simpleMenuDisabled': 'Disabled',
    'autoPlayEnabled': 'Enabled',
    'autoPlayDisabled': 'Disabled',
    'decodingMode': 'Dec Mode',
    'fpsEnabled': 'Enabled',
    'fpsDisabled': 'Disabled',
    'clockEnabled': 'Enabled',
    'clockDisabled': 'Disabled',
    'networkSpeedEnabled': 'Enabled',
    'networkSpeedDisabled': 'Disabled',
    'videoInfoEnabled': 'Enabled',
    'videoInfoDisabled': 'Disabled',
    'progressBarMode': 'Prog Bar',
    'multiScreenEnabled': 'Enabled',
    'multiScreenDisabled': 'Disabled',
    'multiScreenChannelNameEnabled': 'Enabled',
    'multiScreenChannelNameDisabled': 'Disabled',
    'volumeBoost': 'Boost',
    'noBoost': 'No boost',
    'rememberLastChannelEnabled': 'Enabled',
    'rememberLastChannelDisabled': 'Disabled',
    'epgEnabledAndLoaded': 'Ok',
    'epgEnabledButFailed': 'Fail',
    'epgEnabledPleaseConfigure': 'Fail',
    'epgDisabled': 'Off',
    'dlnaCasting': 'DLNA',
    'enableDlnaService': 'Enable DLNA Service',
    'dlnaServiceStarted': 'Started',
    'allowOtherDevicesToCast': 'Allow',
    'dlnaServiceStartedMsg': 'Started',
    'dlnaServiceStoppedMsg': 'Stopped',
    'dlnaServiceStartFailed': 'Failed',
    'developerAndDebug': 'Developer',
    'logLevel': 'Log',
    'exportLogs': 'Export',
    'exportLogsSubtitle': 'Subtitle',
    'clearLogs': 'Clear',
    'clearLogsSubtitle': 'Subtitle',
    'logFileLocation': 'Location',
    'checkUpdate': 'Update',
    'checkUpdateSubtitle': 'Subtitle',
    'checkingUpdate': 'Checking for updates...',
    'launcherCheckingResources': 'Checking resources...',
    'launcherDownloadingUpdate': 'Downloading update...',
    'launcherSyncingAccount': 'Syncing account...',
    'launcherReady': 'Ready.',
    'launcherEnter': 'ENTER',
    'colorScheme': 'Color Scheme',
    'selectColorScheme': 'Select Color Scheme',
    'customColorPicker': 'Picker',
    'colorSchemeChanged': 'Changed',
    'colorSchemeCustom': 'Custom',
    'colorSchemeLotus': 'Lotus',
    'colorSchemeOcean': 'Ocean',
    'colorSchemeForest': 'Forest',
    'colorSchemeSunset': 'Sunset',
    'colorSchemeLavender': 'Lavender',
    'colorSchemeMidnight': 'Midnight',
    'colorSchemeLotusLight': 'Lotus Light',
    'colorSchemeSky': 'Sky',
    'colorSchemeSpring': 'Spring',
    'colorSchemeCoral': 'Coral',
    'colorSchemeViolet': 'Violet',
    'colorSchemeClassic': 'Classic',
    'colorSchemeDescLotus': 'Subtitle',
    'colorSchemeDescOcean': 'Subtitle',
    'colorSchemeDescForest': 'Subtitle',
    'colorSchemeDescSunset': 'Subtitle',
    'colorSchemeDescLavender': 'Subtitle',
    'colorSchemeDescMidnight': 'Subtitle',
    'colorSchemeDescLotusLight': 'Subtitle',
    'colorSchemeDescSky': 'Subtitle',
    'colorSchemeDescSpring': 'Subtitle',
    'colorSchemeDescCoral': 'Subtitle',
    'colorSchemeDescViolet': 'Subtitle',
    'colorSchemeDescClassic': 'Subtitle',
    'decodingModeHardware': 'Hardware',
    'decodingModeSoftware': 'Software',
    'decodingModeAuto': 'Auto',
    'decodingModeSet': 'Set',
    'decodingModeHardwareDesc': 'Desc',
    'decodingModeSoftwareDesc': 'Desc',
    'decodingModeAutoDesc': 'Desc',
    'fastBuffer': 'Fast',
    'balancedBuffer': 'Balanced',
    'stableBuffer': 'Stable',
    'progressBarModeAuto': 'Auto',
    'progressBarModeAlways': 'Always',
    'progressBarModeNever': 'Never',
    'progressBarModeAutoDesc': 'Desc',
    'progressBarModeAlwaysDesc': 'Desc',
    'progressBarModeNeverDesc': 'Desc',
    'progressBarModeSet': 'Set',
    'noBoostValue': 'None',
    'volumeBoostSet': 'Set',
    'volumeBoostLow': 'Low',
    'volumeBoostSlightLow': 'Slight Low',
    'volumeBoostNormal': 'Normal',
    'volumeBoostSlightHigh': 'Slight High',
    'volumeBoostHigh': 'High',
    'epgUrlSavedAndLoaded': 'Ok',
    'epgUrlSavedButFailed': 'Fail',
    'epgUrlCleared': 'Cleared',
    'epgUrlSaved': 'Saved',
    'allSettingsReset': 'Reset',
    'logLevelDebug': 'Debug',
    'logLevelRelease': 'Release',
    'logLevelOff': 'Off',
    'logLevelDebugDesc': 'Desc',
    'logLevelReleaseDesc': 'Desc',
    'logLevelOffDesc': 'Desc',
    'screenPosition1': '1',
    'screenPosition2': '2',
    'screenPosition3': '3',
    'screenPosition4': '4',
    'screenPositionSet': 'Set',
    'backToPlayer': 'Back',
    'miniMode': 'Mini',
    'exitMultiScreen': 'Exit',
    'screenNumber': 'Screen',
    'clickToAddChannel': 'Add',
    'selectedColor': 'Color',
    'customColorApplied': 'Applied',
    'newVersionAvailable': 'New Version',
    'whatsNew': 'News',
    'updateLater': 'Later',
    'updateNow': 'Now',
    'downloadComplete': 'Download complete',
    'logsCleared': 'Cleared',
    'clearLogsConfirm': 'Clear',
    'clearLogsConfirmMessage': 'Confirm?',
    'home': 'Home',
    'watchHistory': 'History',
    'recommendedChannels': 'Recs',
    'continueWatching': 'Continue',
    'channelStats': 'Stats',
    'noPlaylistYet': 'No Playlists',
    'addM3uToStart': 'Add',
    'minutesAgo': 'min ago',
    'hoursAgo': 'h ago',
    'daysAgo': 'd ago',
    'epgAutoApplied': 'Auto applied',
    'chat': 'Chat',
    'removeFriend': 'Remove friend',
    'sendFriendRequest': 'Send friend request',
    'noMessagesYet': 'No messages yet',
    'viewFullProfile': 'View full profile',
    'removeFromFavorites': 'Remove from favorites',
    'requestSent': 'Request sent!',
    'couldNotSendRequest': 'Could not send',
    'deleteFriendConfirm': 'Remove friend?',
    'deleteFriendConfirmMessage': 'This person will be removed from your friends. They will no longer see you as a friend.',
    'loadFailed': 'Failed to load',
    'friendCountLabel': '1 friend',
    'friendsCountLabel': '{count} friends',
    'addFriend': 'Add',
    'pending': 'Pending',
    'suggestMovie': 'Suggest movie or series',
    'messageHint': 'Message...',
    'routeNotDefined': 'No route defined for ',
    'noTitle': 'No title',
    'profileLabel': 'Profile',
    'filterAll': 'All',
    'filterOnline': 'Online',
    'filterPending': 'Pending',
    'myProfile': 'My profile',
    'myFriendsCount': 'Friends',
    'noPendingRequests': 'No pending requests',
    'noFriendsFound': 'No friends found',
    'acceptLabel': 'Accept',
    'rejectLabel': 'Reject',
    'userLabel': 'User',
  };

  static const Map<String, String> _ptBrOverrides = {
    'lotusIptv': 'Luminora',
    'language': 'Idioma',
    'followSystem': 'Seguir sistema',
    'languageFollowSystem': 'Definido para seguir o idioma do sistema',
    'settings': 'Configurações',
    'general': 'Geral',
    'theme': 'Tema',
    'themeDark': 'Escuro',
    'themeLight': 'Claro',
    'themeSystem': 'Seguir sistema',
    'themeChanged': 'Tema alterado',
    'cancel': 'Cancelar',
    'delete': 'Excluir',
    'save': 'Salvar',
    'error': 'Erro',
    'success': 'Sucesso',
    'chinese': '中文',
    'english': 'English',
    'playlistManager': 'Gerenciador de listas',
    'playlistList': 'Fontes',
    'goToHomeToAdd': 'Vá ao Início para adicionar listas',
    'addNewPlaylist': 'Adicionar lista',
    'playlistName': 'Nome da lista',
    'playlistUrl': 'URL M3U/M3U8/TXT',
    'addFromUrl': 'Adicionar por URL',
    'fromFile': 'Do arquivo',
    'importing': 'Importando...',
    'noPlaylists': 'Nenhuma lista',
    'addFirstPlaylist': 'Adicione sua primeira lista acima',
    'deletePlaylist': 'Excluir lista',
    'deleteConfirmation': 'Excluir "{name}"? Isso também remove todos os canais desta lista.',
    'playlists': 'Listas',
    'channels': 'Canais',
    'allChannels': 'Todos os canais',
    'noChannelsFound': 'Nenhum canal encontrado',
    'addFavorites': 'Adicionar aos favoritos',
    'removeFavorites': 'Remover dos favoritos',
    'favorites': 'Favoritos',
    'home': 'Início',
    'refresh': 'Atualizar',
    'updated': 'Atualizado',
    'version': 'Versão',
    'close': 'Fechar',
    'search': 'Pesquisar',
    'languageSwitchedToChinese': 'Idioma alterado para Chinês',
    'languageSwitchedToEnglish': 'Idioma alterado para Inglês',
    'loading': 'Carregando...',
    'allFavoritesCleared': 'Todas os favoritos foram removidos',
    'clearAllFavorites': 'Limpar favoritos',
    'clearFavoritesConfirm': 'Tem certeza que deseja limpar todos os favoritos?',
    'more': 'Mais',
    'unknown': 'Desconhecido',
    'active': 'Ativo',
    'channelInfo': 'Informações do canal',
    'totalChannels': 'Total de canais',
    'categories': 'Categorias',
    'searchChannels': 'Pesquisar canais',
    'searchHint': 'Pesquisar canais...',
    'typeToSearch': 'Digite para pesquisar',
    'popularCategories': 'Categorias populares',
    'sports': 'Esportes',
    'movies': 'Filmes',
    'news': 'Notícias',
    'music': 'Música',
    'kids': 'Kids',
    'noResultsFound': 'Nenhum resultado encontrado',
    'noChannelsMatch': 'Nenhum canal encontrado para "{query}"',
    'resultsFor': 'Resultados para "{query}"',
    'favoritesHint': 'Pressione e segure um canal para adicionar aos favoritos',
    'browseChannels': 'Navegar pelos canais',
    'removedFromFavorites': 'Removido dos favoritos',
    'undo': 'Desfazer',
    'clearAll': 'Limpar tudo',
    'noFavoritesYet': 'Nenhum favorito ainda',
    'noProgramInfo': 'Sem informações do programa',
    'playback': 'Reprodução',
    'live': 'AO VIVO',
    'buffering': 'Carregando...',
    'paused': 'Pausado',
    'playbackError': 'Erro na reprodução',
    'retry': 'Tentar novamente',
    'goBack': 'Voltar',
    'playbackSettings': 'Configurações de reprodução',
    'playbackSpeed': 'Velocidade de reprodução',
    'shortcutsHint': 'Atalhos: Espaço (Pause), F (Tela Cheia), M (Mudo)',
    'nextChannel': 'Próximo canal',
    'previousChannel': 'Canal anterior',
    'source': 'Fonte',
    'nowPlaying': 'Reproduzindo agora',
    'endsInMinutes': 'Termina em {minutes} min',
    'upNext': 'A seguir',
    'playerHintTV': 'Use as setas para navegar',
    'playerHintDesktop': 'Use o mouse ou teclado',
    'playlistAdded': 'Lista adicionada com sucesso',
    'playlistRefreshed': 'Lista atualizada',
    'playlistRefreshFailed': 'Falha ao atualizar lista',
    'playlistDeleted': 'Lista excluída',
    'playlistImported': 'Lista importada',
    'errorPickingFile': 'Erro ao selecionar arquivo',
    'managePlaylists': 'Gerenciar listas',
    'noPlaylistsYet': 'Nenhuma lista ainda',
    'addFirstPlaylistHint': 'Adicione sua primeira lista para começar',
    'addPlaylist': 'Adicionar lista',
    'scanToImport': 'Escanear para importar',
    'playlistUrlHint': 'URL da lista',
    'selectM3uFile': 'Selecione arquivo M3U',
    'noFileSelected': 'Nenhum arquivo selecionado',
    'addFirstPlaylistTV': 'Adicione lista na TV',
    'or': 'ou',
    'autoPlay': 'Reprodução automática',
    'autoPlaySubtitle': 'Iniciar reprodução automaticamente ao abrir',
    'hardwareDecoding': 'Decodificação de hardware',
    'hardwareDecodingSubtitle': 'Usar aceleração de hardware para vídeo',
    'bufferSize': 'Tamanho do buffer',
    'seconds': 'segundos',
    'autoRefresh': 'Atualização automática',
    'autoRefreshSubtitle': 'Atualizar listas automaticamente',
    'refreshInterval': 'Intervalo de atualização',
    'hours': 'horas',
    'days': 'dias',
    'day': 'dia',
    'rememberLastChannel': 'Lembrar último canal',
    'rememberLastChannelSubtitle': 'Continuar de onde parou',
    'epg': 'Guia de Programação (EPG)',
    'enableEpg': 'Habilitar EPG',
    'enableEpgSubtitle': 'Mostrar guia de programação',
    'epgUrl': 'URL do EPG',
    'notConfigured': 'Não configurado',
    'parentalControl': 'Controle parental',
    'enableParentalControl': 'Habilitar controle parental',
    'enableParentalControlSubtitle': 'Proteger canais com senha',
    'changePin': 'Alterar PIN',
    'changePinSubtitle': 'Mudar senha de acesso',
    'about': 'Sobre',
    'platform': 'Plataforma',
    'resetAllSettings': 'Redefinir configurações',
    'resetSettingsSubtitle': 'Voltar aos padrões de fábrica',
    'enterEpgUrl': 'Digite a URL do EPG',
    'setPin': 'Definir PIN',
    'enterPin': 'Digite o PIN',
    'resetSettings': 'Redefinir',
    'resetConfirm': 'Tem certeza que deseja redefinir?',
    'reset': 'Redefinir',
    'bufferStrength': 'Força do buffer',
    'showFps': 'Mostrar FPS',
    'showFpsSubtitle': 'Exibir quadros por segundo',
    'showClock': 'Mostrar relógio',
    'showClockSubtitle': 'Exibir hora atual',
    'showNetworkSpeed': 'Mostrar velocidade de rede',
    'showNetworkSpeedSubtitle': 'Exibir uso de dados',
    'showVideoInfo': 'Mostrar info do vídeo',
    'showVideoInfoSubtitle': 'Resolução e codecs',
    'enableMultiScreen': 'Multitela',
    'enableMultiScreenSubtitle': 'Habilitar modo mosaico',
    'showMultiScreenChannelName': 'Nome do canal no mosaico',
    'showMultiScreenChannelNameSubtitle': 'Exibir nomes no modo multitela',
    'defaultScreenPosition': 'Posição padrão',
    'screenPositionDesc': 'Onde abrir novos canais',
    'watchHistory': 'Histórico',
    'recommendedChannels': 'Recomendados',
    'continueWatching': 'Continuar assistindo',
    'channelStats': 'Estatísticas',
    'noPlaylistYet': 'Nenhuma lista ainda',
    'addM3uToStart': 'Adicione uma lista M3U para começar',
    'minutesAgo': 'min atrás',
    'hoursAgo': 'h atrás',
    'daysAgo': 'd atrás',
    'processing': 'Processando...',
    'localFile': 'Arquivo local',
    'volumeNormalization': 'Normalização de Volume',
    'volumeNormalizationSubtitle': 'Ajustar automaticamente diferenças de volume',
    'volumeBoost': 'Aumento de Volume',
    'noBoost': 'Sem aumento',
    'checkUpdate': 'Verificar Atualização',
    'checkUpdateSubtitle': 'Verificar se há nova versão disponível',
    'decodingMode': 'Modo de Decodificação',
    'decodingModeAuto': 'Automático',
    'decodingModeHardware': 'Hardware',
    'decodingModeSoftware': 'Software',
    'decodingModeAutoDesc': 'Escolher automaticamente. Recomendado.',
    'decodingModeHardwareDesc': 'Forçar MediaCodec. Pode causar erros.',
    'decodingModeSoftwareDesc': 'Usar CPU. Mais compatível, gasta mais bateria.',
    'volumeBoostLow': 'Volume muito baixo',
    'volumeBoostSlightLow': 'Volume ligeiramente baixo',
    'volumeBoostNormal': 'Volume normal',
    'volumeBoostSlightHigh': 'Volume ligeiramente alto',
    'volumeBoostHigh': 'Volume muito alto',
    'startingServer': 'Iniciando servidor...',
    'epgAutoApplied': 'EPG aplicado automaticamente',
    'importFromUsb': 'Importar do USB ou armazenamento local',
    'qrStep1': 'Escaneie o código QR com seu celular',
    'qrStep2': 'Digite a URL ou envie o arquivo na página',
    'qrStep3': 'Clique em importar, a TV recebe automaticamente',
    'qrSearchStep1': 'Escaneie o código QR com seu celular',
    'qrSearchStep2': 'Digite a busca na página',
    'qrSearchStep3': 'Resultados aparecerão na TV automaticamente',
    'scanToSearch': 'Escanear para Buscar',
    'newVersionAvailable': 'Nova versão disponível',
    'whatsNew': 'O que há de novo',
    'updateLater': 'Atualizar depois',
    'updateNow': 'Atualizar agora',
    'noReleaseNotes': 'Sem notas de lançamento',
    'autoPlayEnabled': 'Reprodução automática ativada',
    'autoPlayDisabled': 'Reprodução automática desativada',
    'fpsEnabled': 'Exibição de FPS ativada',
    'fpsDisabled': 'Exibição de FPS desativada',
    'clockEnabled': 'Relógio ativado',
    'clockDisabled': 'Relógio desativado',
    'networkSpeedEnabled': 'Velocidade de rede ativada',
    'networkSpeedDisabled': 'Velocidade de rede desativada',
    'videoInfoEnabled': 'Informações de vídeo ativadas',
    'videoInfoDisabled': 'Informações de vídeo desativadas',
    'multiScreenEnabled': 'Modo multitela ativado',
    'multiScreenDisabled': 'Modo multitela desativado',
    'multiScreenChannelNameEnabled': 'Nomes de canais no multitela ativados',
    'multiScreenChannelNameDisabled': 'Nomes de canais no multitela desativados',
    'screenPosition1': 'Superior Esquerdo (1)',
    'screenPosition2': 'Superior Direito (2)',
    'screenPosition3': 'Inferior Esquerdo (3)',
    'screenPosition4': 'Inferior Direito (4)',
    'screenPositionSet': 'Posição padrão definida para: {position}',
    'multiScreenMode': 'Modo Multitela',
    'backToPlayer': 'Voltar',
    'miniMode': 'Modo Mini',
    'exitMultiScreen': 'Sair do Multitela',
    'screenNumber': 'Tela {number}',
    'clickToAddChannel': 'Clique para adicionar canal',
    'selectChannel': 'Selecionar Canal',
    'collapse': 'Recolher',
    'channelCountLabel': '{count} canais',
    'showOnlyFailed': 'Mostrar apenas falhas ({count})',
    'moveToUnavailable': 'Mover para Indisponíveis',
    'stopTest': 'Parar Teste',
    'startTest': 'Iniciar Teste',
    'complete': 'Concluído',
    'runInBackground': 'Executar em Segundo Plano',
    'movedToUnavailable': 'Movidos {count} canais indisponíveis para categoria Indisponível',
    'checkingUpdate': 'Verificando atualizações...',
    'launcherCheckingResources': 'Verificando recursos...',
    'launcherDownloadingUpdate': 'Baixando atualização...',
    'launcherSyncingAccount': 'Sincronizando conta...',
    'launcherReady': 'Pronto.',
    'launcherEnter': 'ENTRAR',
    'alreadyLatestVersion': 'Já está na versão mais recente',
    'checkUpdateFailed': 'Falha ao verificar atualização: {error}',
    'updateFailed': 'Falha na atualização: {error}',
    'downloadUpdate': 'Baixar Atualização',
    'downloadFailed': 'Falha no download: {error}',
    'downloadComplete': 'Download Concluído',
    'runInstallerNow': 'Executar instalador agora?',
    'later': 'Mais tarde',
    'installNow': 'Instalar Agora',
    'deletedChannels': '{count} canais indisponíveis excluídos',
    'testing': 'Testando: {name}',
    'channelAvailableRestored': '{name} disponível, restaurado para categoria "{group}"',
    'testingInBackground': 'Testando em segundo plano, restam {count} canais',
    'restoredToCategory': 'Restaurado {name} para categoria original',
    'dlnaCast': 'Transmitir DLNA',
    'notImplemented': '(Não implementado)',
    'volumeNormalizationNotImplemented': 'Normalização de volume não implementada',
    'autoRefreshNotImplemented': 'Atualização automática não implementada',
    'rememberLastChannelEnabled': 'Lembrar último canal ativado',
    'rememberLastChannelDisabled': 'Lembrar último canal desativado',
    'epgEnabledAndLoaded': 'EPG ativado e carregado com sucesso',
    'epgEnabledButFailed': 'EPG ativado mas falhou ao carregar',
    'epgEnabledPleaseConfigure': 'EPG ativado, por favor configure a URL',
    'epgDisabled': 'EPG desativado',
    'weak': 'Fraco',
    'medium': 'Médio',
    'strong': 'Forte',
    'dlnaServiceStarted': 'Iniciado: {deviceName}',
    'allowOtherDevicesToCast': 'Permitir que outros dispositivos transmitam para este',
    'dlnaServiceStartedMsg': 'Serviço DLNA iniciado',
    'dlnaServiceStoppedMsg': 'Serviço DLNA parado',
    'dlnaServiceStartFailed': 'Falha ao iniciar serviço DLNA',
    'parentalControlNotImplemented': 'Controle parental não implementado',
    'changePinNotImplemented': '(Não implementado)',
    'decodingModeSet': 'Modo de decodificação definido para: {mode}',
    'fastBuffer': 'Rápido (Troca rápida, pode travar)',
    'balancedBuffer': 'Balanceado',
    'stableBuffer': 'Estável (Troca lenta, menos travamentos)',
    'bufferSizeNotImplemented': 'Tamanho do buffer não implementado',
    'volumeBoostSet': 'Aumento de volume definido para {value}',
    'noBoostValue': 'Sem aumento',
    'epgUrlSavedAndLoaded': 'URL do EPG salva e carregada com sucesso',
    'epgUrlSavedButFailed': 'URL do EPG salva mas falhou ao carregar',
    'epgUrlCleared': 'URL do EPG limpa',
    'epgUrlSaved': 'URL do EPG salva',
    'pinNotImplemented': 'PIN não implementado',
    'enter4DigitPin': 'Digite o PIN de 4 dígitos',
    'allSettingsReset': 'Todas as configurações foram redefinidas',
    'themeChangedMessage': 'Tema alterado: {theme}',
    'defaultVersion': 'Versão padrão',
    'colorScheme': 'Esquema de Cores',
    'selectColorScheme': 'Selecionar Esquema de Cores',
    'colorSchemeLotus': 'Lotus',
    'colorSchemeOcean': 'Oceano',
    'colorSchemeForest': 'Floresta',
    'colorSchemeSunset': 'Pôr do Sol',
    'colorSchemeLavender': 'Lavanda',
    'colorSchemeMidnight': 'Meia-noite',
    'colorSchemeLotusLight': 'Lotus Claro',
    'colorSchemeSky': 'Céu',
    'colorSchemeSpring': 'Primavera',
    'colorSchemeCoral': 'Coral',
    'colorSchemeViolet': 'Violeta',
    'colorSchemeClassic': 'Clássico',
    'colorSchemeDescLotus': 'Elegante, moderno, cor da marca',
    'colorSchemeDescOcean': 'Calmo, profissional, confortável',
    'colorSchemeDescForest': 'Natural, confortável, confortável',
    'colorSchemeDescSunset': 'Quente, energético, chamativo',
    'colorSchemeDescLavender': 'Misterioso, nobre, suave',
    'colorSchemeDescMidnight': 'Profundo, focado, discreto',
    'colorSchemeDescLotusLight': 'Elegante, moderno, cor da marca',
    'colorSchemeDescSky': 'Fresco, brilhante, confortável',
    'colorSchemeDescSpring': 'Vibrant, energético, confortável',
    'colorSchemeDescCoral': 'Quente, amigável, chamativo',
    'colorSchemeDescViolet': 'Elegante, suave, nobre',
    'colorSchemeDescClassic': 'Simples, profissional, universal',
    'colorSchemeChanged': 'Esquema de cores alterado para: {scheme}',
    'customColorPicker': 'Seletor de Cor Personalizado',
    'selectedColor': 'Cor Selecionada',
    'apply': 'Aplicar',
    'customColorApplied': 'Cor personalizada aplicada',
    'colorSchemeCustom': 'Personalizado',
    'importPlaylistTitle': 'Importar Lista',
    'importPlaylistSubtitle': 'Importar lista para sua TV',
    'importFromUrlTitle': 'Importar via URL',
    'importFromFileTitle': 'Importar de Arquivo',
    'playlistNameOptional': 'Nome da lista (opcional)',
    'enterPlaylistUrl': 'Digite a URL M3U/M3U8/TXT',
    'importUrlButton': 'Importar URL',
    'selectFile': 'Selecionar Arquivo',
    'fileNameOptional': 'Nome da lista (opcional)',
    'fileUploadButton': 'Enviar Arquivo',
    'pleaseEnterUrl': 'Por favor, digite a URL',
    'sentToTV': 'Enviado para a TV',
    'sendFailed': 'Falha no envio',
    'networkError': 'Erro de rede',
    'uploading': 'Enviando...',
    'simpleMenu': 'Menu Simples',
    'simpleMenuSubtitle': 'Manter menu recolhido',
    'simpleMenuEnabled': 'Menu simples ativado',
    'simpleMenuDisabled': 'Menu simples desativado',
    'progressBarMode': 'Barra de Progresso',
    'progressBarModeSubtitle': 'Controlar exibição da barra de progresso',
    'progressBarModeAuto': 'Automático',
    'progressBarModeAlways': 'Sempre Visível',
    'progressBarModeNever': 'Nunca Visível',
    'progressBarModeAutoDesc': 'Automático (VOD visível, Live oculto)',
    'progressBarModeAlwaysDesc': 'Sempre visível',
    'progressBarModeNeverDesc': 'Nunca visível',
    'progressBarModeSet': 'Barra de progresso definida para: {mode}',
    'developerAndDebug': 'Desenvolvedor e Depuração',
    'logLevel': 'Nível de Log',
    'logLevelSubtitle': 'Selecione o nível de log',
    'logLevelDebug': 'Depuração',
    'logLevelRelease': 'Lançamento',
    'logLevelOff': 'Desligado',
    'logLevelDebugDesc': 'Logar tudo',
    'logLevelReleaseDesc': 'Apenas avisos e erros',
    'logLevelOffDesc': 'Não logar nada',
    'exportLogs': 'Exportar Logs',
    'exportLogsSubtitle': 'Escanear QR para ver logs',
    'clearLogs': 'Limpar Logs',
    'clearLogsSubtitle': 'Excluir todos os arquivos de log',
    'logFileLocation': 'Local do Arquivo de Log',
    'logsCleared': 'Logs limpos',
    'clearLogsConfirm': 'Limpar Logs',
    'clearLogsConfirmMessage': 'Tem certeza que deseja excluir todos os logs?',
    'errorTimeout': 'Tempo limite esgotado',
    'errorNetwork': 'Erro de rede',
    'usingCachedSource': 'Usando fonte em cache',
    'enableDlnaService': 'Habilitar Serviço DLNA',
    'chat': 'Conversar',
    'removeFriend': 'Excluir amigo',
    'sendFriendRequest': 'Enviar solicitação de amizade',
    'noMessagesYet': 'Nenhuma mensagem ainda',
    'viewFullProfile': 'Ver perfil completo',
    'removeFromFavorites': 'Remover dos favoritos',
    'requestSent': 'Solicitação enviada!',
    'couldNotSendRequest': 'Não foi possível enviar',
    'deleteFriendConfirm': 'Excluir amigo?',
    'deleteFriendConfirmMessage': 'Esta pessoa será removida da sua lista de amigos. Ela também deixará de ver você como amigo.',
    'loadFailed': 'Falha ao carregar',
    'friendCountLabel': '1 amigo',
    'friendsCountLabel': '{count} amigos',
    'addFriend': 'Adicionar',
    'pending': 'Pendente(s)',
    'suggestMovie': 'Indicar filme ou série',
    'messageHint': 'Mensagem...',
    'routeNotDefined': 'Rota não definida para ',
    'noTitle': 'Sem título',
    'profileLabel': 'Perfil',
    'filterAll': 'TODOS',
    'filterOnline': 'ONLINE',
    'filterPending': 'PENDENTES',
    'myProfile': 'MEU PERFIL',
    'myFriendsCount': 'AMIGOS',
    'noPendingRequests': 'Nenhum pedido pendente',
    'noFriendsFound': 'Nenhum amigo encontrado',
    'acceptLabel': 'Aceitar',
    'rejectLabel': 'Rejeitar',
    'userLabel': 'Usuário',
  };

  static Map<String, String> get _ptBrValues =>
      Map.from(_enValues)..addAll(_ptBrOverrides);
}
