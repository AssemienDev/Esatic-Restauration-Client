import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:restaurant_esatic/espace_etudiant.dart';
import 'package:restaurant_esatic/service/notif.dart';
import 'package:shared_preferences/shared_preferences.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});


  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  FirebaseDatabase database = FirebaseDatabase.instance;
  late TextEditingController cardNumber;
  late TextEditingController passe;
  String? card;

  Future<bool> connexion() async{
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      return true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      return true;
    } else{
      return false;
    }
  }

  Future<void> testeConnexion() async{
    bool valeur = await connexion();
    if(valeur == false){
      final snackbar = SnackBar(content: Text("Veuillez vous connecter a Internet"), backgroundColor: Colors.red,);
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    }
  }

  Future<void> sauvegarde() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('card', cardNumber.text);
    await prefs.setString('passe', passe.text);
    await prefs.setBool('login', true);

    setState(() {
      cardNumber.text = cardNumber.text ?? '';
      passe.text = '';
    });
  }

  Future<void> recuperer() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? card =  prefs.getString('card');
    final bool? login = prefs.getBool('login');

    if(login == true) {
      setState(() {
        this.card = card;
      });

      final ref = FirebaseDatabase.instance.ref();
      final snapshot = await ref.child('comptes/$card').get();
      if (snapshot.exists) {
        Navigator.of(context).push(_routeConnexionLogin());
      }
    }
  }


  @override
  void initState() {
    super.initState();
    cardNumber = TextEditingController();
    passe = TextEditingController();
    testeConnexion();
    recuperer();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    passe.dispose();
    cardNumber.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
            icon: Icon(Icons.home, color: Colors.white,), onPressed: () {
          print("ok");
        }
        ),
        title: Text("Acceuil Restaurant", style: TextStyle(color: Colors.white),),
      ),
      body: Center(

          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(bottom: 50),
                  child: const Text("Bienvenue sur l'espace de connexion", style: TextStyle(
                      color: Colors.blue, fontSize: 30, fontWeight: FontWeight.bold
                  ),
                  ),
                ),
                saisie(position: 10, icon: Icons.add_card_outlined, couleur: Colors.black54, texte: "Entrer votre numéro de carte", clavier: TextInputType.number, controller: cardNumber, choix: false, choix2: false),
                saisie(position: 80, icon: Icons.password, couleur: Colors.black54, texte: "Entrer votre code", clavier: TextInputType.number, controller: passe, choix: true, choix2: false),
                ElevatedButton(onPressed: () async{
                  bool valeur = await connexion();
                  if(valeur == true){
                    if(!cardNumber.text.isEmpty && !passe.text.isEmpty){
                      base();
                    }else{
                      voirDialogue(alerte: alerte("Veuillez entrer le numéro de la carte et le mot de passe", 20));
                    }
                  }else{
                    final snackbar = SnackBar(content: Text("Veuillez vous connecter a Internet"), backgroundColor: Colors.red,);
                    ScaffoldMessenger.of(context).showSnackBar(snackbar);
                  }
                },
                    child: Text("CONNEXION", style: TextStyle(
                        color: Colors.white,
                        fontSize: 20
                    ),
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        elevation: 4,
                        minimumSize: Size(100, 60)
                    )
                ),
              ],
            ),
          )
      ),
    );
  }

  Widget saisie({double? position, IconData? icon, Color? couleur, String? texte, TextInputType? clavier, TextEditingController? controller, bool? choix, bool? choix2}){
    return Container(
      margin: EdgeInsets.only(bottom: position!),
      child: Padding(padding: EdgeInsets.all(30),
        child: TextField(
          readOnly: choix2!,
          controller: controller,
          obscureText: choix!,
          decoration: InputDecoration(
            hintStyle: TextStyle(color: couleur),
            hintText: card ?? texte! ,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            prefixIcon: Icon(icon!),
            focusColor: Colors.blue,
          ),
          keyboardType: clavier,
        ),
      ),
    );
  }

  Future<void> base() async{
      final ref = FirebaseDatabase.instance.ref();
      final snapshot = await ref.child('comptes/${cardNumber.text}').get();
      if (snapshot.exists) {
        if(snapshot.value != null){
          Map<Object?, Object?> rawData = snapshot.value as Map<Object?, Object?>;

          Map<String, dynamic> data = {};
          rawData.forEach((key, value) {
            if (key is String) {
              data[key] = value;
            }
          });
          if(data.containsKey('code') && data['code'] == passe.text){
            sauvegarde();
            Navigator.of(context).push(_routeConnexionNotLogin());
          }else{
            voirDialogue(alerte: alerte("Mot de passe Incorrect", 30));
          }
        }
      } else {
        voirDialogue(alerte: alerte("Carte Inconnu", 30));
      }
  }

  AlertDialog alerte(String texte, double? size) {
    return AlertDialog(
      content: Text(texte, style: TextStyle(fontSize: size, color: Colors.red),
      ),
      backgroundColor: Colors.white,
      actions: [
        TextButton(onPressed: (){
          Navigator.of(context).pop();
        }, child: Text("OK", style: TextStyle(color: Colors.blue),))
      ],
    );

  }

  void voirDialogue({required AlertDialog alerte}){
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx){
          return alerte;
        });
  }

  Route _routeConnexionNotLogin() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => Espace_etudiant(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  Route _routeConnexionLogin() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => Espace_etudiant(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final begin = 0.0;
        final end = 1.0;
        final curve = Curves.ease;

        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        final scaleAnimation = animation.drive(tween);

        return ScaleTransition(
          scale: scaleAnimation,
          child: child,
        );
      },
    );
  }
}
