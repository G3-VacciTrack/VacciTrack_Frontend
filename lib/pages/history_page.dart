import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

import '../models/history_record.dart';
import '../components/custom_vaccine_history_card.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static final String baseUrl =
      dotenv.env['API_URL'] ?? 'http://localhost:3001/api';

  String errorMessage = '';
  late Future<List<HistoryRecord>> futureHistory;
  List<HistoryRecord> history = [];
  String? selectedYear;

  @override
  void initState() {
    super.initState();
    futureHistory = fetchHistory();
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<List<HistoryRecord>> fetchHistory() async {
    final uid = await getUserId();
    if (uid == null) {
      setState(() {
        errorMessage = 'User not logged in.';
      });
      return [];
    }

    final url = Uri.parse('$baseUrl/history/all?uid=$uid');
    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['history'] != null &&
            jsonResponse['history'] is List) {
          return (jsonResponse['history'] as List)
              .map((item) => HistoryRecord.fromJson(item))
              .toList();
        } else {
          setState(() {
            errorMessage = 'No history data found.';
          });
          return [];
        }
      } else {
        throw Exception('Failed to load history: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'No History Found.';
      });
      return [];
    }
  }

  String formatDate(String dateTimeString) {
    try {
      final dt = DateTime.parse(dateTimeString);
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return dateTimeString;
    }
  }

  Map<String, List<HistoryRecord>> groupByDate(List<HistoryRecord> history) {
    final Map<String, List<HistoryRecord>> grouped = {};
    for (var record in history) {
      String isoDate;
      try {
        final dt = DateTime.parse(record.date);
        isoDate =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {
        isoDate = record.date;
      }

      grouped.putIfAbsent(isoDate, () => []).add(record);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (var k in sortedKeys) k: grouped[k]!};
  }

  List<String> extractAvailableYears(List<HistoryRecord> history) {
    final years = <String>{};
    for (var item in history) {
      try {
        final dt = DateTime.parse(item.date);
        years.add(dt.year.toString());
      } catch (_) {}
    }
    final sorted = years.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<HistoryRecord>>(
        future: futureHistory,
        builder: (context, snapshot) {
          List<Widget> sliverList = [
            SliverAppBar(
              title: const Text(
                'History',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0.0,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              floating: false,
            ),
          ];

          if (snapshot.connectionState == ConnectionState.waiting) {
            sliverList.add(
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          } else if (snapshot.hasError || errorMessage.isNotEmpty) {
            sliverList.add(
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    errorMessage.isNotEmpty
                        ? errorMessage
                        : 'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            sliverList.add(
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No vaccination history found.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            );
          } else {
            history = snapshot.data!;
            final years = extractAvailableYears(history);
            final filteredHistory = selectedYear == null
                ? history
                : history.where((h) {
                    final date = DateTime.tryParse(h.date);
                    return date?.year.toString() == selectedYear;
                  }).toList();
            final groupedHistory = groupByDate(filteredHistory);

            sliverList.add(
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          PopupMenuButton<String>(
                            color: Colors.white,
                            onSelected: (String year) {
                              setState(() {
                                selectedYear = year == 'All' ? null : year;
                              });
                            },
                            itemBuilder: (BuildContext context) {
                              final items = ['All', ...years];
                              return items.map((year) {
                                return PopupMenuItem<String>(
                                  value: year,
                                  child: Text(
                                    year,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                );
                              }).toList();
                            },
                            offset: const Offset(0, 36),
                            child: Container(
                              alignment: Alignment.center,
                              width: 130,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6CC2A8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.15),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    selectedYear ?? 'Select Year',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '*Display only years with data',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );

            groupedHistory.forEach((isoDate, records) {
              final displayDate = formatDate(isoDate);
              sliverList.addAll([
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                    ),
                    child: Text(
                      displayDate,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    records
                        .map((record) => VaccineHistoryCard(
                              historyId: record.id,
                              vaccineName: record.vaccineName,
                              hospital: record.location,
                              dose: int.tryParse(record.dose) ?? 1,
                              totalDose:
                                  int.tryParse(record.totalDose ?? '') ?? 1,
                              description: record.description ?? '',
                            ))
                        .toList(),
                  ),
                ),
              ]);
            });

            sliverList.add(const SliverToBoxAdapter(child: SizedBox(height: 100)));
          }

          return SafeArea(
            top: false,
            child: CustomScrollView(slivers: sliverList),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          print("Add Vaccine tapped");
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Vaccine",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFF6CC2A8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
