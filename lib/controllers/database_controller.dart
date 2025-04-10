import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/reusables.dart';
import 'package:intl/intl.dart';

class DatabaseController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getUsername(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        String username = userDoc['username'];
        return username;
      } else {
        return 'User not found';
      }
    } catch (e) {
      print("Error getting username: $e");
      return 'Error retrieving username';
    }
  }

  Future<String> getWeight(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        var weight = userDoc['weight'];
        return weight.toString();
      } else {
        return 'Weight not found';
      }
    } catch (e) {
      print("Error getting weight: $e");
      return 'Error retrieving weight';
    }
  }

  Future<String> getHeight(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        var height = userDoc['height'];
        return height.toString();
      } else {
        return 'Height not found';
      }
    } catch (e) {
      print("Error getting height: $e");
      return 'Error retrieving height';
    }
  }

  Future<void> updateUserDetails({
    required String uid,
    required String username,
    required double height,
    required int weight,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'username': username,
        'height': height,
        'weight': weight,
      });
      print("User details updated successfully");
    } catch (e) {
      print("Error updating user details: $e");
      throw e;
    }
  }

  Future<String> getBedtime(String uid) async {
    try {
      DocumentSnapshot caffeineDoc = await _firestore.collection('caffeine')
          .doc(uid)
          .get();

      if (caffeineDoc.exists) {
        Timestamp bedtimeTimestamp = caffeineDoc['bedtime'];
        DateTime bedtime = bedtimeTimestamp.toDate();

        String formattedTime = "${bedtime.hour.toString().padLeft(
            2, '0')}:${bedtime.minute.toString().padLeft(2, '0')}:${bedtime
            .second.toString().padLeft(2, '0')} ${bedtime.hour >= 12
            ? 'PM'
            : 'AM'}";

        return formattedTime;
      } else {
        return 'Bedtime not found';
      }
    } catch (e) {
      print("Error getting bedtime: $e");
      return 'Error retrieving bedtime';
    }
  }

  Future<void> updateBedtime(
      {required String uid, required TimeOfDay bedtime}) async {
    try {
      DateTime updatedBedtime = DateTime(
        2024,
        1,
        1,
        bedtime.hour,
        bedtime.minute,
      );

      Timestamp bedtimeTimestamp = Timestamp.fromDate(updatedBedtime);

      await _firestore.collection('caffeine').doc(uid).update({
        'bedtime': bedtimeTimestamp,
      });

      print("Bedtime updated successfully");
    } catch (e) {
      print("Error updating bedtime: $e");
      throw e;
    }
  }

  Future<void> addItemToPersonalList({
    required String uid,
    required String name,
    required int caffeineAmount,
    required String category,
    required int? size, // Nullable for cases where size is not applicable
  }) async {
    try {
      DocumentReference userPersonalListDoc = _firestore.collection(
          'personalList').doc(uid);

      // Update the document by appending a new item to an array or creating one
      await userPersonalListDoc.update({
        'items': FieldValue.arrayUnion([
          {
            'name': name,
            'caffeineAmount': caffeineAmount,
            'category': category,
            'size': size ?? '0',
          }
        ]),
      });

      print("Item added to personal list successfully");
    } catch (e) {
      // If the document does not exist, create it and add the first item
      if (e.toString().contains('not-found')) {
        await _firestore.collection('personalList').doc(uid).set({
          'items': [
            {
              'name': name,
              'caffeineAmount': caffeineAmount,
              'category': category,
              'size': size ?? '0',
            }
          ],
        });
        print("Personal list created and item added successfully");
      } else {
        print("Error adding item to personal list: $e");
        throw e;
      }
    }
  }

  Future<List<Map<String, dynamic>>> getPersonalList(String uid) async {
    try {
      DocumentSnapshot userPersonalListDoc = await _firestore.collection(
          'personalList').doc(uid).get();

      if (userPersonalListDoc.exists) {
        List<dynamic> items = userPersonalListDoc['items'] ?? [];

        return List<Map<String, dynamic>>.from(items.map((item) {
          return {
            'name': item['name'],
            'caffeineAmount': (item['caffeineAmount'] is double)
                ? (item['caffeineAmount'] as double).toInt()
                : item['caffeineAmount'] ?? 0,
            'category': item['category'] ?? '',
            'size': (item['size'] is double)
                ? (item['size'] as double).toInt()
                : item['size'] ?? 0,
            'relatedTerms': List<String>.from(item['relatedTerms'] ?? []),
          };
        }));
      } else {
        print("Personal list not found for user: $uid");
        return [];
      }
    } catch (e) {
      print("Error loading personal list: $e");
      throw Exception("Failed to load personal list");
    }
  }

  Future<void> updateItemNameInPersonalList({
    required String uid,
    required String oldName,
    required String newName,
  }) async {
    try {
      DocumentReference userPersonalListDoc = _firestore.collection('personalList').doc(uid);
      DocumentSnapshot userPersonalListSnapshot = await userPersonalListDoc.get();

      if (userPersonalListSnapshot.exists) {
        List<dynamic> items = userPersonalListSnapshot['items'] ?? [];

        List<dynamic> updatedItems = items.map((item) {
          if (item['name'] == oldName) {
            item['name'] = newName;
          }
          return item;
        }).toList();

        await userPersonalListDoc.update({'items': updatedItems});
      }
    } catch (e) {
      print("Error updating item name: $e");
      throw e;
    }
  }

  Future<void> updateItemInPersonalList({
    required String uid,
    required String oldName, // To identify the item in the list
    required Map<String, dynamic> updatedItem, // Contains the new values (name, caffeineAmount, size)
  }) async {
    try {
      DocumentReference userPersonalListDoc = _firestore.collection('personalList').doc(uid);
      DocumentSnapshot userPersonalListSnapshot = await userPersonalListDoc.get();

      if (userPersonalListSnapshot.exists) {
        List<dynamic> items = userPersonalListSnapshot['items'] ?? [];

        List<dynamic> updatedItems = items.map((item) {
          if (item['name'] == oldName) {
            return {
              'name': updatedItem['name'] ?? item['name'], // Update name if provided
              'caffeineAmount': updatedItem['caffeineAmount'] ?? item['caffeineAmount'], // Update caffeineAmount if provided
              'size': updatedItem['size'] ?? item['size'], // Update size if provided
            };
          }
          return item;
        }).toList();

        await userPersonalListDoc.update({'items': updatedItems});
      }
    } catch (e) {
      print("Error updating item: $e");
      throw e;
    }
  }


  Future<void> removeItemFromPersonalList({
    required String uid,
    required String itemName,
  }) async {
    try {
      DocumentReference userPersonalListDoc = _firestore.collection('personalList').doc(uid);

      DocumentSnapshot userPersonalListSnapshot = await userPersonalListDoc.get();

      if (userPersonalListSnapshot.exists) {
        List<dynamic> items = userPersonalListSnapshot['items'] ?? [];

        List<dynamic> updatedItems = items.where((item) => item['name'] != itemName).toList();

        await userPersonalListDoc.update({
          'items': updatedItems,
        });

        print("Item removed from personal list successfully");
      } else {
        print("Personal list not found for user: $uid");
      }
    } catch (e) {
      print("Error removing item from personal list: $e");
      throw e;
    }
  }


  Future<bool?> calculateCaffeine({
    required BuildContext context,
    required String uid,
    required String itemName,
    required double caffeineContent,
    required String category,
    required int size,
  }) async {
    try {
      DocumentSnapshot userCaffeineDoc = await _firestore.collection('caffeine')
          .doc(uid)
          .get();

      if (userCaffeineDoc.exists) {
        int caffeineLimit = userCaffeineDoc['caffeineLimit'] ??
            400; //default if not set
        DateTime cafEnd = (userCaffeineDoc['cafEnd'] as Timestamp).toDate();

        if (cafEnd.isBefore(DateTime.now())) {
          cafEnd = DateTime.now();
        }

        double height = double.parse(await getHeight(uid));
        double weight = double.parse(await getWeight(uid));
        double bmi = weight / (height * height);

        double halfLife = 4.0; // Average half-life of caffeine in hours
        halfLife = halfLife * (bmi / 23.0); // Adjust half-life based on BMI

        double cafTime = 0.0;
        double cafRemaining = caffeineContent;

        while (cafRemaining > 60) {
          cafRemaining /= 2; // Halve the remaining caffeine
          cafTime += (halfLife * 60); // Add time in minutes for each half-life
        }

        cafTime +=
            (halfLife / 2) * (cafRemaining / 60) * 60; //convert to minutes

        double multiplier = 1.0;
        multiplier = await getMultiplier(uid);
        cafTime *= multiplier;

        Duration cafDuration = Duration(minutes: cafTime.toInt());
        cafEnd = cafEnd.add(cafDuration);
        int totalMinutes = cafEnd
            .difference(DateTime.now())
            .inMinutes;
        Map<String, dynamic> history = await getCaffeineHistory(uid);
        if (history.isNotEmpty) {
          List<dynamic> itemsConsumed = history['itemsConsumed'] ?? [];

          DateTime today = DateTime.now();
          int totalCaffeineConsumedToday = 0;

          for (var item in itemsConsumed) {
            Map<String, dynamic> itemData = item as Map<String, dynamic>;

            Timestamp timestamp = itemData['timeConsumed'];
            DateTime consumedDate = timestamp.toDate();

            if (consumedDate.year == today.year &&
                consumedDate.month == today.month &&
                consumedDate.day == today.day) {
              totalCaffeineConsumedToday +=
                  (itemData['caffeineContent'] as double).toInt();
            }
          }
          if (totalCaffeineConsumedToday > caffeineLimit) {
            bool? confirmed = await showYesNoDialog(context, "Warning",
                "If you consume this item you will have exceeded your caffeine limit. \n Consume anyway?");
            if (!confirmed!) {
              return false;
            }
          }

          String bedtime = await getBedtime(uid);
          final format = DateFormat("hh:mm:ss");
          DateTime bedtimeDateTime = format.parse(bedtime);

          bedtimeDateTime = DateTime(
            DateTime
                .now()
                .year,
            DateTime
                .now()
                .month,
            DateTime
                .now()
                .day,
            bedtimeDateTime.hour,
            bedtimeDateTime.minute,
            bedtimeDateTime.second,
          );

          // If the bedtime time has already passed today, set it to tomorrow
          if (bedtimeDateTime.isBefore(DateTime.now())) {
            bedtimeDateTime = bedtimeDateTime.add(Duration(days: 1));
          }

          if (cafEnd.isAfter(bedtimeDateTime)) {
            bool? confirmed = await showYesNoDialog(context, "Warning",
                "If you consume this item it may interupt your sleep tonight. \n Consume anyway?");
            if (!confirmed!) {
              return false;
            }
          }

          await _firestore.collection('caffeine').doc(uid).update({
            'cafEnd': Timestamp.fromDate(cafEnd),
            'totalMins': totalMinutes,
          });

          await _firestore.collection('caffeineHistory').doc(uid).update({
            'itemsConsumed': FieldValue.arrayUnion([
              {
                'name': itemName,
                'caffeineContent': caffeineContent,
                'timeConsumed': Timestamp.now(),
              }
            ])
          });

          print("Caffeine calculation and data update successful.");

          if (category != "Other Food")
          {
            calculateHydration(context: context, uid: uid, category: category, size: size.toDouble());
            print("Hydration updated from caffeine page");
          }
          else
            {
              print("No hydration update required because category is $category");
            }
          return true;
        } else {
          print("User caffeine data not found for $uid");
        }
      }
    } catch (e, stackTrace) {
      if (e is FirebaseException) {
        print("FirebaseException (${e.code}): ${e.message}");
      } else {
        print("Error calculating caffeine: $e");
      }
      print("Stack trace: $stackTrace");
      return false;
    }
  }

  Future<int> getCaffeineLimit(String uid) async {
    try {
      DocumentSnapshot userCaffeineDoc = await _firestore.collection('caffeine')
          .doc(uid)
          .get();

      if (userCaffeineDoc.exists) {
        return userCaffeineDoc['caffeineLimit'];
      } else {
        print("User caffeine data not found for $uid");
        return 400; // Default value
      }
    } catch (e) {
      print("Error retrieving caffeine limit: $e");
      throw e;
    }
  }

  Future<void> updateCaffeineLimit({
    required String uid,
    required int newCaffeineLimit,
  }) async {
    try {
      // Update the caffeineLimit field in the 'caffeine' collection for the given user
      await _firestore.collection('caffeine').doc(uid).update({
        'caffeineLimit': newCaffeineLimit,
      });
      print("Caffeine limit updated successfully to $newCaffeineLimit");
    } catch (e) {
      print("Error updating caffeine limit: $e");
      throw e;
    }
  }


  Future<Map<String, dynamic>> getCaffeineHistory(String uid) async {
    try {
      DocumentReference historyDocRef =
      _firestore.collection('caffeineHistory').doc(uid);

      // Check if the document exists
      DocumentSnapshot historyDoc = await historyDocRef.get();

      if (!historyDoc.exists) {
        // If the document doesn't exist, create it with an empty array
        await historyDocRef.set({
          'itemsConsumed': [],
        });
        print("Caffeine history document created for $uid with an empty array.");
        return {
          'itemsConsumed': [],
        };
      } else {
        // Retrieve the array of maps
        List<dynamic> itemsConsumed = historyDoc['itemsConsumed'] ?? [];

        // If the array is empty, return an empty map
        if (itemsConsumed.isEmpty) {
          return {
            'itemsConsumed': [],
          };
        }

        // Return the valid caffeine history data
        return {
          'itemsConsumed': itemsConsumed,
        };
      }
    } catch (e) {
      print("Error retrieving caffeine history: $e");
      throw e;
    }
  }

  Future<DateTime?> getCaffeineEndTime(String uid) async {
    try {
      DocumentSnapshot userCaffeineDoc = await _firestore.collection('caffeine').doc(uid).get();

      if (userCaffeineDoc.exists) {
        Timestamp? cafEndTimestamp = userCaffeineDoc['cafEnd'];
        if (cafEndTimestamp != null) {
          return cafEndTimestamp.toDate();
        } else {
          print("cafEnd field not found for user: $uid");
          return null;
        }
      } else {
        print("Caffeine document not found for user: $uid");
        return null;
      }
    } catch (e) {
      print("Error retrieving cafEnd: $e");
      throw e;
    }
  }

  Future<Map<String, dynamic>?> getLastItem(String uid) async {
    try {
      DocumentSnapshot userHistoryDoc = await _firestore.collection('caffeineHistory').doc(uid).get();

      if (userHistoryDoc.exists) {
        List<dynamic> itemsConsumed = userHistoryDoc['itemsConsumed'] ?? [];

        if (itemsConsumed.isNotEmpty) {
          Map<String, dynamic> lastItem = Map<String, dynamic>.from(itemsConsumed.last);
          return {
            'name': lastItem['name'],
            'timeConsumed': lastItem['timeConsumed'],
          };
        } else {
          print("No items consumed for user: $uid");
          return null;
        }
      } else {
        print("Caffeine history document not found for user: $uid");
        return null;
      }
    } catch (e) {
      print("Error retrieving last item: $e");
      throw e;
    }
  }

  Future<int?> getTotalMinutes(String uid) async {
    try {
      DocumentSnapshot userCaffeineDoc = await _firestore.collection('caffeine').doc(uid).get();

      if (userCaffeineDoc.exists) {
        int? totalMinutes = userCaffeineDoc['totalMins'];
        if (totalMinutes != null) {
          return totalMinutes;
        } else {
          print("totalMins field not found for user: $uid");
          return null;
        }
      } else {
        print("Caffeine document not found for user: $uid");
        return null;
      }
    } catch (e) {
      print("Error retrieving totalMins: $e");
      throw e;
    }
  }

  Future<bool> doAllFieldsExist(String uid) async {
    try {
      // Retrieve both documents asynchronously
      DocumentSnapshot caffeineDoc = await _firestore.collection('caffeine').doc(uid).get();
      DocumentSnapshot hydrationDoc = await _firestore.collection('hydration').doc(uid).get();

      // Extract data safely
      final caffeineData = caffeineDoc.data() as Map<String, dynamic>?;
      final hydrationData = hydrationDoc.data() as Map<String, dynamic>?;

      // Log if any document is missing
      if (caffeineData == null) {
        print("Caffeine document data is null for user: $uid");
        return false;
      }
      if (hydrationData == null) {
        print("Hydration document data is null for user: $uid");
        return false;
      }

      // Required fields for each collection
      List<String> caffeineFields = ['bedtime', 'caffeineLimit'];
      List<String> hydrationFields = ['dailyGoal'];

      // Check if all required fields exist
      bool caffeineFieldsExist = caffeineFields.every((field) => caffeineData.containsKey(field));
      bool hydrationFieldsExist = hydrationFields.every((field) => hydrationData.containsKey(field));

      return caffeineFieldsExist && hydrationFieldsExist;
    } catch (e) {
      print("Error checking fields: $e");
      throw e; // Handle error appropriately
    }
  }


  Future<int?> getDailyGoal(String uid) async {
    try {
      DocumentSnapshot userHydrationDoc = await _firestore.collection('hydration').doc(uid).get();

      if (userHydrationDoc.exists) {
        int? dailyGoal = userHydrationDoc['dailyGoal'];
        if (dailyGoal != null) {
          return dailyGoal;
        } else {
          print("dailyGoal field not found for user: $uid");
          return null;
        }
      } else {
        print("Hydration document not found for user: $uid");
        return null;
      }
    } catch (e) {
      print("Error retrieving dailyGoal: $e");
      throw e;
    }
  }

  Future<void> updateDailyGoal({
    required String uid,
    required int newDailyGoal,
  }) async {
    try {
      // Update the dailyGoal field in the 'hydration' collection for the given user
      await _firestore.collection('hydration').doc(uid).update({
        'dailyGoal': newDailyGoal,
      });
      print("Daily goal updated successfully to $newDailyGoal");
    } catch (e) {
      print("Error updating daily goal: $e");
      throw e;
    }
  }

  Future<int?> getWaterConsumed(String uid) async {
    try {
      DocumentSnapshot userHydrationDoc = await _firestore.collection('hydration').doc(uid).get();

      if (userHydrationDoc.exists) {
        var waterConsumed = userHydrationDoc['waterConsumed'];
        if (waterConsumed != null) {
          if (waterConsumed is int) {
            return waterConsumed;
          } else if (waterConsumed is double) {
            return waterConsumed.toInt();
          }
        } else {
          print("waterConsumed field not found for user: $uid");
          return null;
        }
      } else {
        print("Hydration document not found for user: $uid");
        return null;
      }
    } catch (e) {
      print("Error retrieving waterConsumed: $e");
      throw e;
    }
  }

  Future<bool?> calculateHydration({
    required BuildContext context,
    required String uid,
    required String category,
    required double size,
  }) async {
    try {
      DocumentSnapshot userHydrationDoc = await _firestore.collection('hydration')
          .doc(uid)
          .get();

      await resetWaterConsumed(uid: uid);

      size = size * (hydrationMultipliers[category] ?? 1.0);

      if (userHydrationDoc.exists) {
        var consumed = userHydrationDoc['waterConsumed'] ??
            0;
        if (consumed is int) {
          consumed.toDouble();
        }

          await _firestore.collection('hydration').doc(uid).update({
            'lastDrink': Timestamp.now(),
            'waterConsumed': (consumed+size),
          });

          await _firestore.collection('hydrationHistory').doc(uid).update({
            'drinksConsumed': FieldValue.arrayUnion([
              {
                'category': category,
                'waterContent': size,
                'timeConsumed': Timestamp.now(),
              }
            ])
          });

          print("Hydration calculation and data update successful.");
          return true;
        } else {
          print("User hydration data not found for $uid");
        }
    } catch (e) {
      print("Error calculating hydration: $e");
      return false;
    }
  }

  Future<void> resetWaterConsumed({
    required String uid,
  }) async {
    try {
      DateTime? lastDrink = await getLastDrink(uid);

      if (lastDrink != null) {
        DateTime now = DateTime.now();
        DateTime today = DateTime(now.year, now.month, now.day);
        DateTime lastDrinkDate = DateTime(lastDrink.year, lastDrink.month, lastDrink.day);

        // Check if lastDrink was yesterday or earlier
        if (lastDrinkDate.isBefore(today)) {
          // Reset water consumed
          await _firestore.collection('hydration').doc(uid).update({
            'waterConsumed': 0,
          });

          print("Water consumed successfully reset");
        } else {
          print("Water consumed not reset as the last drink was today.");
        }
      } else {
        print("No lastDrink found; no reset performed.");
      }
    } catch (e) {
      print("Error resetting water consumed: $e");
      throw e;
    }
  }


  Future<DateTime?> getLastDrink(String uid) async {
    try {
      DocumentSnapshot userHydrationDoc = await _firestore.collection('hydration').doc(uid).get();

      if (userHydrationDoc.exists) {
        Timestamp? lastDrinkTimestamp = userHydrationDoc['lastDrink'];
        if (lastDrinkTimestamp != null) {
          return lastDrinkTimestamp.toDate();
        } else {
          print("lastDrink field not found for user: $uid");
          return null;
        }
      } else {
        print("Hydration document not found for user: $uid");
        return null;
      }
    } catch (e) {
      print("Error retrieving lastDrink: $e");
      throw e;
    }
  }

  Future<void> updateHydrationGoal({required String uid, required int newHydrationGoal}) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'hydrationGoal': newHydrationGoal,
    });
  }

  Future<List<Map<String, dynamic>>> getHydrationHistoryForPeriod(
      String uid, DateTime startDate, DateTime endDate) async {
    try {
      DocumentSnapshot snapshot =
      await _firestore.collection('hydrationHistory').doc(uid).get();

      if (!snapshot.exists || snapshot.data() == null) {
        return [];
      }

      List<dynamic> hydrationData = (snapshot.data() as Map<String, dynamic>)['drinksConsumed'] ?? [];
      List<Map<String, dynamic>> filteredData = [];

      for (var entry in hydrationData) {
        DateTime timeConsumed = (entry['timeConsumed'] as Timestamp).toDate();

        // Normalize the timeConsumed to the start of the day
        DateTime normalizedTime = DateTime(timeConsumed.year, timeConsumed.month, timeConsumed.day);
        DateTime normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
        DateTime normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

        if (normalizedTime.isAfter(normalizedStart.subtract(Duration(days: 1))) &&
            normalizedTime.isBefore(normalizedEnd.add(Duration(days: 1)))) {
          filteredData.add(entry);
        }
      }
      return filteredData;
    } catch (e) {
      print("Error fetching hydration history: $e");
      return [];
    }
  }

  Map<String, double> calculateDailyWaterConsumption(
      List<Map<String, dynamic>> hydrationData) {
    Map<String, double> dailyConsumption = {};

    for (var entry in hydrationData) {
      DateTime date = (entry['timeConsumed'] as Timestamp).toDate();
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);

      double waterContent = (entry['waterContent'] as num).toDouble();

      if (dailyConsumption.containsKey(formattedDate)) {
        dailyConsumption[formattedDate] = dailyConsumption[formattedDate]! + waterContent;
      } else {
        dailyConsumption[formattedDate] = waterContent;
      }
    }
    return dailyConsumption;
  }

  Map<String, int> calculateDrinkTypeCounts(List<Map<String, dynamic>> hydrationData) {
    Map<String, int> drinkTypeCounts = {};

    for (var entry in hydrationData) {
      String category = entry['category'];

      if (drinkTypeCounts.containsKey(category)) {
        drinkTypeCounts[category] = drinkTypeCounts[category]! + 1;
      } else {
        drinkTypeCounts[category] = 1;
      }
    }
    return drinkTypeCounts;
  }

  Future<List<Map<String, dynamic>>> getCaffeineHistoryForPeriod(
      String uid, DateTime startDate, DateTime endDate) async {
    try {
      DocumentSnapshot snapshot =
      await _firestore.collection('caffeineHistory').doc(uid).get();

      if (!snapshot.exists || snapshot.data() == null) {
        return [];
      }

      List<dynamic> hydrationData = (snapshot.data() as Map<String, dynamic>)['itemsConsumed'] ?? [];
      List<Map<String, dynamic>> filteredData = [];

      for (var entry in hydrationData) {
        DateTime timeConsumed = (entry['timeConsumed'] as Timestamp).toDate();

        // Normalize the timeConsumed to the start of the day
        DateTime normalizedTime = DateTime(timeConsumed.year, timeConsumed.month, timeConsumed.day);
        DateTime normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
        DateTime normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

        if (normalizedTime.isAfter(normalizedStart.subtract(Duration(days: 1))) &&
            normalizedTime.isBefore(normalizedEnd.add(Duration(days: 1)))) {
          filteredData.add(entry);
        }
      }
      return filteredData;
    } catch (e) {
      print("Error fetching hydration history: $e");
      return [];
    }
  }

  Map<String, double> calculateDailyCaffeineConsumption(
      List<Map<String, dynamic>> caffeineData) {
    Map<String, double> dailyConsumption = {};

    for (var entry in caffeineData) {
      DateTime date = (entry['timeConsumed'] as Timestamp).toDate();
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);

      double caffeineContent = (entry['caffeineContent'] as num).toDouble();

      if (dailyConsumption.containsKey(formattedDate)) {
        dailyConsumption[formattedDate] = dailyConsumption[formattedDate]! + caffeineContent;
      } else {
        dailyConsumption[formattedDate] = caffeineContent;
      }
    }
    return dailyConsumption;
  }

  Map<String, int> calculateItemTypeCounts(List<Map<String, dynamic>> caffeineData) {
    Map<String, int> itemTypeCounts = {};

    for (var entry in caffeineData) {
      String category = entry['name'];

      if (itemTypeCounts.containsKey(category)) {
        itemTypeCounts[category] = itemTypeCounts[category]! + 1;
      } else {
        itemTypeCounts[category] = 1;
      }
    }
    return itemTypeCounts;
  }

  Future<double> getMultiplier(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('caffeine').doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('multiplier')) {
          return (data['multiplier'] as num).toDouble();
        }
      }

      print("Multiplier not found for $uid. Returning default: 1.0");
      return 1.0; // Default multiplier

    } catch (e) {
      print("Error retrieving multiplier: $e");
      throw e;
    }
  }

  Future<void> updateMultiplier({
    required String uid,
    required double newMultiplier,
  }) async {
    try {
      DocumentReference userDocRef = _firestore.collection('caffeine').doc(uid);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userDocRef);

        if (snapshot.exists) {
          // Update existing multiplier
          double oldMultiplier = await getMultiplier(uid);
          newMultiplier *= oldMultiplier;
          transaction.update(userDocRef, {'multiplier': newMultiplier});
          print("Multiplier updated successfully to $newMultiplier");
        } else {
          // Create document and set multiplier field
          transaction.set(userDocRef, {'multiplier': newMultiplier});
          print("Multiplier created successfully with value $newMultiplier");
        }
      });
    } catch (e) {
      print("Error updating multiplier: $e");
      throw e;
    }
  }

}

