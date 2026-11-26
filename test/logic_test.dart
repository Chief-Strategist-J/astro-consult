import 'package:astro_app/app_constants.dart';
import 'package:astro_app/features/astrologer_dashboard/astrologer_dashboard_state.dart';
import 'package:astro_app/features/astrologer_profile/astrologer_profile_model.dart';
import 'package:astro_app/features/astrologer_profile/astrologer_profile_state.dart';
import 'package:astro_app/features/astrologers/astrologers_model.dart';
import 'package:astro_app/features/astrologers/astrologers_state.dart';
import 'package:astro_app/features/auth/auth_model.dart';
import 'package:astro_app/features/auth/auth_state.dart';
import 'package:astro_app/features/chat/chat_model.dart';
import 'package:astro_app/features/home/home_model.dart';
import 'package:astro_app/features/home/home_state.dart';
import 'package:astro_app/features/profile/profile_model.dart';
import 'package:astro_app/features/profile/profile_state.dart';
import 'package:astro_app/features/session/session_model.dart';
import 'package:astro_app/features/session/session_state.dart';
import 'package:flutter_test/flutter_test.dart';

Astrologer astro(String id,
        {String name = 'Name',
        double rating = 4,
        double price = 10,
        int exp = 5,
        Availability status = Availability.online,
        List<String> expertise = const ['Vedic']}) =>
    Astrologer(
      id: id,
      name: name,
      avatar: '',
      expertise: expertise,
      languages: const ['Hindi'],
      experience: exp,
      rating: rating,
      reviews: 1,
      pricePerMin: price,
      status: status,
      about: '',
    );

ConsultSession session({double price = 20, SessionStatus status = SessionStatus.ongoing, String id = 's1', DateTime? at}) => ConsultSession(
      id: id,
      userId: 'u1',
      userName: 'Alice',
      astrologerId: 'a1',
      astrologerName: 'A',
      astrologerAvatar: '',
      type: ConsultType.chat,
      status: status,
      createdAt: at ?? DateTime(2026),
      durationSec: 0,
      cost: 0,
      pricePerMin: price,
    );

void main() {
  group('UserModel.isProfileComplete', () {
    test('false when birth details are missing or empty', () {
      expect(const UserModel(id: 'u', name: 'Aarav', phone: '+91').isProfileComplete, isFalse);
      expect(
        const UserModel(id: 'u', name: 'Aarav', phone: '+91', dob: '', birthTime: '09:30', birthPlace: 'Jaipur')
            .isProfileComplete,
        isFalse,
      );
    });

    test('false when name is blank, true when everything is present', () {
      expect(
        const UserModel(id: 'u', name: ' ', phone: '+91', dob: '1990-01-01', birthTime: '09:30', birthPlace: 'Jaipur')
            .isProfileComplete,
        isFalse,
      );
      expect(
        const UserModel(id: 'u', name: 'Aarav', phone: '+91', dob: '1990-01-01', birthTime: '09:30', birthPlace: 'Jaipur')
            .isProfileComplete,
        isTrue,
      );
    });
  });

  group('AuthState validation', () {
    test('errors stay hidden until showErrors is set', () {
      const s = AuthState(phone: '123');
      expect(s.phoneError, isNull);
      expect(s.copyWith(showErrors: true).phoneError, AppStrings.errPhone);
    });

    test('valid phone and otp pass; name only required for sign up', () {
      final s = AuthState(showErrors: true, phone: '9' * AppConfig.phoneLength, otp: '1' * AppConfig.otpLength);
      expect(s.phoneError, isNull);
      expect(s.otpError, isNull);
      expect(s.nameError, isNull);
      expect(s.copyWith(isSignUp: true).nameError, AppStrings.errName);
    });
  });

  group('ProfileState', () {
    test('valid only when every field is filled', () {
      const empty = ProfileState();
      expect(empty.valid, isFalse);
      expect(empty.copyWith(showErrors: true).dobError, AppStrings.errDob);
      const full = ProfileState(name: 'Aarav', dob: '1990-01-01', birthTime: '09:30', birthPlace: 'Jaipur');
      expect(full.valid, isTrue);
    });

    test('ProfileForm maps to Firestore field names', () {
      const f = ProfileForm(name: 'A', dob: 'd', birthTime: 't', birthPlace: 'p');
      expect(f.toMap(), {Db.name: 'A', Db.dob: 'd', Db.birthTime: 't', Db.birthPlace: 'p'});
    });
  });

  group('AstrologersState', () {
    final items = [
      astro('a', name: 'Asha', rating: 4.9, price: 40, exp: 20),
      astro('b', name: 'Bala', rating: 4.1, price: 10, exp: 3, status: Availability.offline, expertise: const ['Tarot']),
      astro('c', name: 'Chitra', rating: 4.5, price: 25, exp: 9, expertise: const ['Tarot']),
    ];

    test('sorts and filters', () {
      final s = AstrologersState(items: items);
      expect(s.visible.map((a) => a.id), ['a', 'c', 'b']);
      expect(s.copyWith(sort: AstrologerSort.priceLow).visible.map((a) => a.id), ['b', 'c', 'a']);
      expect(s.copyWith(onlyOnline: true).visible.map((a) => a.id), ['a', 'c']);
      expect(s.copyWith(expertise: 'Tarot').visible.map((a) => a.id), ['c', 'b']);
      expect(s.copyWith(query: 'chit').visible.map((a) => a.id), ['c']);
      expect(s.allExpertise, ['Tarot', 'Vedic']);
    });
  });

  group('Session', () {
    test('formatDuration', () {
      expect(formatDuration(0), '00:00');
      expect(formatDuration(65), '01:05');
      expect(formatDuration(3725), '01:02:05');
    });

    test('running cost rounds up to the next started minute', () {
      expect(SessionState(session: session(price: 20), elapsed: 61).runningCost, 40);
      expect(SessionState(session: session(), elapsed: 0).runningCost, 0);
      expect(const SessionState().runningCost, 0);
    });
  });

  group('ChatMessage', () {
    test('delivery state affects equality', () {
      final t = DateTime(2026);
      final pending = ChatMessage(id: '1', text: 'hi', fromMe: true, time: t, sent: false);
      final sent = ChatMessage(id: '1', text: 'hi', fromMe: true, time: t);
      expect(pending == sent, isFalse);
    });
  });

  group('AppStrings', () {
    test('formatters', () {
      expect(AppStrings.perMinute(25), '₹25/min');
      expect(AppStrings.moneyExact(40), '₹40.00');
      expect(AppStrings.reviewTitle('Priya', 3), 'Priya  ★★★');
    });
  });

  group('Roles', () {
    test('tabs differ per role and navigation starts on the first tab', () {
      expect(HomeTabInfo.forRole(UserRole.user), [HomeTab.astrologers, HomeTab.history, HomeTab.profile]);
      expect(HomeTabInfo.forRole(UserRole.astrologer), [HomeTab.dashboard, HomeTab.profile]);
      final s = HomeState(tabs: HomeTabInfo.forRole(UserRole.astrologer));
      expect(s.tab, HomeTab.dashboard);
      expect(s.copyWith(tab: HomeTab.profile).index, 1);
    });

    test('astrologer accounts skip the user birth-details gate', () {
      expect(const UserModel(id: 'a', name: 'R', phone: '+91', role: UserRole.astrologer).isProfileComplete, isTrue);
      expect(const UserModel(id: 'u', name: 'R', phone: '+91').isProfileComplete, isFalse);
    });

    test('AuthState carries the chosen portal and gates readiness', () {
      const s = AuthState();
      expect(s.role, UserRole.user);
      expect(s.copyWith(role: UserRole.astrologer).role, UserRole.astrologer);
      expect(s.astrologerReady, isFalse);
      expect(s.copyWith(astrologerReady: true).astrologerReady, isTrue);
    });

    test('a session shows the other party to each side', () {
      final s = session();
      expect(s.isAstrologer('a1'), isTrue);
      expect(s.isAstrologer('u1'), isFalse);
      expect(s.counterpartName('a1'), 'Alice'); // astrologer sees the client
      expect(s.counterpartName('u1'), 'A'); // client sees the astrologer
      expect(s.counterpartAvatar('a1'), isEmpty); // users have no photo
    });
  });

  group('AstrologerProfileState', () {
    test('parseList trims and drops empties', () => expect(parseList(' Vedic, ,Tarot ,'), ['Vedic', 'Tarot']));

    test('validation rules', () {
      const ok = AstrologerProfileState(
          name: 'Ravi', expertise: 'Vedic', languages: 'Hindi', experience: '7', price: '30', loading: false);
      expect(ok.valid, isTrue);
      expect(ok.copyWith(name: 'R').valid, isFalse);
      expect(ok.copyWith(expertise: ' , ').valid, isFalse);
      expect(ok.copyWith(expertise: 'a,b,c,d,e,f,g').valid, isFalse);
      expect(ok.copyWith(experience: '81').valid, isFalse);
      expect(ok.copyWith(experience: '').valid, isFalse);
      expect(ok.copyWith(price: '0').valid, isFalse);
      expect(ok.copyWith(price: '1001').valid, isFalse);
      expect(ok.copyWith(price: '12.5').valid, isTrue);
      expect(ok.copyWith(avatar: 'http://x').valid, isFalse);
      expect(ok.copyWith(avatar: 'https://x/y.png').valid, isTrue);
      expect(ok.copyWith(about: 'x' * 501).valid, isFalse);
    });

    test('errors appear only after a save attempt and the payload matches the function contract', () {
      const bad = AstrologerProfileState(loading: false);
      expect(bad.priceError, isNull);
      expect(bad.copyWith(showErrors: true).priceError, AppStrings.errPrice);
      const ok = AstrologerProfileState(
          name: ' Ravi ', expertise: 'Vedic, Career', languages: 'Hindi', experience: '7', price: '30', about: ' hi ', loading: false);
      expect(ok.toForm().toMap(), {
        Fn.argName: 'Ravi',
        Fn.argAvatar: '',
        Fn.argExpertise: ['Vedic', 'Career'],
        Fn.argLanguages: ['Hindi'],
        Fn.argExperience: 7,
        Fn.argPricePerMin: 30,
        Fn.argAbout: 'hi',
      });
    });
  });

  group('AstrologerDashboardState', () {
    test('partitions consultations into requests, active and history', () {
      final s = AstrologerDashboardState(sessions: [
        session(id: 'w2', status: SessionStatus.waiting, at: DateTime(2026, 1, 2)),
        session(id: 'w1', status: SessionStatus.waiting, at: DateTime(2026, 1, 1)),
        session(id: 'on', status: SessionStatus.ongoing),
        session(id: 'h1', status: SessionStatus.completed, at: DateTime(2025, 12, 1)),
        session(id: 'h2', status: SessionStatus.rejected, at: DateTime(2025, 12, 5)),
        session(id: 'h3', status: SessionStatus.cancelled, at: DateTime(2025, 11, 1)),
      ]);
      expect(s.requests.map((x) => x.id), ['w1', 'w2'], reason: 'oldest request first');
      expect(s.active?.id, 'on');
      expect(s.history.map((x) => x.id), ['h2', 'h1', 'h3'], reason: 'newest first, declined included');
      expect(const AstrologerDashboardState().active, isNull);
    });
  });
}
