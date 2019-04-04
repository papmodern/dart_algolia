import 'dart:async';
import 'package:test/test.dart';
import 'package:algolia/algolia.dart';

void main() async {
  ///
  /// Initiate Algolia in your project
  ///
  Algolia algolia = Application.algolia;
  AlgoliaTask taskAdded,
      taskUpdated,
      taskDeleted,
      taskBatch,
      taskClearIndex,
      taskDeleteIndex;
  AlgoliaObjectSnapshot addedObject;

  /// Storage for returned Object IDs
  final List<String> ids = [];

  ///
  /// 1. Perform Adding Object to existing Index.
  ///
  test("1. Perform Adding Object to existing Index.", () async {
    Map<String, dynamic> addData = {
      'name': 'John Smith',
      'contact': '+1 609 123456',
      'email': 'johan@example.com',
      'isDelete': false,
      'status': 'published',
      'createdAt': DateTime.now(),
      'modifiedAt': DateTime.now(),
    };
    taskAdded = await algolia.instance.index('contacts').addObject(addData);

    // Checking if has [AlgoliaTask]
    expect(taskAdded.runtimeType, AlgoliaTask);
    print(taskAdded.data);
    print('\n\n');
  });

  ///
  /// 2. Perform Get Object to existing Index.
  ///
  /// -- A Delay of 3 seconds is added for algolia to cdn the object for retrieval.
  test("2. Perform Get Object to existing Index.", () async {
    addedObject = await Future.delayed(Duration(seconds: 3), () async {
      return await algolia.instance
          .index('contacts')
          .object(taskAdded.data['objectID'].toString())
          .getObject();
    });

    // Checking if has [AlgoliaObjectSnapshot]
    expect(addedObject.runtimeType, AlgoliaObjectSnapshot);
    print(addedObject.data);
    print('\n\n');
  });

  ///
  /// 3. Perform Updating Object to existing Index.
  ///
  test("3. Perform Updating Object to existing Index.", () async {
    Map<String, dynamic> updateData =
        Map<String, dynamic>.from(addedObject.data);
    updateData['contact'] = '+1 609 567890';
    updateData['modifiedAt'] = DateTime.now();
    taskUpdated = await algolia.instance
        .index('contacts')
        .object(addedObject.objectID)
        .updateData(updateData);

    // Checking if has [AlgoliaTask]
    expect(taskUpdated.runtimeType, AlgoliaTask);
    print(taskUpdated.data);
    print('\n\n');
  });

  ///
  /// 4. Perform Delete Object to existing Index.
  ///
  test("4. Perform Delete Object to existing Index.", () async {
    taskDeleted = await algolia.instance
        .index('contacts')
        .object(addedObject.objectID)
        .deleteObject();

    // Checking if has [AlgoliaTask]
    expect(taskDeleted.runtimeType, AlgoliaTask);
    print(taskDeleted.data);
    print('\n\n');
  });

  ///
  /// 5. Perform Batch
  ///
  test("5. Perform Batch", () async {
    AlgoliaBatch batch = algolia.instance.index('contacts').batch();
    batch.clearIndex();
    for (int i = 0; i < 10; i++) {
      Map<String, dynamic> addData = {
        'name': 'John ${DateTime.now().microsecond}',
        'contact': '+1 ${DateTime.now().microsecondsSinceEpoch}',
        'email': 'johan.${DateTime.now().microsecond}@example.com',
        'isDelete': false,
        'status': 'published',
        'createdAt': DateTime.now(),
        'modifiedAt': DateTime.now(),
      };
      batch.addObject(addData);
    }

    // Get Result/Objects
    taskBatch = await batch.commit();

    // Checking if has [AlgoliaTask]
    expect(taskBatch.runtimeType, AlgoliaTask);
    print(taskBatch.data);
    print('\n\n');

    // Add ids to list for test 7
    final List batchIds = taskBatch.data['objectIDs'];
    ids.addAll([batchIds[3], batchIds[4]]);
  });

  ///
  /// 6. Perform Query
  ///
  test("6. Perform Query", () async {
    AlgoliaQuery query = algolia.instance.index('contacts').search('john');

    // Perform multiple facetFilters
    query = query.setFacetFilter('status:published');
    query = query.setFacetFilter('isDelete:false');

    // Get Result/Objects
    AlgoliaQuerySnapshot snap = await query.getObjects();

    // Checking if has [AlgoliaQuerySnapshot]
    expect(snap.runtimeType, AlgoliaQuerySnapshot);
    print('Hits count: ${snap.nbHits}');
    print('\n\n');
  });

  ///
  /// 7. Get Objects by ObjectID
  ///
  test('7. Get Objects by ObjectID', () async {
    List<AlgoliaObjectSnapshot> results = await Future.delayed(
        Duration(seconds: 3),
        () => algolia.instance.index('contacts').getObjectsByIds(ids));

    expect(results.length, 2);
    expect(results.first.objectID, ids.first);
  });

  ///
  /// 8. Perform List all Indices
  ///
  test("8. Perform List all Indices", () async {
    AlgoliaIndexesSnapshot indices = await algolia.instance.getIndices();

    // Checking if has [AlgoliaIndexesSnapshot]
    expect(indices.runtimeType, AlgoliaIndexesSnapshot);
    print('Indices count: ${indices.items.length}');
    print('\n\n');
  });

  ///
  /// 9. Get Settings of 'contacts' index
  ///
  test("9. Get Settings of 'contacts' index", () async {
    Map<String, dynamic> settings =
        await algolia.instance.index('contacts').settings.getSettings();

    // Checking if has [Map<String, dynamic>]
    expect(settings.isEmpty, false);
    print(settings);
    print('\n\n');
  });

  ///
  /// 10. Set Settings of 'contacts' index
  ///
  test("10. Set Settings of 'contacts' index", () async {
    AlgoliaSettings settings =
        await algolia.instance.index('contacts').settings;

    settings =
        settings.setReplicas(const ['contacts_copy_1', 'contacts_copy_2']);

    AlgoliaTask response = await settings.setSettings();

    // Checking if has [AlgoliaTask]
    expect(response.runtimeType, AlgoliaTask);
    print(response);
    print('\n\n');
  });

  ///
  /// 11. Perform Clear Index.
  ///
  test("11. Perform Clear Index.", () async {
    taskClearIndex = await algolia.instance.index('contacts').clearIndex();

    // Checking if has [AlgoliaTask]
    expect(taskClearIndex.runtimeType, AlgoliaTask);
    print(taskClearIndex.data);
    print('\n\n');
  });

  ///
  /// 12. Perform Delete Index.
  ///
  test("12. Perform Delete Indexes.", () async {
    taskDeleteIndex = await algolia.instance.index('contacts').deleteIndex();
    taskDeleteIndex =
        await algolia.instance.index('contacts_copy_1').deleteIndex();
    taskDeleteIndex =
        await algolia.instance.index('contacts_copy_2').deleteIndex();

    // Checking if has [AlgoliaTask]
    expect(taskDeleteIndex.runtimeType, AlgoliaTask);
    print(taskDeleteIndex.data);
    print('\n\n');
  });
}

class Application {
  static final Algolia algolia = Algolia.init(
    applicationId: 'YOUR_APPLICATION_ID',
    apiKey: 'YOUR_API_KEY',
  );
}
