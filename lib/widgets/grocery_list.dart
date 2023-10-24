import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/category.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;
import '../models/grocery_item.dart';

/* ***** This is the page where we are using (get) method ***** */

/* We also using here delete item from server */

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading=true;
  String? _error;

  @override
  void initState() {
    _loadItem();
    super.initState();
  }

  void _loadItem() async {
    final url = Uri.https(
        'shoppinglist-93405-default-rtdb.firebaseio.com', 'shopping-list.json');


    //jodi amader device e internet connection na thake shei khetre je error ashbe
    //oita handle korbo

    //jodi error thake throw Exception er por ar kono code run korbe na
    //throw Exception('An error occured!');

    //amra ekhane try catch use kore error handle korbo

    try{
      final response = await http.get(url);
      if(response.statusCode>=400){
        setState(() {
          _error='Failed to fetch data. Please try again letter.';
        });
      }
      if(response.body==null){
        setState(() {
          _isLoading=false;
        });
        return;
      }
      print(response);
      //amar je data gulo ashlo response e ogulo decode kore map e convert korte hobe
      //jehetu response e key and object ache abar object er modhe string and int both
      //type value ache tai key er jonno first e Map er modhe String then object er jonno
      //abar Map and Map er modhe key String but String,int value thakar jonno dynamic newa
      //hoyeche
      final Map<String, dynamic> listData =
      json.decode(response.body);
      //akhon ei Map type listData ke amra List e convert korbo.Using for loop

      //jehetu key er coresponding e amader object ache tai ekta temporary list niye
      //oi list er modhe object ke rekhe final list _groceryItems e add korbo.
      final List<GroceryItem> loadedItemList = [];
      for (final item in listData.entries) {
        final category=categories.entries.firstWhere((element) => element.value.title==item.value['category']).value;
        loadedItemList.add(
          GroceryItem(
            id: item.key,
            /*jehetu First ekti map ache tar value te arekti map
      tai amra item.value diye map er value ke access nichi
      ar item.value['category'] diye nested map er value show kortechi*/
            name: item.value["name"],
            quantity: item.value["quantity"],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItems=loadedItemList;
        _isLoading=true;
      });
    }catch (error){
      _error=   'Something went wrong! Please try again later.';
    }
  }

  void _addItem() async {
    final newItem=await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if(newItem==null)return;
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index=_groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    //final url = Uri.https(
    //         'shoppinglist-93405-default-rtdb.firebaseio.com', 'shopping-list.json');
    //eikhane last er shopping-list er jaygay amra je item delete korbo oitar id dibo
    //oi id onujayi server tehke data delete hobe
    final url =Uri.https(
        'shoppinglist-93405-default-rtdb.firebaseio.com', 'shopping-list/${item.id}.json');

    final response= await http.delete(url);

    if(response.statusCode>=400){
      setState(() {
        _groceryItems.insert(index,item);
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No items added yet'),
    );

    if(_isLoading){
      content=const Center(child: CircularProgressIndicator(),);
    }
    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              height: 24,
              width: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }
    if(_error!=null){
      content = Center(
        child: Text(_error!),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
