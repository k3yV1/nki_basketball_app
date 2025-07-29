import 'package:flutter/material.dart';
import 'package:nki_basketball/data/models/member_model.dart';
import 'package:nki_basketball/services/subscriptions/subscriptions_service.dart';

class MembersView extends StatefulWidget {
  final DateTime date;
  final String type;
  final List<String> queue;

  const MembersView({
    Key? key,
    required this.date,
    required this.type,
    required this.queue,
  }) : super(key: key);

  @override
  State<MembersView> createState() => _MembersViewState();
}

class _MembersViewState extends State<MembersView> {
  final _subscriptionsService = SubscriptionsService();
  List<Member> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    final subscriptions = await _subscriptionsService.fetchSubscriptions();
    final members = subscriptions
        .where((s) => s.isPaid)
        .map((s) => Member(name: '${s.name} ${s.last_name}', isReady: s.is_ready))
        .toList();

    setState(() {
      _members = members;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          '${widget.type} — ${widget.date.day}.${widget.date.month}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
  height: double.infinity, // Тянем фон на весь экран
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xff2c5364),
        Color(0xff203e43),
        Color(0xff0f2027),
      ],
    ),
  ),
  child: SafeArea(
    child: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Участники:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/teams'),
                                child: const Text(
                                  'Команды',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._members.map((m) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      m.isReady ? Icons.check_circle : Icons.cancel,
                                      color: m.isReady ? Colors.greenAccent : Colors.redAccent,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      m.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 24),
                          const Text(
                            'Очередь:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...widget.queue.map((name) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.hourglass_empty, color: Colors.white),
                                    const SizedBox(width: 12),
                                    Text(
                                      name,
                                      style: const TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                  ],
                                ),
                              )),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
  ),
),

    );
  }
}
