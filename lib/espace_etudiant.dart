import 'package:flutter/material.dart';
import 'package:restaurant_esatic/service/notif.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:restaurant_esatic/login_resto.dart';


class Espace_etudiant extends StatefulWidget{

  @override
  StateEspaceEtudiant createState() => StateEspaceEtudiant();
}

class StateEspaceEtudiant extends State<Espace_etudiant>{

  String? nom;
  String? prenom;
  String? filiere;
  String? matricule;
  String? niveau;
  int? balance;
  String? etat;
  Map<String, dynamic> historique= {};

  // Initialiser une référence à la base de données
  final ref = FirebaseDatabase.instance.ref();


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

  Future<void> recupere() async{

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? card = prefs.getString('card');

    ref.child('comptes/$card').onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        if (snapshot.value != null) {

          Map<Object?, Object?> rawData = snapshot.value as Map<Object?, Object?>;

          Map<String, dynamic> data = {};
          rawData.forEach((key, value) {
            if (key is String) {
              data[key] = value;
            }
          });

          setState(() {
            this.nom = data['nom'];
            this.prenom = data['prenom'];
            this.matricule = data['matricule'];
            this.niveau = data['niveau'];
            this.filiere = data['filiere'];
            this.balance = data['balance'];
            this.etat = data['etat'];
          });

        }
      }
    });

    ref.child('comptes/$card/historiques').onValue.listen((event) {
      NotificationService().showNotif(title: 'Bienvenue', body:'Rester connecter');
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        if (snapshot.value != null) {
          Map<Object?, Object?> rawData = snapshot.value as Map<Object?, Object?>;

          // Convertir les clés en une liste et les trier
          List<String> sortedKeys = rawData.keys.whereType<String>().toList();
          sortedKeys.sort();

          // Parcourir les données dans l'ordre trié des clés
          Map<String, dynamic> data = {};
          for (var key in sortedKeys) {
            data[key] = rawData[key];
          }
          setState(() {
            this.historique =data;
          });
        }
      }
    });

  }


  Future<void> supprime() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('login');
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    testeConnexion();
    recupere();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    supprime();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white,), onPressed: () {
          voirDialogueDeco(alerte: alerteDeco("Voulez vous vous deconnecter", 20));
        }
        ),
        title: const Text("Espace Etudiant", style: TextStyle(color: Colors.white),),
      ),
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height/3.5,
                  child: Card(
                    elevation: 8,
                    color: Colors.blue,
                    margin: EdgeInsets.only(top: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          texteAvecStyle('nom: ${this.nom ?? ''}'),
                        Spacer(),
                        texteAvecStyle('prenom: ${this.prenom ?? ''}'),
                        Spacer(),
                        texteAvecStyle('Matricule: ${this.matricule ?? ''}'),
                        Spacer(),
                        texteAvecStyle('Niveau: ${this.niveau ?? ''}'),
                        Spacer(),
                        texteAvecStyle('Filière: ${this.filiere ?? ''}'),
                        Spacer(),
                        texteAvecStyle('Solde: ${this.balance ?? ''} Frcfa'),
                        Spacer()
                      ],
                    ),
                  ),
                )
              ),
              Padding(padding: EdgeInsets.only(top: 10),
                child: ElevatedButton(onPressed: () async {
                  final SharedPreferences prefs = await SharedPreferences.getInstance();
                  final String? card = prefs.getString('card');
                  if(this.etat == "actif"){
                    await ref.child('comptes/$card/etat').set("bloquer");
                  }else if(this.etat == "bloquer"){
                    await ref.child('comptes/$card/etat').set("actif");
                  }

                },
                    child: Text("${this.etat == "actif" ? "bloquer": "debloquer"}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17
                    ),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue
                  ),
                ),
              ),
              const Padding(padding: EdgeInsets.only(top: 18),
              child: Text('Historique', style: TextStyle(
                  color: Colors.blue,
                fontSize: 30,
                fontWeight: FontWeight.bold
                  ),
                ),
              ),
              Padding(padding: EdgeInsets.only(top: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                      hist(),
                  ],
                  ),
                )
            ],
          ),
        )
      )
    );
  }

  Text texteAvecStyle(String texte){
    return Text(texte, style: const TextStyle(
      fontStyle: FontStyle.normal,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
    );
  }

  AlertDialog alerteDeco(String texte, double? size) {
    return AlertDialog(
      content: Text(texte, style: TextStyle(fontSize: size, color: Colors.red),
      ),
      backgroundColor: Colors.white,
      actions: [
        Row(
          children: [
            TextButton(onPressed: (){
              supprime();
              Navigator.of(context).push( _routeConnexionLogin());
            }, child: Text("OK", style: TextStyle(color: Colors.blue),)),
            TextButton(onPressed: (){
              Navigator.of(context).pop();
            }, child: Text("Annuler", style: TextStyle(color: Colors.blue),))
          ],
        )
      ],
    );

  }

  void voirDialogueDeco({required AlertDialog alerte}){
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx){
          return alerte;
        });
  }


  Route _routeConnexionLogin() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => MyHomePage(),
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


  Widget hist() {

    if(historique.isNotEmpty){
      List<Widget> containers = [];

      // Inverser l'ordre de la map
      Map<dynamic, dynamic> reversedHistorique = historique;

      // Parcours de l'historique inversé
      reversedHistorique.forEach((key, value) {
        List<Widget> children = [];
        value.forEach((key, value) {
          children.add(Text("$key : $value"));
        });

        containers.add(
          Container(
            width:300,
            height: 150,
            margin: EdgeInsets.all(8.0),
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: children,
            ),
          ),
        );
      });

      // Inverser l'ordre des conteneurs
      containers = containers.reversed.toList();

      // Retourner les conteneurs dans une colonne
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: containers,
        ),
      );
      }else {
        return const Text(
          "Aucune valeur",
          style: TextStyle(
            fontSize: 25
          ),
        );
      }
    }


}