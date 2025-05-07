import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/reusables.dart';
import '../controllers/database_controller.dart';
import '../widgets/caffeine_base_page.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class HomePage extends StatefulWidget {
  final String uid;
  final PageController pageController;

  const HomePage({required this.uid, required this.pageController, Key? key})
      : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedItem;
  double _selectedItemCaffeine = 0;
  String _selectedItemCategory = 'Coffee';
  int _selectedItemSize = 0;
  final DatabaseController databaseController = DatabaseController();
  String _username = 'Loading...'; // placeholder
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _caffeineController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  List<String> times = [];
  final List<String> items = [
    'Coffee',
    'Tea',
    'Energy Drink',
    'Soda'
  ]; // Placeholder example items

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _generateTimeDropdown();
    _fetchUsername();
    _loadPersonalList();
    _checkRequiredFields();
    _categoryController.text = _selectedItemCategory.toString();
  }

  void _checkRequiredFields() async {
    bool fieldsExist = await databaseController.doAllFieldsExist(widget.uid);
    if (!fieldsExist) {
      showSetRequiredFieldsDialog(
          context, widget.uid, databaseController, cafColorScheme);
    }
  }

  List<Map<String, dynamic>> personalList = [];

  void _showAddNewItemDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController caffeineController = TextEditingController();
    final TextEditingController sizeController = TextEditingController();
    String selectedCategory = 'Coffee';
    bool isSizeFieldEnabled = true;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            color: brown,
            padding: EdgeInsets.all(16.0),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      'Add New Item',
                      style: TextStyle(
                        color: caramel,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Name Input
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter item name',
                        border: OutlineInputBorder(),
                        hintStyle: TextStyle(color: brown),
                      ),
                      style: TextStyle(color: brown),
                    ),
                    SizedBox(height: 10),

                    // Caffeine Input
                    TextField(
                      controller: caffeineController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter caffeine amount in mg',
                        border: OutlineInputBorder(),
                        hintStyle: TextStyle(color: brown),
                      ),
                      style: TextStyle(color: brown),
                    ),
                    SizedBox(height: 10),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      dropdownColor: caramel,
                      items: [
                        'Coffee',
                        'Tea',
                        'Energy Drink',
                        'Other Drink',
                        'Other Food',
                      ].map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            style: TextStyle(color: brown),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                          isSizeFieldEnabled = selectedCategory != 'Other Food';

                          if (!isSizeFieldEnabled) {
                            sizeController.text =
                                '0'; // Set size to 0 if disabled
                          } else {
                            sizeController
                                .clear(); // Clear size field when enabled
                          }
                        });
                      },
                    ),
                    SizedBox(height: 10),

                    TextField(
                      controller: sizeController,
                      keyboardType: TextInputType.number,
                      enabled: isSizeFieldEnabled,
                      decoration: InputDecoration(
                        hintText: isSizeFieldEnabled
                            ? 'Enter size in ml'
                            : 'Size not applicable for food',
                        border: OutlineInputBorder(),
                        hintStyle: TextStyle(color: brown),
                      ),
                      style: TextStyle(color: brown),
                    ),
                    SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pop();
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: caramel),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            String name = nameController.text.trim();
                            String caffeine = caffeineController.text.trim();
                            String size = sizeController.text.trim();

                            if (name.isEmpty ||
                                caffeine.isEmpty ||
                                (isSizeFieldEnabled && size.isEmpty)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Please fill out all fields!')),
                              );
                              return;
                            }

                            try {
                              await databaseController.addItemToPersonalList(
                                uid: widget.uid,
                                name: name,
                                caffeineAmount: int.parse(caffeine),
                                category: selectedCategory,
                                size: isSizeFieldEnabled
                                    ? int.parse(size)
                                    : 0, // Convert size to int or set to 0
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Item added successfully!')),
                              );

                              Navigator.of(context)
                                  .pop();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error adding item: $e')),
                              );
                            }
                          },
                          child: Text('Save'),
                        )
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showEditListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            color: brown,
            padding: EdgeInsets.all(16.0),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: databaseController.getPersonalList(widget.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading list',
                      style: TextStyle(color: caramel),
                    ),
                  );
                }

                List<Map<String, dynamic>> items = snapshot.data ?? [];
                bool isSelecting = false;
                Set<String> selectedItems = {};
                String searchQuery = '';

                Map<String, Map<String, TextEditingController>> controllers =
                    {};
                Map<String, dynamic> editedItems = {};
                Map<String, String> selectedField = {};

                return StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Edit List',
                              style: TextStyle(
                                color: caramel,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                if (isSelecting && selectedItems.isNotEmpty)
                                  TextButton(
                                    onPressed: () async {
                                      for (var name in selectedItems) {
                                        await databaseController
                                            .removeItemFromPersonalList(
                                                uid: widget.uid,
                                                itemName: name);
                                      }
                                      setState(() {
                                        selectedItems.clear();
                                      });
                                    },
                                    child: Text(
                                      'Delete Selected',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      isSelecting = !isSelecting;
                                      selectedItems.clear();
                                    });
                                  },
                                  child: Text(
                                    isSelecting ? 'Cancel' : 'Select',
                                    style: TextStyle(color: caramel),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        // Search Bar
                        TextField(
                          onChanged: (query) {
                            setState(() {
                              searchQuery = query.toLowerCase();
                            });
                          },
                          style: TextStyle(color: brown),
                          decoration: InputDecoration(
                            hintText: 'Search for an item',
                            hintStyle: TextStyle(
                              color: brown,
                              fontWeight: FontWeight.bold,
                            ),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),

                        // List of Items
                        items.isEmpty
                            ? Text(
                                'No items added yet.',
                                style: TextStyle(color: caramel),
                              )
                            : Expanded(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    var item = items[index];
                                    String originalName = item['name'];

                                    controllers.putIfAbsent(
                                      originalName,
                                      () => {
                                        'name': TextEditingController(
                                            text: originalName),
                                        'caffeineAmount': TextEditingController(
                                            text: item['caffeineAmount']
                                                .toString()),
                                        'size': TextEditingController(
                                            text: item['size'].toString()),
                                      },
                                    );

                                    var nameController =
                                        controllers[originalName]!['name']!;
                                    var caffeineController = controllers[
                                        originalName]!['caffeineAmount']!;
                                    var sizeController =
                                        controllers[originalName]!['size']!;

                                    String editedName =
                                        editedItems[originalName]?['name'] ??
                                            originalName;
                                    String editedCaffeine =
                                        editedItems[originalName]
                                                ?['caffeineAmount'] ??
                                            item['caffeineAmount'].toString();
                                    String editedSize =
                                        editedItems[originalName]?['size'] ??
                                            item['size'].toString();

                                    String field =
                                        selectedField[originalName] ?? 'name';
                                    bool isSelected =
                                        selectedItems.contains(originalName);
                                    bool hasChanges =
                                        editedItems.containsKey(originalName);

                                    // Filter the items based on search query and related terms
                                    bool matchesItem(
                                        String item,
                                        List<String> searchWords,
                                        List<String> relatedTerms) {
                                      String lowerCaseItem = item.toLowerCase();
                                      for (var word in searchWords) {
                                        if (!lowerCaseItem.contains(word) &&
                                            !relatedTerms.any((term) => term
                                                .toLowerCase()
                                                .contains(word))) {
                                          return false;
                                        }
                                      }
                                      return true;
                                    }

                                    // Filter items based on search query
                                    List<String> searchWords = searchQuery
                                        .split(' ')
                                        .map(
                                            (word) => word.trim().toLowerCase())
                                        .where((word) => word.isNotEmpty)
                                        .toList();
                                    List<String> relatedTerms =
                                        List<String>.from(
                                            item['relatedTerms'] ?? []);

                                    if (!matchesItem(originalName, searchWords,
                                        relatedTerms)) {
                                      return Container();
                                    }

                                    return Container(
                                      margin:
                                          EdgeInsets.symmetric(vertical: 8.0),
                                      decoration: BoxDecoration(
                                        color: caramel,
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 5.0,
                                            spreadRadius: 1.0,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          ListTile(
                                            contentPadding:
                                                EdgeInsets.all(16.0),
                                            leading: isSelecting
                                                ? Checkbox(
                                                    value: isSelected,
                                                    onChanged: (bool? value) {
                                                      setState(() {
                                                        if (value == true) {
                                                          selectedItems.add(
                                                              originalName);
                                                        } else {
                                                          selectedItems.remove(
                                                              originalName);
                                                        }
                                                      });
                                                    },
                                                  )
                                                : null,
                                            title: field == 'name'
                                                ? TextField(
                                                    controller: nameController,
                                                    onChanged: (newValue) {
                                                      setState(() {
                                                        editedItems[
                                                            originalName] = {
                                                          ...editedItems[
                                                                  originalName] ??
                                                              {},
                                                          'name': newValue,
                                                        };
                                                      });
                                                    },
                                                    decoration: InputDecoration(
                                                      border:
                                                          OutlineInputBorder(),
                                                      filled: true,
                                                      fillColor: Colors.white
                                                    ),
                                                  )
                                                : GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        selectedField[
                                                                originalName] =
                                                            'name';
                                                      });
                                                    },
                                                    child: Text(
                                                      editedName,
                                                      style: TextStyle(
                                                          color: brown,
                                                          fontSize: 18),
                                                    ),
                                                  ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                field == 'caffeineAmount'
                                                    ? TextField(
                                                        controller:
                                                            caffeineController,
                                                        onChanged: (newValue) {
                                                          setState(() {
                                                            editedItems[
                                                                originalName] = {
                                                              ...editedItems[
                                                                      originalName] ??
                                                                  {},
                                                              'caffeineAmount':
                                                                  newValue,
                                                            };
                                                          });
                                                        },
                                                        decoration:
                                                            InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          filled: true,
                                                          fillColor: Colors
                                                              .white
                                                        ),
                                                      )
                                                    : GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            selectedField[
                                                                    originalName] =
                                                                'caffeineAmount';
                                                          });
                                                        },
                                                        child: Text(
                                                          '$editedCaffeine mg',
                                                          style: TextStyle(
                                                              color: brown),
                                                        ),
                                                      ),
                                                field == 'size'
                                                    ? TextField(
                                                        controller:
                                                            sizeController,
                                                        onChanged: (newValue) {
                                                          setState(() {
                                                            editedItems[
                                                                originalName] = {
                                                              ...editedItems[
                                                                      originalName] ??
                                                                  {},
                                                              'size': newValue,
                                                            };
                                                          });
                                                        },
                                                        decoration:
                                                            InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          filled: true,
                                                          fillColor: Colors
                                                              .white
                                                        ),
                                                      )
                                                    : GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            selectedField[
                                                                    originalName] =
                                                                'size';
                                                          });
                                                        },
                                                        child: Text(
                                                          '$editedSize ml',
                                                          style: TextStyle(
                                                              color: brown),
                                                        ),
                                                      ),
                                              ],
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (!isSelecting)
                                                  IconButton(
                                                    icon: Icon(Icons.delete,
                                                        color: Colors.red),
                                                    onPressed: () async {
                                                      await databaseController
                                                          .removeItemFromPersonalList(
                                                              uid: widget.uid,
                                                              itemName:
                                                                  originalName);
                                                      setState(() {});
                                                    },
                                                  ),
                                                if (hasChanges)
                                                  TextButton(
                                                    onPressed: () async {
                                                      await databaseController
                                                          .updateItemInPersonalList(
                                                        uid: widget.uid,
                                                        oldName: originalName,
                                                        updatedItem: {
                                                          'name': editedName,
                                                          'caffeineAmount':
                                                              editedCaffeine,
                                                          'size': editedSize,
                                                        },
                                                      );
                                                      setState(() {
                                                        editedItems.remove(
                                                            originalName);
                                                      });
                                                    },
                                                    child: Text('Save',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.green)),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                        SizedBox(height: 10),

                        Align(
                          alignment: Alignment.bottomRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child:
                                Text('Close', style: TextStyle(color: caramel)),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadPersonalList() async {
    try {
      personalList = await databaseController.getPersonalList(widget.uid);
      if (mounted) {
        setState(() {
          items.clear();
          items.addAll(personalList.map((item) => item['name'].toString()));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading personal list: $e')));
      }
    }
  }

  Future<void> _fetchUsername() async {
    String username = await databaseController.getUsername(widget.uid);
    if (mounted) {
      setState(() {
        _username = username;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      final now = DateTime.now();
      final pickedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );

      if (pickedDateTime.isAfter(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You can't select a future time.")),
        );
      } else {
        setState(() {
          _selectedTime = picked;
        });
      }
    }
  }


  void _generateTimeDropdown() {
    for (int hour = 0; hour < 24; hour++) {
      for (int min = 0; min < 60; min += 30) {
        times.add(
            '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CaffeinePage(
      title: 'Home',
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: brown,
            ),
            width: double.infinity,
            height: double.infinity,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome Back $_username!',
                      style: TextStyle(
                        color: caramel,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Lottie.asset(
                      'assets/coffeecup.json',
                      width: 100,
                      height: 100,
                      fit: BoxFit.fill,
                    ),
                    Text(
                      'Select item to be consumed:',
                      style: TextStyle(
                          color: caramel,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),

                    TypeAheadField<String>(
                      builder: (context, controller, focusNode) {
                        return TextField(
                          controller: controller,
                          onTap: controller.clear,
                          focusNode: focusNode,
                          style: TextStyle(
                            color: brown,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Select or type an item',
                            hintStyle: TextStyle(
                              color: brown,
                              fontWeight: FontWeight.bold,
                            ),
                            border: OutlineInputBorder(),
                          ),
                        );
                      },
                      suggestionsCallback: (pattern) async {
                        if (personalList.isEmpty) {
                          await _loadPersonalList();
                        }

                        List<String> searchWords = pattern
                            .split(' ')
                            .map((word) => word.trim().toLowerCase())
                            .where((word) => word.isNotEmpty)
                            .toList();

                        DateTime now = DateTime.now();
                        DateTime startDate = now.subtract(Duration(days: 100));
                        List<Map<String, dynamic>> cafHistory =
                        await databaseController.getCaffeineHistoryForPeriod(widget.uid, startDate, now);
                        Map<String, int> _itemTypeCounts = databaseController.calculateItemTypeCounts(cafHistory);

                        bool matchesItem(String item, List<String> searchWords,
                            List<String> relatedTerms) {
                          String lowerCaseItem = item.toLowerCase();
                          for (var word in searchWords) {
                            if (!lowerCaseItem.contains(word) &&
                                !relatedTerms.any((term) => term.toLowerCase().contains(word))) {
                              return false;
                            }
                          }
                          return true;
                        }

                        // Get all matching items
                        List<String> matchedItems = items.where((item) {
                          Map<String, dynamic>? selectedItem = personalList.firstWhere(
                                (itemMap) => itemMap['name'] == item,
                            orElse: () => {},
                          );

                          if (selectedItem.isNotEmpty) {
                            List<String> relatedTerms = List<String>.from(selectedItem['relatedTerms']);
                            return matchesItem(item, searchWords, relatedTerms);
                          }
                          return false;
                        }).toList();

                        // Sort items by frequency first, then alphabetically
                        matchedItems.sort((a, b) {
                          int countA = _itemTypeCounts[a] ?? 0;
                          int countB = _itemTypeCounts[b] ?? 0;

                          if (countA != countB) {
                            return countB.compareTo(countA); // Sort by count (descending)
                          }
                          return a.compareTo(b); // Sort alphabetically if count is the same
                        });

                        // Order top 5 most frequently used items
                        List<String> topItems = matchedItems.take(5).toList();
                        List<String> remainingItems = matchedItems.skip(5).toList();
                        remainingItems.sort(); // Remaining items are sorted alphabetically

                        return topItems + remainingItems;
                      },

                      itemBuilder: (context, String suggestion) {
                        return ListTile(
                          tileColor: caramel,
                          title: Text(
                            suggestion,
                            style: TextStyle(
                              color: brown,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                      onSelected: (String suggestion) async {
                        setState(() {
                          _selectedItem = suggestion;
                          _itemController.text = suggestion;
                        });

                        if (suggestion == "Other") {
                          setState(() {
                            _selectedItemCaffeine = 0;
                            _selectedItemCategory = "Coffee";
                            _selectedItemSize = 0;
                          });
                        } else {
                          Map<String, dynamic>? selectedItem =
                              personalList.firstWhere(
                            (item) => item['name'] == suggestion,
                            orElse: () => {},
                          );

                          if (selectedItem.isNotEmpty) {
                            setState(() {
                              _selectedItemCaffeine = (selectedItem['caffeineAmount'] as num).toDouble();
                              _selectedItemCategory = selectedItem['category'];
                              _selectedItemSize = selectedItem['size'];
                            });
                          }
                        }
                        _caffeineController.text = _selectedItemCaffeine.toString();
                        _categoryController.text = _selectedItemCategory.toString();
                        _sizeController.text = _selectedItemSize.toString();
                      },
                    ),

                    SizedBox(height: 10),

                    TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Item Name',
                          border: OutlineInputBorder(),
                        ),
                        style: TextStyle(
                            color: brown, fontWeight: FontWeight.bold),
                        controller: _itemController),

                    SizedBox(height: 10),
                    TextField(
                      readOnly:
                          _selectedItem != "Other" && _selectedItem != null,
                      decoration: InputDecoration(
                        hintText: 'Caffeine Content (mg)',
                        border: OutlineInputBorder(),
                      ),
                      style:
                          TextStyle(color: brown, fontWeight: FontWeight.bold),
                        controller: _caffeineController,
                    ),
                    SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: _categoryController.text,
                      decoration: InputDecoration(
                        hintText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      dropdownColor: caramel,
                      items: [
                        'Coffee',
                        'Tea',
                        'Energy Drink',
                        'Other Drink',
                        'Other Food',
                      ].map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            style: TextStyle(
                                color: brown, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      onChanged:
                          (_selectedItem == "Other" || _selectedItem == null)
                              ? (value) {
                                  setState(() {
                                    _selectedItemCategory = value!;
                                    if (_selectedItemCategory == 'Other Food') {
                                      _selectedItemSize = 0;
                                    }
                                  });
                                }
                              : null,
                    ),
                    SizedBox(height: 10),

                    TextField(
                      readOnly: _selectedItemCategory == "Other Food" ||
                          (_selectedItem != "Other" && _selectedItem != null),
                      decoration: InputDecoration(
                        hintText: 'Size (ml)',
                        border: OutlineInputBorder(),
                      ),
                      style:
                          TextStyle(color: brown, fontWeight: FontWeight.bold),
                      controller: _sizeController,
                    ),
                    SizedBox(height: 5),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Time of consumption:',
                              style: TextStyle(
                                color: caramel,
                                fontWeight: FontWeight.bold,
                                fontSize: 20
                              ),
                            ),
                            TextButton(
                              onPressed: () => _pickTime(context),
                              child: Text(
                                _selectedTime.format(context),
                                style: TextStyle(
                                  color: caramel,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                      ],
                    ),

                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          _showAddNewItemDialog(context);
                        },
                        child: Text(
                          'Add New Item',
                          style: TextStyle(
                              color: brown, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),

                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          _showEditListDialog(context);
                        },
                        child: Text(
                          'Edit Items List',
                          style: TextStyle(
                              color: brown, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),

                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          bool? confirmed =
                              await databaseController.calculateCaffeine(
                                  context: context,
                                  uid: widget.uid,
                                  itemName: _selectedItem.toString(),
                                  caffeineContent: _selectedItemCaffeine,
                                  category: _selectedItemCategory,
                                  size: _selectedItemSize,
                                  consumptionTime : _selectedTime
                              );
                          if (confirmed!) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content:
                                    Text('Caffeine Calculation Successful.')));

                            widget.pageController.animateToPage(1,
                                duration: Duration(milliseconds: 200),
                                curve: Curves.easeInOut);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Caffeine Calculation Failed.')));
                          }
                        },
                        child: Text(
                          'Calculate',
                          style: TextStyle(
                              color: brown, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                _showFeedbackDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: caramel,
                shape: CircleBorder(),
                padding: EdgeInsets.all(20),
              ),
              child: Icon(Icons.feedback, color: brown),
            ),
          ),
        ],
      ),
    );
  }
  void _showFeedbackDialog(BuildContext context) async {
    final int? caffeineDuration = await _fetchCaffeineDuration();
    final DateTime? crashTime = await _fetchExpectedCrashTime();
    final DateTime? consumedTime = await _fetchConsumedTime();

    if (caffeineDuration == null || crashTime == null || consumedTime == null) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: brown,
            title: Text(
              "No Data Available",
              style: TextStyle(color: caramel),
            ),
            content: Text(
              "Use the app to track caffeine consumption before providing feedback.",
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK", style: TextStyle(color: caramel)),
              ),
            ],
          );
        },
      );
      return;
    }

    List<double> multipliers = [0.7, 0.8, 0.9, 1, 1.1, 1.2, 1.3];
    List<String> labels = [
      "Even earlier",
      "20% less time",
      "10% less time",
      "Expected time",
      "10% more time",
      "20% more time",
      "Even later"
    ];

    List<Map<String, dynamic>> options = multipliers.map((multiplier) {
      int adjustedDuration = (caffeineDuration * multiplier).round();
      DateTime adjustedCrashTime = crashTime.add(Duration(minutes: (adjustedDuration - caffeineDuration)));

      return {
        "label": labels[multipliers.indexOf(multiplier)],
        "duration": adjustedDuration,
        "time": adjustedCrashTime,
        "multiplier": multiplier
      };
    }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: brown,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "You last consumed caffeine at ${DateFormat('hh:mm a').format(consumedTime)}",
                style: TextStyle(color: caramel, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                "When did you feel the caffeine crash?",
                style: TextStyle(color: caramel, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              String formattedTime = DateFormat('hh:mm a').format(option["time"]);
              String buttonText = option["label"];

              if (buttonText != "Even earlier" && buttonText != "Even later") {
                buttonText += " ($formattedTime)";
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: caramel,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      _saveMultiplier(option["multiplier"]);
                      Navigator.pop(context);

                      String message;
                      if (option["label"] == "Expected time") {
                        message = "Thank you for your feedback!";
                      } else {
                        message = "Thank you for your feedback! Your data has been adjusted.";
                      }

                      _showThankYouDialog(context, message);
                    },
                    child: Text(
                      buttonText,
                      style: TextStyle(color: brown),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showThankYouDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: brown,
          title: Text(
            "Feedback Received",
            style: TextStyle(color: caramel),
          ),
          content: Text(
            message,
            style: TextStyle(color: caramel),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK", style: TextStyle(color: caramel)),
            ),
          ],
        );
      },
    );
  }

  Future<int?> _fetchCaffeineDuration() async {
    return await databaseController.getTotalMinutes(widget.uid);
  }

  Future<DateTime?> _fetchExpectedCrashTime() async {
    return await databaseController.getCaffeineEndTime(widget.uid);
  }

  Future<DateTime?> _fetchConsumedTime() async {
    Map<String, dynamic>? lastItem = await databaseController.getLastItem(widget.uid);

    if (lastItem == null || !lastItem.containsKey('timeConsumed') || lastItem['timeConsumed'] == null) {
      return null;
    }

    try {
      return (lastItem['timeConsumed'] as Timestamp).toDate();
    } catch (e) {
      print("Error converting timeConsumed to DateTime: $e");
      return null;
    }
  }

  void _saveMultiplier(double multiplier) {
    databaseController.updateMultiplier(uid: widget.uid, newMultiplier: multiplier);
  }

}
