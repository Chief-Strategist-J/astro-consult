library;

class AppConfig {
  static const functionsRegion = 'asia-south1';

  static const countryCode = '+91';
  static const phoneLength = 10;
  static const otpLength = 6;
  static const otpTimeout = Duration(seconds: 60);
  static const nameMinLength = 2;
  static const maxMessageLength = 1000;

  static const acceptTimeout = Duration(seconds: 60);
  static const tick = Duration(seconds: 1);
  static const secondsPerMinute = 60;
  static const secondsPerHour = 3600;
  static const defaultBirthYearsAgo = 25;
  static const earliestBirthYear = 1900;
  static const defaultBirthHour = 12;
  static const typingIdle = Duration(seconds: 3);
  static const restoreAttempts = 3;
  static const restoreRetryDelay = Duration(seconds: 1);
  static const priceMin = 1;
  static const priceMax = 1000;
  static const experienceMax = 80;
  static const aboutMax = 500;
  static const listMax = 6;
  static const listInputSeparator = ',';
  static const httpsPrefix = 'https://';

  static const dateFormat = 'yyyy-MM-dd';
  static const historyDateFormat = 'd MMM, h:mm a';
  static const messageTimeFormat = 'h:mm a';

  static const speakerKeyword = 'speaker';
  static const earpieceKeywords = ['earpiece', 'receiver'];
  static const minuteSeparator = ':';
  static const padChar = '0';

  /// Permission result keys reported by the VideoSDK plugin.
  static const permAudio = 'audio';
  static const permVideo = 'video';

  static String avatarHeroTag(String id) => 'avatar-$id';
  static String fullPhone(String phone) => '$countryCode$phone';
  static String clockTime(String hh, String mm) => '$hh$minuteSeparator$mm';
  static String deviceKey(String label, String id) => '$label $id'.toLowerCase();
}

/// Firebase error codes the app maps to messages.
class ErrorCodes {
  static const unauthenticated = 'unauthenticated';
  static const unavailable = 'unavailable';
  static const deadlineExceeded = 'deadline-exceeded';
  static const permissionDenied = 'permission-denied';
  static const invalidPhoneNumber = 'invalid-phone-number';
  static const invalidVerificationCode = 'invalid-verification-code';
  static const sessionExpired = 'session-expired';
  static const codeExpired = 'code-expired';
  static const tooManyRequests = 'too-many-requests';
  static const quotaExceeded = 'quota-exceeded';
  static const networkRequestFailed = 'network-request-failed';
}

class Db {
  static const users = 'users';
  static const astrologers = 'astrologers';
  static const reviews = 'reviews';
  static const sessions = 'sessions';
  static const messages = 'messages';

  static const name = 'name';
  static const phone = 'phone';
  static const dob = 'dob';
  static const birthTime = 'birthTime';
  static const birthPlace = 'birthPlace';
  static const createdAt = 'createdAt';

  static const avatar = 'avatar';
  static const expertise = 'expertise';
  static const languages = 'languages';
  static const experience = 'experience';
  static const rating = 'rating';
  static const reviewCount = 'reviews';
  static const pricePerMin = 'pricePerMin';
  static const status = 'status';
  static const about = 'about';

  static const reviewUser = 'user';
  static const reviewRating = 'rating';
  static const reviewText = 'text';

  static const userId = 'userId';
  static const astrologerId = 'astrologerId';
  static const astrologerName = 'astrologerName';
  static const astrologerAvatar = 'astrologerAvatar';
  static const type = 'type';
  static const durationSec = 'durationSec';
  static const cost = 'cost';
  static const role = 'role';
  static const uid = 'uid';
  static const userName = 'userName';
  static const userDob = 'userDob';
  static const userBirthTime = 'userBirthTime';
  static const userBirthPlace = 'userBirthPlace';
  static const startedAt = 'startedAt';

  static const presence = 'presence';
  static const online = 'online';
  static const typing = 'typing';
  static const updatedAt = 'updatedAt';

  static const messageText = 'text';
  static const messageFrom = 'from';
  static const fromUser = 'user';
  static const fromAstrologer = 'astrologer';
}

class Fn {
  static const startSession = 'startSession';
  static const endSession = 'endSession';
  static const getVideoSdkRoom = 'getVideoSdkRoom';
  static const saveAstrologerProfile = 'saveAstrologerProfile';
  static const setAvailability = 'setAvailability';
  static const respondToSession = 'respondToSession';

  static const argAccept = 'accept';
  static const argOnline = 'online';
  static const argName = 'name';
  static const argAvatar = 'avatar';
  static const argExpertise = 'expertise';
  static const argLanguages = 'languages';
  static const argExperience = 'experience';
  static const argPricePerMin = 'pricePerMin';
  static const argAbout = 'about';

  static const argAstrologerId = 'astrologerId';
  static const argType = 'type';
  static const argSessionId = 'sessionId';

  static const resId = 'id';
  static const resToken = 'token';
  static const resMeetingId = 'meetingId';
}

class Prefs {
  static const themeMode = 'theme_mode';
}

class AppStrings {
  static const appTitle = 'Astro';
  static const retry = 'Retry';
  static const close = 'Close';
  static const done = 'Done';
  static const pleaseWait = 'Please wait…';
  static const toggleTheme = 'Toggle theme';
  static const logOut = 'Log out';
  static const dash = '—';
  static const bullet = ' • ';
  static const listSeparator = ', ';
  static const star = '★';
  static const currency = '₹';
  static const errorGeneric = 'Something went wrong. Please try again.';
  static const errorNetwork = 'Cannot reach the server. Check your connection.';
  static const errorPermission = 'You do not have permission to do that.';
  static const errorSignedOut = 'Your session has expired. Please sign in again.';
  static String perMinute(num price) => '$currency${price.toStringAsFixed(0)}/min';
  static String money(num amount) => '$currency${amount.toStringAsFixed(0)}';
  static String moneyExact(num amount) => '$currency${amount.toStringAsFixed(2)}';

  static const loginTitle = 'Welcome back';
  static const signUpTitle = 'Create account';
  static const otpTitle = 'Verify your number';
  static const authSubtitle = 'Talk to trusted astrologers over chat, voice and video.';
  static String otpSubtitle(String phone) =>
      'Enter the code sent to ${AppConfig.countryCode} $phone';
  static const fullName = 'Full name';
  static const mobileNumber = 'Mobile number';
  static const signUp = 'Sign up';
  static const sendOtp = 'Send OTP';
  static const toSignUp = 'New here? Create an account';
  static const toLogin = 'Already have an account? Log in';
  static const verifyContinue = 'Verify & continue';
  static const resendOtp = 'Resend OTP';
  static const changeNumber = 'Change number';
  static const otpHint = '••••••';
  static const errName = 'Enter your name';
  static const errPhone = 'Enter a valid 10-digit number';
  static const errOtp = 'Enter the 6-digit code';
  static const errInvalidCode = 'Incorrect code. Please try again.';
  static const errCodeExpired = 'The code has expired. Request a new one.';
  static const errTooManyRequests = 'Too many attempts. Please try again later.';
  static const errInvalidPhone = 'That phone number is not valid.';
  static final phonePrefix = '${AppConfig.countryCode}  ';

  static const profileSetupTitle = 'Complete your profile';
  static const profileTitle = 'My profile';
  static const profileSetupHint =
      'Astrologers need your birth details to prepare an accurate reading.';
  static const dob = 'Date of birth';
  static const birthTime = 'Birth time';
  static const birthPlace = 'Birth place';
  static const saveContinue = 'Save & continue';
  static const saveChanges = 'Save changes';
  static const profileSaved = 'Profile saved';
  static const errDob = 'Select your date of birth';
  static const errBirthTime = 'Select your birth time';
  static const errBirthPlace = 'Enter your birth place';

  // Roles / auth
  static const roleUser = 'User';
  static const roleAstrologer = 'Astrologer';
  static const loginTitleAstrologer = 'Astrologer login';
  static const signUpTitleAstrologer = 'Create astrologer account';
  static const authSubtitleAstrologer = 'Accept consultations and connect with users over chat, voice and video.';
  static String errWrongRole(String registeredAs) =>
      'This number is registered as ${registeredAs.toLowerCase()} account. Switch to the "$registeredAs" option to continue.';

  // Astrologer profile
  static const astroProfileSetupTitle = 'Set up your astrologer profile';
  static const astroProfileTitle = 'My astrologer profile';
  static const astroProfileHint = 'Users see this when they browse astrologers.';
  static const fieldAvatar = 'Photo link (optional, https)';
  static const fieldExpertise = 'Expertise (comma separated)';
  static const fieldLanguages = 'Languages (comma separated)';
  static const fieldExperience = 'Experience (years)';
  static const fieldPrice = 'Price per minute (₹)';
  static const fieldAbout = 'About you';
  static const errExpertise = 'Add at least one expertise (up to 6)';
  static const errLanguages = 'Add at least one language (up to 6)';
  static const errExperience = 'Enter years of experience (0 to 80)';
  static const errPrice = 'Enter a price between ₹1 and ₹1000';
  static const errAbout = 'Keep this under 500 characters';
  static const errAvatar = 'The photo link must start with https://';

  // Astrologer dashboard
  static const tabDashboard = 'Dashboard';
  static const dashboardTitle = 'Consultations';
  static const youAreOnline = 'You are online';
  static const youAreOffline = 'You are offline';
  static const youAreBusy = 'In a consultation';
  static const availabilityHint = 'Users can request consultations only while you are online.';
  static const incomingRequests = 'Incoming requests';
  static const noRequests = 'No requests right now';
  static const activeConsultation = 'Active consultation';
  static const resume = 'Resume';
  static const endConsultation = 'End';
  static const accept = 'Accept';
  static const decline = 'Decline';
  static const recentConsultations = 'Recent consultations';
  static const noRecent = 'No consultations yet';
  static const newAstrologer = 'New';
  static const declined = 'Declined';
  static String requestTitle(String name, String type) => '$name$bullet$type';
  static String clientBirth(String dob, String time, String place) => 'Born $dob, $time, $place';
  static String earned(String amount) => 'Earned $amount';

  static const tabAstrologers = 'Astrologers';
  static const tabHistory = 'History';
  static const tabProfile = 'Profile';

  static const astrologersTitle = 'Astrologers';
  static const sort = 'Sort';
  static const searchHint = 'Search name, expertise or language';
  static const onlineNow = 'Online now';
  static const noMatches = 'No astrologers match your filters';
  static const noAstrologers = 'No astrologers are available yet. Please check back soon.';
  static const noReviews = 'No reviews yet';
  static const sortRating = 'Top rated';
  static const sortPriceLow = 'Price: low to high';
  static const sortPriceHigh = 'Price: high to low';
  static const sortExperience = 'Most experienced';
  static const availOnline = 'Online';
  static const availBusy = 'Busy';
  static const availOffline = 'Offline';
  static String years(int n) => '$n yrs';
  static String experienceLine(int years, List<String> langs) =>
      '${AppStrings.years(years)}$bullet${langs.join(listSeparator)}';
  static String ratingWithCount(double rating, int count) => ' $rating ($count)';

  static const about = 'About';
  static const reviews = 'Reviews';
  static const statRating = 'Rating';
  static const statExperience = 'Experience';
  static const statReviews = 'Reviews';
  static const statPrice = 'Price';
  static const actionChat = 'Chat';
  static const actionCall = 'Call';
  static const actionVideo = 'Video';
  static String ratingStat(double rating) => '$rating $star';
  static String languages(List<String> l) => 'Languages: ${l.join(listSeparator)}';
  static String reviewTitle(String user, int rating) => '$user  ${star * rating}';
  static String unavailable(String name, String status) =>
      '$name is $status right now. Please check back later.';

  static const typeChat = 'Chat';
  static const typeVoice = 'Voice call';
  static const typeVideo = 'Video call';
  static const sendingRequest = 'Sending request…';
  static const reconnecting = 'Reconnecting…';
  static const cancelRequest = 'Cancel request';
  static const endTitle = 'End consultation?';
  static const endBody = 'The session will stop and billing ends now.';
  static const keepGoing = 'Keep going';
  static const end = 'End';
  static const completedTitle = 'Consultation completed';
  static const failedTitle = 'Could not start consultation';
  static const failedGeneric = 'Something went wrong.';
  static const rowAstrologer = 'Astrologer';
  static const rowClient = 'Client';
  static const rowType = 'Type';
  static const rowDuration = 'Duration';
  static const rowRate = 'Rate';
  static const rowTotal = 'Total';
  static const historyTitle = 'Consultation history';
  static const noHistory = 'No consultations yet';
  static const cancelled = 'Cancelled';
  static String waitingFor(String name) => 'Waiting for $name';
  static String requestSent(String type) =>
      'Your ${type.toLowerCase()} request has been sent. This usually takes a few seconds.';
  static String durationLabel(String d) => 'Duration $d';
  static String historySubtitle(String type, String date, String tail) => '$type$bullet$date\n$tail';
  static String count(int n) => n.toString();
  static String endFailed(String reason) => 'Could not end the session: $reason';
  static const errNoResponse = 'The astrologer did not respond. Please try again.';
  static const errCancelled = 'The consultation was cancelled.';
  static String errDeclined(String name) => '$name declined your request.';
  static const errConnectionLost = 'Lost connection to the server.';
  static const errSessionMissing = 'The consultation could not be found.';

  static const endChat = 'End chat';
  static const typing = 'typing…';
  static const online = 'Online';
  static const offline = 'Offline';
  static const connecting = 'Connecting…';
  static const messageHint = 'Type a message';
  static const errSend = 'Could not send your message.';
  static String sayHello(String name) => 'Say hello to $name';

  static const callPreparing = 'Preparing…';
  static const callConnecting = 'Connecting…';
  static const callConnected = 'Connected';
  static const callFailed = 'Call failed';
  static const mute = 'Mute';
  static const unmute = 'Unmute';
  static const speaker = 'Speaker';
  static const guestName = 'Guest';
  static const errMicPermission = 'Microphone permission is required for calls.';
  static const errUnsupportedDevice =
      'Calls are not supported on this device. Use a real Android phone (ARM), not an x86 emulator.';
  static const errCamPermission =
      'Camera and microphone permissions are required for video calls.';
  static const errDisconnected = 'Call disconnected. Tap retry to rejoin.';
  static const errMicToggle = 'Could not change microphone state.';
  static const errCamToggle = 'Could not change camera state.';
  static const errCamSwitch = 'Could not switch camera.';
  static const errSpeakerSwitch = 'Could not switch audio output.';
  static const errCallNotConfigured = 'Calling is not available right now.';
  static const outputSpeaker = 'speaker';
  static const outputEarpiece = 'earpiece';
  static String waitingPeer(String name) => 'Waiting for $name to join…';
  static String peerLeft(String name) => '$name left the call';
  static String errOutputMissing(String output) => 'No $output output available.';
  static String soFar(num cost) => '${money(cost)} so far';
  static String timerWithCost(String time, num cost) => '$time  •  ${money(cost)}';
}
