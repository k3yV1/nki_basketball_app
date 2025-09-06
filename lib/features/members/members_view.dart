import 'package:flutter/material.dart';
import 'package:nki_basketball/data/models/member_model.dart';
import 'package:nki_basketball/services/subscriptions/subscriptions_service.dart';
import 'package:nki_basketball/services/queue/queue_service.dart';

class MembersView extends StatefulWidget {
  final DateTime date;
  final String type;

  const MembersView({
    Key? key,
    required this.date,
    required this.type,
  }) : super(key: key);

  @override
  State<MembersView> createState() => _MembersViewState();
}

class _MembersViewState extends State<MembersView> {
  final _subscriptionsService = SubscriptionsService();
  final _queueService = QueueService();

  List<Member> _members = [];
  List<String> _queue = [];
  bool _isLoading = true;

  late String _userId;
  late String _trainingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _userId = args?['id']?.toString() ?? "UNKNOWN_USER";
      _trainingId = args?['trainingId']?.toString() ?? "1"; // ⚡️ временно "1", лучше передавать из HomeView
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    try {
      final subscriptions = await _subscriptionsService.fetchSubscriptions();
      final members = subscriptions
          .where((s) => s.isPaid)
          .map((s) => Member(name: '${s.name} ${s.last_name}', isReady: s.is_ready))
          .toList();

      final queue = await _queueService.getQueue(widget.date);

      setState(() {
        _members = members;
        _queue = queue;
        _isLoading = false;
      });
    } catch (e) {
      print("Ошибка: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinQueue() async {
    try {
      await _queueService.addToQueue(_trainingId, _userId, widget.date);
      await _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _leaveQueue() async {
    try {
      await _queueService.removeFromQueue(_userId, widget.date);
      await _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
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
        height: double.infinity,
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
                                            color: m.isReady
                                                ? Colors.greenAccent
                                                : Colors.redAccent,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            m.name,
                                            style: const TextStyle(
                                                color: Colors.white, fontSize: 16),
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
                                ..._queue.map((name) => Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.hourglass_empty,
                                              color: Colors.white),
                                          const SizedBox(width: 12),
                                          Text(
                                            name,
                                            style: const TextStyle(
                                                color: Colors.white, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    )),
                                const SizedBox(height: 24),
                                Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white, // чёрный фон
                                      foregroundColor: Colors.black, // белый текст
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: _joinQueue,
                                    child: const Text(
                                      "Встать в очередь",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white, // чёрный фон
                                      foregroundColor: Colors.black, // белый текст
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: _leaveQueue,
                                    child: const Text(
                                      "Выйти из очереди",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

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
