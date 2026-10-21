import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:todo_list_flutter/widgets/empty_state.dart';

void main(){
  runApp(const MaterialApp(
   debugShowCheckedModeBanner: false,
   home: Scaffold(
    body: Center(
      child: EmptyState(),
    )
   )
  ));
}
