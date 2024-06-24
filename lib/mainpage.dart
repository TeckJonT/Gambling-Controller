import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/history.dart';
import 'package:myapp/main.dart';
import 'package:myapp/setup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class MainPage extends StatefulWidget {
  final String userEmail;

  MainPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  double betlimit = 0.0;
  double luckvalue = 0.0;
  List<HistoryItem> historyList = [];

  TextEditingController _betLimitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _showBetLimit();
    fetchHistoryData();
  }

  @override
  void dispose() {
    _betLimitController.dispose();
    super.dispose();
  }

  void fetchHistoryData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection(widget.userEmail + ' history')
        .get();

    setState(() {
      historyList = snapshot.docs.map((doc) {
        final data = doc.data();
        return HistoryItem(
          details: data['details'],
          betAmount: data['betAmount'],
          betLimit: data['betLimit'],
          isWin: data['isWin'],
        );
      }).toList();
    });
  }

  Widget generatebarChart(List<HistoryItem> historyList) {
    final double totalWins =
        historyList.where((item) => item.isWin).length.toDouble();
    final double totalLosses =
        historyList.where((item) => !item.isWin).length.toDouble();

    final data = [
      _ChartData('Wins', totalWins),
      _ChartData('Losses', totalLosses),
    ];

    final seriesList = [
      charts.Series<_ChartData, String>(
        id: 'BarChart',
        domainFn: (_ChartData data, _) => data.label,
        measureFn: (_ChartData data, _) => data.value,
        data: data,
        labelAccessorFn: (_ChartData data, _) => '${data.value}',
      ),
    ];

    return charts.BarChart(
      seriesList,
      animate: true,
      barGroupingType: charts.BarGroupingType.grouped,
      barRendererDecorator: charts.BarLabelDecorator(
          insideLabelStyleSpec: const charts.TextStyleSpec(
        fontSize: 12,
      )),
    );
  }

  Widget generateLineChart(List<HistoryItem> historyList) {
    final double maxBetAmount = _calculateMaxBetAmount(historyList);
    final double minBetAmount = _calculateMinBetAmount(historyList);

    final data = [
      _ChartData('Max Bet', maxBetAmount),
      _ChartData('Min Bet', minBetAmount),
    ];

    final seriesList = [
      charts.Series<dynamic, num>(
        id: 'LineChart',
        domainFn: (dynamic data, int? index) => index!.toDouble(),
        measureFn: (dynamic data, _) => data.value,
        data: data,
      ),
    ];
    return charts.LineChart(
      seriesList,
      animate: true,
    );
  }

  Widget generateRateChart(List<HistoryItem> historyList) {
    final double totalWins =
        historyList.where((item) => item.isWin).length.toDouble();
    final double winPercentage = (totalWins / historyList.length * 100);
    final double averageBetAmount = _calculateAverageBetAmount(historyList);

    final data = [
      _ChartData('Win %', winPercentage),
      _ChartData('Avg BetAmount', averageBetAmount),
    ];

    final seriesList = [
      charts.Series<_ChartData, String>(
        id: 'RateChart',
        domainFn: (_ChartData data, _) => data.label,
        measureFn: (_ChartData data, _) => data.value,
        data: data,
        labelAccessorFn: (_ChartData data, _) => '${data.value}',
      ),
    ];

    return charts.BarChart(
      seriesList,
      animate: true,
      barGroupingType: charts.BarGroupingType.grouped,
      vertical: false,
      barRendererDecorator: charts.BarLabelDecorator(
          insideLabelStyleSpec: const charts.TextStyleSpec(
        fontSize: 12,
      )),
    );
  }

  Widget generateStreakChart(List<HistoryItem> historyList) {
    List<_ChartData> streakData = [];

    int longestWinningStreak = 0;
    int currentWinningStreak = 0;
    int longestLosingStreak = 0;
    int currentLosingStreak = 0;

    for (HistoryItem item in historyList) {
      if (item.isWin) {
        currentLosingStreak = 0;
        currentWinningStreak++;
        if (currentWinningStreak > longestWinningStreak) {
          longestWinningStreak = currentWinningStreak;
        }
      } else {
        currentWinningStreak = 0;
        currentLosingStreak++;
        if (currentLosingStreak > longestLosingStreak) {
          longestLosingStreak = currentLosingStreak;
        }
      }
    }

    streakData.add(
        _ChartData('Longest Winning Streak', longestWinningStreak.toDouble()));
    streakData.add(
        _ChartData('Longest Losing Streak', longestLosingStreak.toDouble()));

    final seriesList = [
      charts.Series<_ChartData, String>(
        id: 'StreakChart',
        domainFn: (_ChartData data, _) => data.label,
        measureFn: (_ChartData data, _) => data.value,
        data: streakData,
        labelAccessorFn: (_ChartData data, _) => '${data.value}',
      ),
    ];

    return charts.BarChart(seriesList,
        animate: true,
        barGroupingType: charts.BarGroupingType.grouped,
        barRendererDecorator: charts.BarLabelDecorator(
            insideLabelStyleSpec: const charts.TextStyleSpec(
          fontSize: 12,
        )));
  }

  double _calculateAverageBetAmount(List<HistoryItem> historyList) {
    if (historyList.isEmpty) return 0.0;

    final totalBetAmount = historyList
        .map((item) => item.betAmount)
        .reduce((value, element) => value + element);
    return totalBetAmount / historyList.length;
  }

  double _calculateMaxBetAmount(List<HistoryItem> historyList) {
    if (historyList.isEmpty) return 0.0;

    return historyList
        .map((item) => item.betAmount)
        .reduce((a, b) => a > b ? a : b);
  }

  double _calculateMinBetAmount(List<HistoryItem> historyList) {
    if (historyList.isEmpty) return 0.0;

    return historyList
        .map((item) => item.betAmount)
        .reduce((a, b) => a < b ? a : b);
  }

  void _refreshCharts() {
    setState(() {
      fetchHistoryData();
    });
  }

  void showAlertMessage() {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Disclaimer"),
          content: const Text(
              "Gambling can have negative effects on personal finances, leading to squandered savings and income, and taking money away from other economic uses, investment, and charities. Poorer gamblers may take greater risks in the hopes of a big win, reinforcing poverty. Addictive gamblers may resort to criminal activity to get cash. Gambling can also lead to mental and physical health problems, including anxiety, mood swings, atypical behavior, headaches, stomach ulcers, insomnia, muscle pain, and depression. Other common mistakes include the inability to quit after a long string of losses, making high-stakes bets in hopes of high returns, and betting with money that can't be afforded to lose."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Close"),
            ),
          ],
        ),
      );
    });
  }

  void _showBetLimit() {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Enter Bet Limit'),
            content: TextField(
              controller: _betLimitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Bet Limit',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    betlimit = double.tryParse(_betLimitController.text) ?? 0.0;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ).then((value) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SetupPage(
              betlimit: betlimit,
            ),
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(child: const Text("Gambling Controller")),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Bet Limit: ${betlimit.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _showBetLimit,
                child: const Text('Set Bet Limit'),
              ),
              IconButton(
                onPressed: _refreshCharts,
                icon: Icon(Icons.refresh),
              ),
              SizedBox(height: 10.0),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2.0),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const Text(
                      'Total Win and Loss',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: generatebarChart(historyList),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.0),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2.0),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const Text(
                      'Maximum bet to Minimum bet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: generateLineChart(historyList),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.0),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2.0),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const Text(
                      'Win % and Average Bet Amount',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: generateRateChart(historyList),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.0),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2.0),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const Text(
                      'Winning and Losing Streak',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: generateStreakChart(historyList),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => myApp()),
                );
              },
              icon: Icon(Icons.logout),
            ),
            IconButton(
              onPressed: () {
                showAlertMessage();
              },
              icon: const Icon(Icons.info),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryPage(
                      userEmail: FirebaseAuth.instance.currentUser?.email ?? '',
                    ),
                  ),
                );
              },
              icon: Icon(Icons.history),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SetupPage(
                betlimit: betlimit,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _ChartData {
  final String label;
  final double value;

  _ChartData(this.label, this.value);
}
