import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryPage extends StatefulWidget {
  final String userEmail;

  HistoryPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late CollectionReference<Map<String, dynamic>> _historyCollection;

  @override
  void initState() {
    super.initState();
    _historyCollection =
        FirebaseFirestore.instance.collection(widget.userEmail + ' history');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userEmail + 'History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _historyCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          if (snapshot.data?.docs.isEmpty ?? true) {
            return Center(
              child: Text('No history data found.'),
            );
          }

          return ListView.builder(
              itemCount: snapshot.data?.docs.length,
              itemBuilder: (context, index) {
                var data =
                    snapshot.data?.docs[index].data() as Map<String, dynamic>?;

                var details = data?['details'];
                var betLimit = data?['betLimit'];
                var betAmount = data?['betAmount'];
                var isWin = data?['isWin'];

                var resultText = isWin == true ? 'Win' : 'Lose';
                var resultColor = isWin == true ? Colors.green : Colors.red;

                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2.0),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    title: Text(details ?? ''),
                    subtitle: Text(
                      'Bet Limit: ${betLimit ?? ''}, Bet Amount: ${betAmount ?? ''}, Result: ${resultText}',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    tileColor: resultColor,
                  ),
                );
              });
        },
      ),
    );
  }
}

class HistoryItem {
  final String details;
  final double betAmount;
  final double betLimit;
  final bool isWin;

  HistoryItem({
    required this.details,
    required this.betAmount,
    required this.betLimit,
    required this.isWin,
  });

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      details: map['details'] ?? '',
      betAmount: map['betAmount'] ?? 0.0,
      betLimit: map['betLimit'] ?? 0.0,
      isWin: map['isWin'] ?? false,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final User? user = FirebaseAuth.instance.currentUser;
  final String? userEmail = user?.email;

  runApp(MaterialApp(
    home: HistoryPage(
      userEmail: userEmail ?? '',
    ),
  ));
}
