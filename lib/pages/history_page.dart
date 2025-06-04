import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

import '../models/history_record.dart';
import '../components/custom_create_history_dialog.dart' as create_dialog;
import '../components/custom_vaccine_history_card.dart';
import '../components/custom_history_detail_dialog.dart' as detail_dialog;

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
  List<HistoryRecord> allHistory = [];
  String? selectedYear;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  Future<void> _fetchHistory() async {
    setState(() {
      futureHistory = fetchHistory();
    });
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
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['history'] != null &&
            jsonResponse['history'] is List) {
          final fetchedHistory =
              (jsonResponse['history'] as List)
                  .map((item) => HistoryRecord.fromJson(item))
                  .toList();
          setState(() {
            allHistory = fetchedHistory;
            errorMessage = '';
          });
          return fetchedHistory;
        } else {
          setState(() {
            errorMessage = 'No history data found.';
            allHistory = [];
          });
          return [];
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load history: ${response.statusCode}';
          allHistory = [];
        });
        return [];
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to connect to server or no history found.';
        allHistory = [];
      });
      return [];
    }
  }

  String formatDate(String dateTimeString) {
    try {
      final dt = DateTime.parse(dateTimeString);
      return DateFormat('d MMM y').format(dt);
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
    final availableYears = extractAvailableYears(allHistory);
    final bool canPop = Navigator.of(context).canPop();
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                leading:
                    canPop
                        ? IconButton(
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: Color(0xFF33354C),
                            size: 35,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        )
                        : null,
                title: const Text(
                  'History',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
                ),
                backgroundColor: Colors.white,
                elevation: 0,
                pinned: true,
                titleSpacing: canPop ? 0.0 : null,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF33354C,
                                  ).withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search vaccine',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF6F6F6F),
                                  fontSize: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Color(0xFF6CC2A8),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                              final items = ['All', ...availableYears];
                              return items.map((year) {
                                return PopupMenuItem<String>(
                                  value: year,
                                  child: Text(
                                    year,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF33354C),
                                    ),
                                  ),
                                );
                              }).toList();
                            },
                            offset: const Offset(0, 36),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6CC2A8),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF33354C,
                                    ).withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    selectedYear ?? 'All',
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
                          
                          
                          
                          
                          
                          
                          
                          
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              FutureBuilder<List<HistoryRecord>>(
                future: futureHistory,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text('Error: ${snapshot.error}\n$errorMessage'),
                      ),
                    );
                  } else if (snapshot.hasData) {
                    List<HistoryRecord> displayedHistory = snapshot.data!;
                    if (selectedYear != null) {
                      displayedHistory =
                          displayedHistory.where((record) {
                            try {
                              return DateTime.parse(
                                    record.date,
                                  ).year.toString() ==
                                  selectedYear;
                            } catch (_) {
                              return false;
                            }
                          }).toList();
                    }
                    final searchQuery = _searchController.text.toLowerCase();
                    if (searchQuery.isNotEmpty) {
                      displayedHistory =
                          displayedHistory.where((record) {
                            return record.vaccineName.toLowerCase().contains(
                              searchQuery,
                            );
                          }).toList();
                    }

                    if (displayedHistory.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sentiment_dissatisfied,
                                size: 80,
                                color: Color.fromARGB(255, 186, 235, 221),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No vaccinate history found.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final groupedHistory = groupByDate(
                      displayedHistory,
                    );
                    final List<Widget> groupedWidgets = [];

                    groupedHistory.forEach((isoDate, records) {
                      final displayDate = formatDate(isoDate);
                      groupedWidgets.add(
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              displayDate,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      );

                      groupedWidgets.addAll(
                        records.map(
                          (record) => GestureDetector(
                            onTap: () {
                              detail_dialog.showHistoryDetailsDialog(
                                context,
                                history: record,
                                onHistoryUpdated: () {
                                  _fetchHistory();
                                },
                              );
                            },
                            child: VaccineHistoryCard(
                              memberName: record.memberName,
                              diseaseName: record.diseaseName,
                              historyId: record.id,
                              vaccineName: record.vaccineName,
                              hospital: record.location,
                              dose: record.dose,
                              totalDose: record.totalDose,
                              description: record.description,
                            ),
                          ),
                        ),
                      );
                    });

                    return SliverToBoxAdapter(
                      child: Column(children: groupedWidgets),
                    );
                  } else {
                    return const SliverFillRemaining(
                      child: Center(child: Text('No data available.')),
                    );
                  }
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          create_dialog.showHistoryDetailsDialog(
            context,
            onHistoryAdded: () {
              _fetchHistory();
            },
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Vaccine",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFF6CC2A8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
    );
  }
}
