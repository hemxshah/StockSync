import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {

  final _auth = FirebaseAuth.instance;
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password ='';
  String name = '';

  void submit() async{
    if(!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try{
      if(isLogin){
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      } else{
        final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      }
    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin?'Login':'Sign up')),
      body: Padding(padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if(!isLogin) 
              TextFormField(
                key: ValueKey('name'),
                decoration: InputDecoration(labelText: 'Name'),
                onSaved: (v) => name = v!,
                validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                key: ValueKey('email'),
                decoration: InputDecoration(labelText: 'Email'),
                onSaved: (v) => email = v!,
                validator: (v) => v!.isEmpty ? 'Please enter an email' : null,
              ),

              TextFormField(
                key: ValueKey('password'),
                decoration: InputDecoration(labelText : 'Password'),
                obscureText: true,
                onSaved: (v) => password = v!,
                validator: (v) => v!.isEmpty ? 'Please enter a password' : null,
              ),
              SizedBox(height: 20,),
              ElevatedButton(
                onPressed: submit, 
                child: Text(isLogin? 'Login' : 'Sign up')),
              TextButton(
                onPressed: (){
                  setState(() {
                    isLogin = !isLogin;
                  });
                }, 
                child: Text(isLogin? 'Create an account' : 'Already have an account? Login')),
          ],
        )),)

    );
  }
}