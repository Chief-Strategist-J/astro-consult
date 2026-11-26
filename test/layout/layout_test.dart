// Renders every page with realistic data at several screen sizes / themes / text scales.
// Fails on any overflow or exception and writes a PNG of each render to $SHOT_DIR (default build/layout_shots)
// so alignment can be reviewed visually.   flutter test test/layout/layout_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:astro_app/features/astrologer_dashboard/astrologer_dashboard_model.dart';
import 'package:astro_app/features/astrologer_dashboard/astrologer_dashboard_controller.dart';
import 'package:astro_app/features/astrologer_dashboard/astrologer_dashboard_state.dart';
import 'package:astro_app/features/astrologer_dashboard/astrologer_dashboard_view.dart';
import 'package:astro_app/features/astrologer_detail/astrologer_detail_controller.dart';
import 'package:astro_app/features/astrologer_detail/astrologer_detail_model.dart';
import 'package:astro_app/features/astrologer_detail/astrologer_detail_state.dart';
import 'package:astro_app/features/astrologer_detail/astrologer_detail_view.dart';
import 'package:astro_app/features/astrologer_profile/astrologer_profile_controller.dart';
import 'package:astro_app/features/astrologer_profile/astrologer_profile_state.dart';
import 'package:astro_app/features/astrologer_profile/astrologer_profile_view.dart';
import 'package:astro_app/features/astrologers/astrologers_controller.dart';
import 'package:astro_app/features/astrologers/astrologers_model.dart';
import 'package:astro_app/features/astrologers/astrologers_state.dart';
import 'package:astro_app/features/astrologers/astrologers_view.dart';
import 'package:astro_app/features/auth/auth_controller.dart';
import 'package:astro_app/features/auth/auth_model.dart';
import 'package:astro_app/features/auth/auth_state.dart';
import 'package:astro_app/features/auth/auth_view.dart';
import 'package:astro_app/features/chat/chat_controller.dart';
import 'package:astro_app/features/chat/chat_model.dart';
import 'package:astro_app/features/chat/chat_state.dart';
import 'package:astro_app/features/chat/chat_view.dart';
import 'package:astro_app/features/home/home_view.dart';
import 'package:astro_app/features/profile/profile_view.dart';
import 'package:astro_app/features/session/session_controller.dart';
import 'package:astro_app/features/session/session_model.dart';
import 'package:astro_app/features/session/session_state.dart';
import 'package:astro_app/features/session/session_view.dart';
import 'package:astro_app/features/theme/theme_controller.dart';
import 'package:astro_app/features/theme/theme_view.dart';
import 'package:astro_app/features/video_call/video_call_controller.dart';
import 'package:astro_app/features/video_call/video_call_model.dart';
import 'package:astro_app/features/video_call/video_call_state.dart';
import 'package:astro_app/features/video_call/video_call_view.dart';
import 'package:astro_app/features/voice_call/voice_call_controller.dart';
import 'package:astro_app/features/voice_call/voice_call_model.dart';
import 'package:astro_app/features/voice_call/voice_call_state.dart';
import 'package:astro_app/features/voice_call/voice_call_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

// ---- cubits seeded with a state (no Firebase) ----
class _Auth extends AuthCubit {
  _Auth(AuthState s) {
    emit(s);
  }
}

class _Session extends SessionCubit {
  _Session(SessionState s) {
    emit(s);
  }
}

class _Astros extends AstrologersCubit {
  _Astros(AstrologersState s) {
    emit(s);
  }
  @override
  Future<void> load() async {}
}

// ---- fixtures ----
const user = UserModel(id: 'u1', name: 'Alice Sharma', phone: '+910123456789', dob: '1994-08-15', birthTime: '06:45', birthPlace: 'Jaipur');
const astroUser = UserModel(id: 'a9', name: 'Ravi Kumar', phone: '+910123456780', role: UserRole.astrologer);

Astrologer astro(String id, String name, Availability st, {List<String> exp = const ['Vedic', 'Career'], double price = 25, int years = 14}) => Astrologer(
    id: id, name: name, avatar: '', expertise: exp, languages: const ['Hindi', 'English'], experience: years, rating: 4.8, reviews: 2310,
    pricePerMin: price, status: st, about: 'Vedic astrologer specialising in career and finance guidance with many years of practice helping clients.');

final catalogue = [
  astro('a1', 'Acharya Rohit Sharma', Availability.online),
  astro('a2', 'Pt. Venkatasubramaniam Raghunathan Iyer-Bhattacharya', Availability.online, exp: const ['Vedic', 'Numerology', 'Marriage', 'Career', 'Health'], price: 1000, years: 40),
  astro('a3', 'Meera', Availability.busy, price: 8),
  astro('a4', 'Guru Vikram Singh', Availability.offline, price: 30),
];

ConsultSession sess({ConsultType type = ConsultType.chat, SessionStatus st = SessionStatus.ongoing, String name = 'Acharya Rohit Sharma', String client = 'Alice Sharma', int dur = 125, double cost = 75, DateTime? at, String id = 's'}) =>
    ConsultSession(id: id, userId: 'u1', userName: client, userDob: '1994-08-15', userBirthTime: '06:45', userBirthPlace: 'Jaipur', astrologerId: 'a9', astrologerName: name,
        astrologerAvatar: '', type: type, status: st, createdAt: at ?? DateTime(2026, 11, 26, 14, 5), durationSec: dur, cost: cost, pricePerMin: 25);

final t0 = DateTime(2026, 11, 26, 14, 5);
List<ChatMessage> chatMsgs() => [
      ChatMessage(id: '5', text: 'Sending this one now', fromMe: true, time: t0, sent: false),
      ChatMessage(id: '4', text: 'It is a very long message to check how the bubble wraps across several lines when the astrologer writes a detailed answer about planetary positions and timing.', fromMe: false, time: t0),
      ChatMessage(id: '3', text: 'Thanks!', fromMe: true, time: t0),
      ChatMessage(id: '2', text: 'Namaste Alice. Jupiter supports a move this year.', fromMe: false, time: t0),
      ChatMessage(id: '1', text: 'Namaste, will I change jobs?', fromMe: true, time: t0),
    ];

// ---- harness ----
const phone = Size(390, 844), small = Size(320, 640), tablet = Size(834, 1112), landscape = Size(844, 390);
final shotDir = Platform.environment['SHOT_DIR'] ?? 'build/layout_shots';

Future<void> _font(String family, List<String> files) async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/home/btpl-lap-22/snap/flutter/common/flutter';
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(File('$root/bin/cache/artifacts/material_fonts/$f').readAsBytes().then((b) => ByteData.sublistView(b)));
  }
  await l.load();
}

class Variant {
  const Variant(this.tag, this.size, {this.dark = false, this.scale = 1});
  final String tag;
  final Size size;
  final bool dark;
  final double scale;
}

const variants = [
  Variant('phone', phone),
  Variant('small', small),
  Variant('dark', phone, dark: true),
  Variant('bigtext', phone, scale: 1.6),
  Variant('tablet', tablet),
  Variant('landscape', landscape),
];

void screen(String name, Widget Function() build, {AuthState? auth, SessionState? session, AstrologersState? astros, List<Variant> only = variants}) {
  for (final v in only) {
    testWidgets('$name [${v.tag}]', (t) async {
      t.view.devicePixelRatio = 2;
      t.view.physicalSize = Size(v.size.width * 2, v.size.height * 2);
      addTearDown(t.view.reset);
      final key = GlobalKey();
      final errors = <String>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.exceptionAsString().split('\n').first);
      addTearDown(() => FlutterError.onError = prev);

      await t.pumpWidget(RepaintBoundary(
        key: key,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
            BlocProvider<AuthCubit>(create: (_) => _Auth(auth ?? const AuthState(status: AuthStatus.authenticated, user: user))),
            BlocProvider<SessionCubit>(create: (_) => _Session(session ?? const SessionState())),
            BlocProvider<AstrologersCubit>(create: (_) => _Astros(astros ?? AstrologersState(items: catalogue))),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: v.dark ? ThemeMode.dark : ThemeMode.light,
            builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(v.scale)), child: child!),
            home: build(),
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 150));
      await t.pump(const Duration(milliseconds: 150));

      await t.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await boundary.toImage(pixelRatio: 1.25);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        final f = File('$shotDir/${name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}__${v.tag}.png')..createSync(recursive: true);
        f.writeAsBytesSync(data!.buffer.asUint8List());
      });

      final ex = t.takeException();
      if (ex != null) errors.add(ex.toString().split('\n').first);
      FlutterError.onError = prev; // restore before asserting so failures are reported cleanly
      if (errors.isNotEmpty) {
        File('$shotDir/_ERRORS.txt')
          ..createSync(recursive: true)
          ..writeAsStringSync('$name [${v.tag}]: ${errors.toSet().join(' | ')}\n', mode: FileMode.append);
      }
      expect(errors, isEmpty, reason: 'layout/runtime errors on "$name" [${v.tag}]');
    });
  }
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false; // fonts are bundled in google_fonts/
    await _font('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf', 'Roboto-Light.ttf']);
    await _font('MaterialIcons', ['MaterialIcons-Regular.otf']);
  });

  const unauth = AuthState(status: AuthStatus.unauthenticated);
  // ---------- auth ----------
  screen('auth user login', () => const AuthView(), auth: unauth);
  screen('auth user signup errors', () => const AuthView(), auth: unauth.copyWith(isSignUp: true, showErrors: true, phone: '123'));
  screen('auth astrologer login', () => const AuthView(), auth: unauth.copyWith(role: UserRole.astrologer));
  screen('auth astrologer signup', () => const AuthView(), auth: unauth.copyWith(role: UserRole.astrologer, isSignUp: true, name: 'Ravi', phone: '0123456780'));
  screen('auth otp', () => const AuthView(), auth: unauth.copyWith(status: AuthStatus.otpPending, phone: '0123456789', otp: '123'));
  screen('auth loading', () => const AuthView(), auth: unauth.copyWith(loading: true, phone: '0123456789'));

  // ---------- user ----------
  screen('user home', () => const HomeView(), session: SessionState(history: [sess(st: SessionStatus.completed), sess(st: SessionStatus.cancelled, id: 'c'), sess(st: SessionStatus.rejected, id: 'r')]));
  screen('astrologers list', () => const AstrologersView());
  screen('astrologers loading', () => const AstrologersView(), astros: const AstrologersState(loading: true));
  screen('astrologers error', () => const AstrologersView(), astros: const AstrologersState(loading: false, error: 'Cannot reach the server. Check your connection.'));
  screen('astrologers no match', () => const AstrologersView(), astros: AstrologersState(items: catalogue, query: 'zzz', onlyOnline: true, expertise: 'Vedic'));
  screen('history filled', () => const HistoryView(), session: SessionState(history: [sess(st: SessionStatus.completed), sess(st: SessionStatus.cancelled, id: 'c'), sess(st: SessionStatus.rejected, id: 'r'), sess(st: SessionStatus.completed, name: 'Pt. Venkatasubramaniam Raghunathan Iyer-Bhattacharya', cost: 12500, id: 'l')]));
  screen('history empty', () => const HistoryView());
  screen('user profile setup', () => const ProfileView(setup: true), auth: const AuthState(status: AuthStatus.authenticated, user: UserModel(id: 'u', name: '', phone: '+910123456789')));
  screen('user profile edit', () => const ProfileView());
  screen('detail online', () => AstrologerDetailView(astrologer: catalogue[0], previewCubit: AstrologerDetailCubit.preview(AstrologerDetailState(astrologer: catalogue[0], loading: false, reviews: const [Review(user: 'Priya', rating: 5, text: 'Very accurate and calming session.'), Review(user: 'Arjun', rating: 4, text: 'Helpful insights on my career switch, explained very patiently over a long call.')]))));
  screen('detail busy long name', () => AstrologerDetailView(astrologer: catalogue[1], previewCubit: AstrologerDetailCubit.preview(AstrologerDetailState(astrologer: catalogue[1].copyStatus(Availability.busy), loading: false))));
  screen('detail loading', () => AstrologerDetailView(astrologer: catalogue[0], previewCubit: AstrologerDetailCubit.preview(AstrologerDetailState(astrologer: catalogue[0]))));

  // ---------- session flow ----------
  screen('session starting', () => const SessionFlowView(), session: const SessionState(phase: SessionPhase.starting));
  screen('session waiting', () => const SessionFlowView(), session: SessionState(phase: SessionPhase.waiting, session: sess(st: SessionStatus.waiting)));
  screen('session waiting reconnecting', () => const SessionFlowView(), session: SessionState(phase: SessionPhase.waiting, reconnecting: true, session: sess(st: SessionStatus.waiting, name: 'Pt. Venkatasubramaniam Raghunathan Iyer-Bhattacharya')));
  screen('session summary user', () => const SessionFlowView(), session: SessionState(phase: SessionPhase.completed, session: sess(st: SessionStatus.completed)));
  screen('session failed', () => const SessionFlowView(), session: const SessionState(phase: SessionPhase.failed, error: 'Acharya Rohit Sharma declined your request.'));

  // ---------- chat & calls ----------
  final ongoing = SessionState(phase: SessionPhase.ongoing, session: sess(), elapsed: 125);
  screen('chat user', () => ChatView(session: sess(), previewCubit: ChatCubit.preview(ChatState(messages: chatMsgs(), connected: true, peerOnline: true, typing: true))), session: ongoing);
  screen('chat astrologer', () => ChatView(session: sess(), previewCubit: ChatCubit.preview(ChatState(messages: chatMsgs(), connected: true, peerOnline: true), asAstrologer: true)), auth: const AuthState(status: AuthStatus.authenticated, user: astroUser, role: UserRole.astrologer), session: ongoing);
  screen('chat empty offline', () => ChatView(session: sess(), previewCubit: ChatCubit.preview(const ChatState())), session: ongoing);
  screen('voice connected', () => VoiceCallView(session: sess(type: ConsultType.voice), previewCubit: VoiceCallCubit.preview(const VoiceCallState(phase: CallPhase.connected, speakerOn: true))), session: ongoing);
  screen('voice waiting muted', () => VoiceCallView(session: sess(type: ConsultType.voice), previewCubit: VoiceCallCubit.preview(const VoiceCallState(phase: CallPhase.waitingForPeer, micOn: false))), session: ongoing);
  screen('voice failed', () => VoiceCallView(session: sess(type: ConsultType.voice), previewCubit: VoiceCallCubit.preview(const VoiceCallState(phase: CallPhase.failed, error: 'Call disconnected. Tap retry to rejoin.'))), session: ongoing);
  screen('video waiting', () => VideoCallView(session: sess(type: ConsultType.video), previewCubit: VideoCallCubit.preview(const VideoCallState(phase: VideoPhase.waitingForPeer))), session: ongoing);
  screen('video connected', () => VideoCallView(session: sess(type: ConsultType.video), previewCubit: VideoCallCubit.preview(const VideoCallState(phase: VideoPhase.connected, camOn: false, micOn: false))), session: ongoing);
  screen('video failed', () => VideoCallView(session: sess(type: ConsultType.video), previewCubit: VideoCallCubit.preview(const VideoCallState(phase: VideoPhase.failed, error: 'Camera and microphone permissions are required for video calls.'))), session: ongoing);

  // ---------- astrologer ----------
  const astroAuth = AuthState(status: AuthStatus.authenticated, user: astroUser, role: UserRole.astrologer);
  const account = AstrologerAccount(id: 'a9', name: 'Ravi Kumar', avatar: '', status: Availability.online, rating: 0, reviews: 0, pricePerMin: 30);
  screen('astro profile setup', () => AstrologerProfileView(setup: true, previewCubit: AstrologerProfileCubit.preview(const AstrologerProfileState(loading: false, name: 'Ravi Kumar'), _Auth(astroAuth))), auth: astroAuth);
  screen('astro profile errors', () => AstrologerProfileView(setup: true, previewCubit: AstrologerProfileCubit.preview(const AstrologerProfileState(loading: false, showErrors: true, price: '0'), _Auth(astroAuth))), auth: astroAuth);
  screen('astro profile edit', () => AstrologerProfileView(previewCubit: AstrologerProfileCubit.preview(const AstrologerProfileState(loading: false, name: 'Ravi Kumar', expertise: 'Vedic, Career', languages: 'Hindi, English', experience: '7', price: '30', about: 'Vedic astrologer for career guidance.'), _Auth(astroAuth))), auth: astroAuth);
  screen('dashboard empty offline', () => AstrologerDashboardView(previewCubit: AstrologerDashboardCubit.preview(AstrologerDashboardState(account: AstrologerAccount(id: 'a9', name: 'Ravi Kumar', avatar: '', status: Availability.offline, rating: 0, reviews: 0, pricePerMin: 30), loading: false))), auth: astroAuth);
  screen('dashboard requests', () => AstrologerDashboardView(previewCubit: AstrologerDashboardCubit.preview(AstrologerDashboardState(account: account, loading: false, sessions: [
        sess(st: SessionStatus.waiting, client: 'Alice Sharma', id: 'w1'),
        sess(st: SessionStatus.waiting, type: ConsultType.video, client: 'Bartholomew Venkatasubramaniam Raghunathan', id: 'w2', at: DateTime(2026, 11, 26, 14, 9)),
        sess(st: SessionStatus.completed, id: 'h1'),
        sess(st: SessionStatus.rejected, id: 'h2', type: ConsultType.voice),
        sess(st: SessionStatus.cancelled, id: 'h3'),
      ]))), auth: astroAuth);
  screen('dashboard busy active', () => AstrologerDashboardView(previewCubit: AstrologerDashboardCubit.preview(AstrologerDashboardState(
          account: const AstrologerAccount(id: 'a9', name: 'Ravi Kumar', avatar: '', status: Availability.busy, rating: 4.7, reviews: 12, pricePerMin: 30), loading: false, sessions: [sess(id: 'on')]))), auth: astroAuth);
  screen('dashboard loading', () => AstrologerDashboardView(previewCubit: AstrologerDashboardCubit.preview(const AstrologerDashboardState())), auth: astroAuth);
  screen('session summary astrologer', () => const SessionFlowView(), auth: astroAuth, session: SessionState(phase: SessionPhase.completed, session: sess(st: SessionStatus.completed)));
}

extension on Astrologer {
  Astrologer copyStatus(Availability s) => Astrologer(id: id, name: name, avatar: avatar, expertise: expertise, languages: languages, experience: experience, rating: rating, reviews: reviews, pricePerMin: pricePerMin, status: s, about: about);
}
