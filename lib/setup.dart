import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/history.dart';
import 'package:myapp/main.dart';
import 'package:myapp/setup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(myApp());
}

class Item {
  final String title;
  final String description;
  final IconData icon;
  final String image;

  Item({
    required this.title,
    required this.description,
    required this.icon,
    required this.image,
  });
}

List<HistoryItem> historyList = [];

class SetupPage extends StatelessWidget {
  final List<Item> items = [
    Item(
        title: 'Black Jack',
        description: 'Card',
        icon: Icons.casino_sharp,
        image: 'images/blackjack.png'),
    Item(
        title: 'Poker',
        description: 'Card',
        icon: Icons.casino,
        image: 'images/poker.png'),
    Item(
        title: 'Slot',
        description: 'Casino',
        icon: Icons.games,
        image: 'images/slot.png'),
    Item(
        title: 'Roulette',
        description: 'Casino',
        icon: Icons.casino,
        image: 'images/roulette.png'),
    Item(
        title: 'Loterry',
        description: 'Lottery',
        icon: Icons.monetization_on,
        image: 'images/lottery.png'),
    Item(
        title: 'BigSmall',
        description: 'Casino',
        icon: Icons.casino,
        image: 'images/bigsmall.png'),
    Item(
        title: 'Cow',
        description: 'Card',
        icon: Icons.casino,
        image: 'images/blackjack.png'),
    Item(
        title: 'Goal',
        description: 'Card',
        icon: Icons.casino,
        image: 'images/poker.png'),
    Item(
        title: 'Television',
        description: 'Casino',
        icon: Icons.casino,
        image: 'images/slot.png'),
    Item(
        title: 'Baccarat',
        description: 'Casino',
        icon: Icons.casino,
        image: 'images/roulette.png'),
    Item(
        title: 'Sic BO',
        description: 'Casino',
        icon: Icons.casino,
        image: 'images/roulette.png'),
    Item(
        title: 'Pai Gow',
        description: 'Card',
        icon: Icons.abc,
        image: 'images/blackjack.png'),
  ];

  final double betlimit;

  SetupPage({
    required this.betlimit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item List'),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 0.0,
          crossAxisSpacing: 0.0,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailsPage(
                    item: item,
                    betlimit: betlimit,
                    userEmail: '',
                  ),
                ),
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: 24.0,
                    color: Colors.cyan,
                  ),
                  SizedBox(height: 0.0),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      child: Image.asset(
                        item.image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 0.0),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 0.0),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ItemDetailsPage extends StatefulWidget {
  final Item item;
  final double betlimit;
  final String userEmail;

  const ItemDetailsPage({
    required this.item,
    required this.betlimit,
    required this.userEmail,
  });

  @override
  _ItemDetailsPageState createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  static double totalBetAmount = 0.0;
  TextEditingController _betAmountController = TextEditingController();
  bool isWin = false;

  @override
  void dispose() {
    _betAmountController.dispose();
    super.dispose();
  }

  void showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alert'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<List<HistoryItem>> fetchHistoryItems(String userEmail) async {
    final CollectionReference historyCollection =
        FirebaseFirestore.instance.collection(userEmail + 'history');

    final QuerySnapshot querySnapshot = await historyCollection.get();

    List<HistoryItem> fetchedHistoryList = [];
    querySnapshot.docs.forEach((doc) {
      final Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

      if (data != null) {
        final String? details = data['details'] as String?;
        final double? betAmount = data['betAmount']?.toDouble();
        final int? colorValue = data['color'] as int?;

        if (details != null && betAmount != null && colorValue != null) {
          final Color color = Color(colorValue);

          final HistoryItem historyItem = HistoryItem(
            details: details,
            betAmount: betAmount,
            betLimit: widget.betlimit,
            isWin: isWin,
          );

          fetchedHistoryList.add(historyItem);
        }
      }
    });

    return fetchedHistoryList;
  }

  Future<void> showHistoryPage(bool isWin) async {
    try {
      final String selectedItemDetails =
          '${widget.item.title} - ${widget.item.description}';
      final double betAmount =
          double.tryParse(_betAmountController.text) ?? 0.0;
      final String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
      this.isWin = isWin;

      if (totalBetAmount + betAmount <= widget.betlimit) {
        final bool isWinValue = isWin;
        final HistoryItem historyItem = HistoryItem(
          details: selectedItemDetails,
          betAmount: betAmount,
          betLimit: widget.betlimit,
          isWin: isWinValue,
        );

        final CollectionReference historyCollection =
            FirebaseFirestore.instance.collection(userEmail + ' history');
        await historyCollection.add({
          'details': historyItem.details,
          'betAmount': historyItem.betAmount,
          'betLimit': historyItem.betLimit,
          'isWin': historyItem.isWin,
        });

        totalBetAmount += betAmount;

        if (totalBetAmount > widget.betlimit) {
          showAlertDialog(
              'Bet amount has reached the limit ${widget.betlimit.toStringAsFixed(2)}');
        } else {
          final List<HistoryItem> historyList =
              await fetchHistoryItems(userEmail);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HistoryPage(
                userEmail: FirebaseAuth.instance.currentUser?.email ?? '',
              ),
            ),
          );
        }
      } else {
        showAlertDialog(
            'Bet amount exceeds the bet limit ${widget.betlimit.toStringAsFixed(2)}');
      }
    } catch (error) {
      print('Error storing history in Firestore: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showHistoryPage(true);
                    });
                  },
                  style: ElevatedButton.styleFrom(primary: Colors.green),
                  child: Text('Win'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showHistoryPage(false);
                    });
                  },
                  style: ElevatedButton.styleFrom(primary: Colors.red),
                  child: Text('Lose'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _betAmountController,
                decoration: InputDecoration(
                  labelText: '$totalBetAmount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
