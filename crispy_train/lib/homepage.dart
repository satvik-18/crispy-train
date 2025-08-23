import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final user = FirebaseAuth.instance.currentUser;
  signout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Homepage")),
      body: Center(child: Text(user!.email ?? 'No email')),
      floatingActionButton: FloatingActionButton(
        onPressed: (() => showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Sign Out"),
            content: Text("Are you sure you want to sign out?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  signout();
                  Navigator.of(context).pop();
                },
                child: Text("Confirm"),
              ),
            ],
          ),
        )),
        child: Icon(Icons.logout),
      ),
    );
  }
}
