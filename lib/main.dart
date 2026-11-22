import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/board_service.dart';
import 'models/board_message.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Vaultboard());
}

class Vaultboard extends StatelessWidget {
  const Vaultboard({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Vaultboard',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff146b62)),
      scaffoldBackgroundColor: const Color(0xfff3f5f1),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        filled: true,
      ),
    ),
    home: const Splash(),
  );
}

class Splash extends StatefulWidget {
  const Splash({super.key, this.initializer});
  final Future<void> Function()? initializer;
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  late Future<void> initialization;
  @override
  void initState() {
    super.initState();
    initialization = startInitialization();
  }

  Future<void> startInitialization() {
    final future = Future.wait<void>([
      (widget.initializer ?? initialize)(),
      Future<void>.delayed(const Duration(milliseconds: 900)),
    ]).then<void>((_) {});
    // Attach an error handler immediately, before FutureBuilder rebuilds.
    future.ignore();
    return future;
  }

  Future<void> initialize() async {
    if (const bool.fromEnvironment('USE_EMULATORS')) {
      final app =
          Firebase.apps.where((a) => a.name == 'demo-vaultboard').firstOrNull ??
          await Firebase.initializeApp(demoProjectId: 'demo-vaultboard');
      const host = String.fromEnvironment(
        'EMULATOR_HOST',
        defaultValue: '10.0.2.2',
      );
      await FirebaseAuth.instanceFor(app: app).useAuthEmulator(host, 9099);
      FirebaseFirestore.instanceFor(app: app).useFirestoreEmulator(host, 8080);
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: initialization,
    builder: (context, s) {
      if (s.connectionState == ConnectionState.done && !s.hasError) {
        return AuthGate(
          auth: AuthService(
            FirebaseAuth.instanceFor(
              app: Firebase.app(
                const bool.fromEnvironment('USE_EMULATORS')
                    ? 'demo-vaultboard'
                    : '[DEFAULT]',
              ),
            ),
            FirebaseFirestore.instanceFor(
              app: Firebase.app(
                const bool.fromEnvironment('USE_EMULATORS')
                    ? 'demo-vaultboard'
                    : '[DEFAULT]',
              ),
            ),
          ),
        );
      }
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 72,
                  color: Color(0xff146b62),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Vaultboard',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const Text('A shared space. Your words, protected.'),
                const SizedBox(height: 28),
                if (s.connectionState == ConnectionState.done &&
                    s.hasError) ...[
                  const Text(
                    'Unable to connect to Firebase. Check your connection and app configuration.',
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      initialization = startInitialization();
                    }),
                    child: const Text('Retry'),
                  ),
                ] else
                  const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class AuthGate extends StatelessWidget {
  final AuthService auth;
  const AuthGate({super.key, required this.auth});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: auth.authState,
    builder: (context, s) {
      if (s.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (s.data == null) return AuthForm(auth: auth);
      return ProfileGate(key: ValueKey(s.data!.uid), auth: auth);
    },
  );
}

class ProfileGate extends StatefulWidget {
  final AuthService auth;
  const ProfileGate({super.key, required this.auth});
  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  late final stream = widget.auth.profile();
  @override
  Widget build(BuildContext context) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, s) {
          if (s.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(friendlyError(s.error!)),
                    TextButton(
                      onPressed: widget.auth.signOut,
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!s.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!s.data!.exists) {
            return AuthForm(auth: widget.auth, profileOnly: true);
          }
          final p = s.data!.data()!;
          return BoardScreen(
            auth: widget.auth,
            name: '${p['firstName']} ${p['lastName']}',
          );
        },
      );
}

class AuthForm extends StatefulWidget {
  final AuthService auth;
  final bool profileOnly;
  const AuthForm({super.key, required this.auth, this.profileOnly = false});
  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final form = GlobalKey<FormState>();
  final first = TextEditingController(),
      last = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool registering = false, busy = false;
  String? error;
  @override
  void dispose() {
    for (final c in [first, last, email, password, confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    final firstName = first.text;
    final lastName = last.text;
    try {
      if (widget.profileOnly) {
        await widget.auth.saveProfile(firstName, lastName);
      } else if (registering) {
        await widget.auth.register(email.text, password.text);
        await widget.auth.saveProfile(firstName, lastName);
      } else {
        await widget.auth.signIn(email.text, password.text);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = widget.auth.currentUser != null
              ? 'Your account exists. Complete your profile using the same account. ${friendlyError(e)}'
              : friendlyError(e),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Widget field(
    String label,
    TextEditingController c, {
    bool secret = false,
    bool mail = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: c,
      obscureText: secret,
      enabled: !busy,
      keyboardType: mail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Enter $label';
        if (mail && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) {
          return 'Enter a valid email';
        }
        if (secret && v.length < 6) return 'Use at least 6 characters';
        if (label == 'Confirm password' && v != password.text) {
          return 'Passwords must match';
        }
        if ((label == 'First name' || label == 'Last name') &&
            v.trim().length > 60) {
          return 'Use 60 characters or fewer';
        }
        return null;
      },
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: Color(0xff146b62),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.profileOnly
                        ? 'Finish your profile'
                        : registering
                        ? 'Join Vaultboard'
                        : 'Welcome to Vaultboard',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.profileOnly
                        ? 'Your account is ready. Save your name to enter the board.'
                        : 'One board. A place for every voice.',
                  ),
                  const SizedBox(height: 28),
                  if (registering || widget.profileOnly) ...[
                    field('First name', first),
                    field('Last name', last),
                  ],
                  if (!widget.profileOnly) ...[
                    field('Email', email, mail: true),
                    field('Password', password, secret: true),
                    if (registering)
                      field('Confirm password', confirm, secret: true),
                  ],
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  FilledButton(
                    onPressed: busy ? null : submit,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.profileOnly
                                  ? 'Save profile / Retry'
                                  : registering
                                  ? 'Create account'
                                  : 'Sign in',
                            ),
                    ),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : widget.profileOnly
                        ? widget.auth.signOut
                        : () => setState(() {
                            registering = !registering;
                            error = null;
                          }),
                    child: Text(
                      widget.profileOnly
                          ? 'Sign out'
                          : registering
                          ? 'Already a member? Sign in'
                          : 'Create an account',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class BoardScreen extends StatefulWidget {
  final AuthService auth;
  final String name;
  final BoardService? boardService;
  const BoardScreen({
    super.key,
    required this.auth,
    required this.name,
    this.boardService,
  });
  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  late final service =
      widget.boardService ??
      BoardService(widget.auth.db, widget.auth.currentUser!.uid, widget.name);
  late final stream = service.messageBoard();
  final composer = TextEditingController();
  bool busy = false, pending = false, ready = false;
  String? error;
  @override
  void initState() {
    super.initState();
    restore();
  }

  Future<void> restore() async {
    try {
      final p = await service.pending();
      if (mounted) {
        setState(() {
          if (p != null) {
            composer.text = p['text'];
            pending = true;
          }
          ready = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = friendlyError(e));
      }
    }
  }

  @override
  void dispose() {
    composer.dispose();
    super.dispose();
  }

  Future<void> post() async {
    if (busy || composer.text.trim().isEmpty || !ready) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await service.postMessage(composer.text);
      if (mounted) {
        composer.clear();
        setState(() => pending = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          pending = true;
          error = friendlyError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> modify(BoardMessage m, bool delete) async {
    final input = TextEditingController(text: m.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(delete ? 'Delete this message?' : 'Edit message'),
        content: delete
            ? const Text('This cannot be undone.')
            : TextField(
                controller: input,
                maxLength: 2000,
                minLines: 2,
                maxLines: 6,
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (delete || input.text.trim().isNotEmpty) {
                Navigator.pop(ctx, delete ? 'delete' : input.text);
              }
            },
            child: Text(delete ? 'Delete' : 'Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      try {
        if (delete) {
          await service.deleteMessage(m.id);
        } else {
          await service.editMessage(m.id, result);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
        }
      }
    }
    // Dialog exit animation may still use its controller; defer disposal.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Vaultboard'),
      actions: [
        IconButton(
          tooltip: 'Sign out',
          onPressed: busy ? null : widget.auth.signOut,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.person_outline)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'COMMUNITY BOARD · LIVE',
                            style: TextStyle(fontSize: 11, letterSpacing: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<BoardMessage>>(
                  stream: stream,
                  builder: (context, s) {
                    if (s.hasError) {
                      return Center(child: Text(friendlyError(s.error!)));
                    }
                    if (!s.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (s.data!.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.forum_outlined, size: 56),
                            SizedBox(height: 16),
                            Text(
                              'Start the conversation',
                              style: TextStyle(fontSize: 22),
                            ),
                            Text(
                              'Share the first message with your community.',
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: s.data!.length,
                      itemBuilder: (context, i) {
                        final m = s.data![i];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m.authorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (m.authorUid ==
                                        widget.auth.currentUser!.uid)
                                      PopupMenuButton<bool>(
                                        onSelected: (v) => modify(m, v),
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: false,
                                            child: Text('Edit'),
                                          ),
                                          PopupMenuItem(
                                            value: true,
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                Text(
                                  m.text,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${m.createdAt?.toLocal().toString().substring(0, 16) ?? 'Saving…'}${m.editedAt == null ? '' : ' · Edited'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (error != null)
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    if (pending)
                      const Text(
                        'Pending post preserved. Reconnect and retry this submission.',
                      ),
                    TextField(
                      controller: composer,
                      enabled: ready && !busy && !pending,
                      maxLength: 2000,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Share something with the board…',
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: busy || !ready ? null : post,
                      icon: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(
                        pending ? 'Retry pending post' : 'Post message',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
