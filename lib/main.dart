import 'dart:async';
import 'package:flutter/material.dart';
import 'api/api_service.dart';
import 'api/loading_screen.dart';

void main() {
  runApp(MyApp());
}

class Transaction {
  final String type; // Buy or Sell
  final int quantity;
  final double amount;
  final DateTime dateTime; // Date and time of the transaction

  Transaction(this.type, this.quantity, this.amount, this.dateTime);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Broker System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          color: Colors.grey[900],
          elevation: 0,
        ),
      ),
      home: BrokerPage(),
    );
  }
}

class BrokerPage extends StatefulWidget {
  @override
  _BrokerPageState createState() => _BrokerPageState();
}

class _BrokerPageState extends State<BrokerPage> {
  double usdValue = 0.000; // USD value
  double previousUSDValue = 0.000; //  previous USD value
  double pesoBalance = 1000000; // Initial balance in pesos
  int usdBought = 0; // Counter for USD bought
  bool isLoading = true;

  // Constants for transaction fees
  static const double buyTransactionFeePercentage = 0.005;
  static const double sellTransactionFeePercentage = 0.002;

  // Variables to store buy and sell quantities
  int buyQuantity = 1;
  int sellQuantity = 1;

  // Variables to store total amounts and transaction fees
  double buyTotal = 0.0;
  double sellTotal = 0.0;
  double buyTransactionFee = 0.0;
  double sellTransactionFee = 0.0;

  // Variables to store grand total per transaction
  double buyGrandTotal = 0.0;
  double sellGrandTotal = 0.0;

  // TextEditingController for handling input in the modal
  TextEditingController _quantityController = TextEditingController();

  List<Transaction> transactionHistory = [];

  @override
  void initState() {
    super.initState();
    fetchUSDValue();
    startTimer();
  }

  void startTimer() {
    Timer.periodic(Duration(seconds: 60), (timer) {
      fetchUSDValue(); // Fetch new USD value every 60 seconds
    });
  }

  void fetchUSDValue() async {
    setState(() {
      isLoading = true; // Set loading state
    });
    try {
      double value = await ApiService.fetchUSDValue();
      setState(() {
        previousUSDValue = usdValue; // Update previous USD value
        usdValue = value;
        isLoading = false; // Mark loading as complete
      });
    } catch (e) {
      print('Error: $e');

      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to get arrow icon based on USD value comparison
  IconData getArrowIcon(double currentValue, double previousValue) {
    if (currentValue > previousValue) {
      return Icons
          .arrow_upward; // Return upward arrow icon if value has increased
    } else if (currentValue < previousValue) {
      return Icons
          .arrow_downward; // Return downward arrow icon if value has decreased
    } else {
      return Icons
          .horizontal_rule; // Return horizontal rule icon if value remains the same
    }
  }

  Color getArrowColor(double currentValue, double previousValue) {
    if (currentValue > previousValue) {
      return Colors.green; // Return green color if value has increased
    } else if (currentValue < previousValue) {
      return Colors.red; // Return red color if value has decreased
    } else {
      return Colors.grey; // Return grey color if value remains the same
    }
  }

  // Function to buy USD
  void buyUSD() {
    // Show modal dialog for adding quantity
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Buy USD", style: TextStyle(color: Colors.white)),
          backgroundColor: Color.fromARGB(255, 85, 155, 10),
          content: TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Quantity",
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Confirm", style: TextStyle(color: Colors.white)),
              onPressed: () {
                // Parse input quantity and calculate total and transaction fee
                int quantity = int.tryParse(_quantityController.text) ?? 0;
                setState(() {
                  buyQuantity = quantity;
                  buyTransactionFee =
                      (usdValue * buyTransactionFeePercentage) * quantity;
                  buyTotal = (usdValue * buyQuantity);
                  buyGrandTotal = buyTotal + buyTransactionFee;
                });
                Navigator.of(context).pop();
                showBuyConfirmation(); // Show confirmation dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Function to show buy confirmation dialog
  void showBuyConfirmation() {
    // Calculate the total cost including transaction fee
    double totalCost = buyGrandTotal;

    // Check if the balance is sufficient
    if (pesoBalance >= totalCost) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.yellow),
                SizedBox(width: 8),
                Text("Confirm Buy", style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: Color.fromARGB(255, 85, 155, 10),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("You are about to buy $buyQuantity USD.",
                    style: TextStyle(color: Colors.white)),
                SizedBox(height: 10),
                Text("Total Amount: ₱${buyTotal.toStringAsFixed(2)}",
                    style: TextStyle(color: Colors.white)),
                Text(
                    "Transaction Fee: ₱${buyTransactionFee.toStringAsFixed(2)}",
                    style: TextStyle(color: Colors.white)),
                Text("Grand Total: ₱${buyGrandTotal.toStringAsFixed(2)}",
                    style: TextStyle(color: Colors.white)),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text("Cancel", style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text("Confirm", style: TextStyle(color: Colors.white)),
                onPressed: () {
                  buyConfirmed();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      // Show insufficient balance dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text("Insufficient Balance",
                    style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: Color.fromARGB(255, 85, 155, 10),
            content: Text("You don't have enough balance to buy USD.",
                style: TextStyle(color: Colors.white)),
            actions: <Widget>[
              TextButton(
                child: Text("OK", style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  // Function to buy USD after confirmation
  void buyConfirmed() {
    setState(() {
      // Deduct the total amount including transaction fee from the balance
      if (pesoBalance >= buyGrandTotal) {
        pesoBalance -= buyGrandTotal;
        usdBought += buyQuantity; // Increment USD bought by the quantity
        // Add transaction to history
        transactionHistory.add(Transaction(
          'Buy',
          buyQuantity,
          buyGrandTotal,
          DateTime.now(),
        ));
      } else {}
    });
  }

  // Function to sell USD
  void sellUSD() {
    // Show modal dialog for adding quantity
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Sell USD", style: TextStyle(color: Colors.white)),
          backgroundColor: Color.fromARGB(255, 214, 27, 27),
          content: TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Quantity",
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Confirm", style: TextStyle(color: Colors.white)),
              onPressed: () {
                // Parse input quantity and calculate total and transaction fee
                int quantity = int.tryParse(_quantityController.text) ?? 0;
                setState(() {
                  sellQuantity = quantity;
                  sellTransactionFee =
                      (usdValue * sellTransactionFeePercentage) * quantity;
                  sellTotal = usdValue * sellQuantity;
                  sellGrandTotal = sellTotal - sellTransactionFee;
                });
                Navigator.of(context).pop();
                sellConfirmation(); // Show confirmation dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Function to show sell confirmation dialog
  void sellConfirmation() {
    // Calculate the total cost including transaction fee

    // Check if there is enough USD to sell
    if (usdBought >= sellQuantity) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Confirm Sell", style: TextStyle(color: Colors.white)),
            backgroundColor: Color.fromARGB(255, 214, 27, 27),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("You are about to sell $sellQuantity USD.",
                    style: TextStyle(color: Colors.white)),
                SizedBox(height: 10),
                Text("Total Amount: ₱${sellTotal.toStringAsFixed(2)}",
                    style: TextStyle(color: Colors.white)),
                Text(
                    "Transaction Fee: ₱${sellTransactionFee.toStringAsFixed(2)}",
                    style: TextStyle(color: Colors.white)),
                Text("Grand Total: ₱${sellGrandTotal.toStringAsFixed(2)}",
                    style: TextStyle(color: Colors.white)),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text("Cancel", style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text("Confirm", style: TextStyle(color: Colors.white)),
                onPressed: () {
                  sellConfirmed();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      // Show insufficient USD dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline,
                    color: const Color.fromARGB(255, 255, 255, 255)),
                SizedBox(width: 8),
                Text("Insufficient Balance",
                    style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: Color.fromARGB(255, 214, 27, 27),
            content: Text("You don't have enough USD to sell.",
                style: TextStyle(color: Colors.white)),
            actions: <Widget>[
              TextButton(
                child: Text("OK", style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  // Function to sell USD after confirmation
  void sellConfirmed() {
    setState(() {
      // Check if there is enough USD to sell
      if (usdBought >= sellQuantity) {
        // Calculate the total amount after deducting the transaction fee
        double totalAmount = sellGrandTotal;
        // Add the total gain to the balance after deducting the transaction fee
        pesoBalance += totalAmount;
        usdBought -= sellQuantity; // Decrease USD count by the quantity
        // Add transaction to history
        transactionHistory.add(Transaction(
          'Sell',
          sellQuantity,
          totalAmount,
          DateTime.now(),
        ));
      } else {
        // Not enough USD to sell
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Insufficient USD",
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.grey[800],
              content: Text("You don't have enough USD to sell.",
                  style: TextStyle(color: Colors.white)),
              actions: <Widget>[
                TextButton(
                  child: Text("OK", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'IMBroke®',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: isLoading
          ? LoadingScreen()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: CustomScrollView(
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(height: 20),
                          // Displaying Peso Balance and USD Bought on the same line
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 45, 53, 60),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'PHP: ₱${pesoBalance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 45, 53, 60),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'USD: \$$usdBought',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 40),

                          Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'H.C.C. Dollar',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 10),
                                Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Image.network(
                                    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExeW1yMjNhbnJvOHg2ZWs4YnhhYWRiaXhmYTh6bGk4NjQ2azJ3ejU0MCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/OccMlQrNO0YU4zFchY/giphy.gif', // Replace with your image URL
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                      Icons.error,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '₱${usdValue.toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              // Display arrow icon based on USD value comparison
                              Icon(
                                getArrowIcon(usdValue, previousUSDValue),
                                color:
                                    getArrowColor(usdValue, previousUSDValue),
                                size: 24,
                              ),
                            ],
                          ),
                          SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: buyUSD,
                                icon: Icon(Icons.attach_money),
                                label: Text('Buy USD'),
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Color.fromARGB(255, 85, 155, 10)),
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.white),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: sellUSD,
                                icon: Icon(Icons.money_off),
                                label: Text('Sell USD'),
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Color.fromARGB(255, 214, 27, 27)),
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.white),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Transaction History',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          final transaction = transactionHistory[index];
                          // Define the icon and outline color based on transaction type
                          IconData icon;
                          Color outlineColor;
                          if (transaction.type == 'Buy') {
                            icon = Icons.attach_money;
                            outlineColor = Color.fromARGB(255, 85, 155, 10);
                          } else {
                            icon = Icons.money_off;
                            outlineColor = Color.fromARGB(255, 214, 27, 27);
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              leading: Icon(
                                icon,
                                color: outlineColor,
                              ),
                              title: Text(
                                '${transaction.type} - ${transaction.quantity} USD',
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'Amount: ₱${transaction.amount.toStringAsFixed(2)} | Date: ${transaction.dateTime}',
                                style: TextStyle(color: Colors.white),
                              ),
                              // Apply outline border based on transaction type
                              tileColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: outlineColor, width: 1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        },
                        childCount: transactionHistory.length,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
