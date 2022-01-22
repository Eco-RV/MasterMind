import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

class Tabla {
  int dim = 4;

  operator [](int i) => tabla[i]; // get

  List<Hilera> tabla = [];

  Tabla(int n) {
    dim = n;
    Tirada.dim = n;
    for (int i = 0; i < dim; i++) {
      tabla.add(Hilera());
    }
  }

  void Reset() {
    for (int i = 0; i < dim; i++) {
      tabla[i].clean();
    }
  }
}

class Hilera {
  static var rng = null;
  static const descartable = -1;
  static const elegible = 1;
  static const vacio = 0;

  List<int> hilera = [
    vacio,
    vacio,
    vacio,
    vacio,
    vacio,
    vacio,
    vacio,
    vacio,
    vacio,
    vacio
  ];

  operator []=(int i, int value) => hilera[i] = value; // set

  void clean() {
    for (int i = 0; i < 10; i++) hilera[i] = vacio;
  }

  bool free(i) {
    return (hilera[i] == vacio);
  }

  void mark(i) {
    hilera[i] = elegible;
  }

  void discard(i) {
    hilera[i] = descartable;
  }

  static void init() {
    rng = new Random();
  }

  int next() {
    if (rng == null) Hilera.init();
    int i = rng.nextInt(10);
    for (int j = 0; j < 10; j++) {
      int x = (j + i) % 10;
      if (free(x)) {
        mark(x);
        return x;
      }
    }
    return descartable;
  }
}

class Tirada {
  List<int> tirada = [];
  int m = 0;
  int h = 0;
  static int dim = 4;
  static const vacio = -1;

  String toString() {
    return tirada.toString();
  }

  Tirada() {
    for (int i = 0; i < dim; i++) tirada.add(vacio);
  }

  Tirada.clone(Tirada n) {
    for (int i = 0; i < dim; i++) tirada.add(n.tirada[i]);
    m = n.m;
    h = n.h;
  }

  void clean() {
    for (int i = 0; i < dim; i++) tirada[i] = vacio;
    m = 0;
    h = 0;
  }

  void AuxMenu() {
    print(
        "tirada: ${tirada.toString()} \n Indique muertos y Heridos separados por coma");
  }

  void Print(int i) {
    print("($i): ${tirada.toString()} m:${m}  h:${h}");
  }

  operator [](int i) => tirada[i]; // get
  operator []=(int i, int value) => tirada[i] = value; // set

}

class MasterMind {
  int dim = 4;
  var T;
  var R;

  static const descartable = -1;
  static const elegible = 1;
  static const vacio = 0;

  List<Tirada> historico = [];
  // ignore: prefer_typing_uninitialized_variables
  var t = null;

  void PrintHistorico() {
    int i = 0;

    print("listado historico");

    historico.forEach((element) {
      element.Print(i++);
      print("-----------------------");
    });
  }

  bool EsCifraRepetida(int pos, Tirada t) {
    for (int i = pos - 1; i >= 0; i--) {
      if (t[pos] == t[i]) return true;
    }

    return false;
  }

  bool HayCoherenciaConElHistorico(int pos, Tirada t) {
    bool exit = true;

    historico.forEach((p) {
      int mm = 0;
      int hh = 0;

      for (int i = 0; i < dim; i++) {
        for (int j = 0; j <= pos; j++) {
          if (t[j] == p[i]) {
            if (i == j)
              mm++;
            else
              hh++;
          }
        }
      }
      int x = dim - (pos + 1);
      if (hh > p.h || (hh + x) < p.h) exit = false;
      if (mm > p.m || (mm + x) < p.m) exit = false;
      if ((mm + hh) > (p.m + p.h) || (mm + hh + x) < (p.m + p.h)) exit = false;
    });

    return exit;
  }

  bool isNumeric(String str) {
    try {
      var value = double.parse(str);
    } on FormatException {
      return false;
    } finally {
      return true;
    }
  }

  Tirada? GeneraTirada() {
    var tt = Tirada();
    bool error = false;
    bool end = false;
    int i = 0;

    T.Reset();

    while (!error && !end) {
      if (i == dim) {
        end = true;
        break;
      }

      tt[i] = T[i].next();

      if (tt[i] == descartable) {
        if (i > 0) {
          T[i].clean();
          --i;
          T[i].discard(tt[i]);
        } else {
          print("inconsistencia de datos");
          print("========================");
          error = true;
        }

        continue;
      }

      if (EsCifraRepetida(i, tt) || !HayCoherenciaConElHistorico(i, tt)) {
        T[i].discard(tt[i]);
        continue;
      }

      i = i + 1;
    }

    if (error)
      return null;
    else
      return tt;
  }

  void Menu() {
    t = GeneraTirada();
    if (t == null) {
      PrintHistorico();
      print("inconsistencia de datos");
      print("trate de corregir el error. Indique linea,muertos , heridos");
    } else
      t.AuxMenu();
  }

  void NuevaPartida() {
    historico.clear();
    T = Tabla(dim);
    Hilera.init();
    T.Reset();
  }

  MasterMind([int? n]) {
    if (n != null) dim = n;
    Tirada.dim = dim;
    t = Tirada();
    t.clean();
    R = readLine().listen(processLine);
    NuevaPartida();
    Menu();
  }

  Stream<String> readLine() =>
      io.stdin.transform(utf8.decoder).transform(const LineSplitter());

  void processLine(String tagname) {
    int estado = 0;
    if (tagname != null) {
      List<String> args = tagname.split(',');
      if (args.length == 2 && isNumeric(args[0]) && isNumeric(args[1])) {
        t.m = int.parse(args[0]);
        t.h = int.parse(args[1]);

        if (t.m == dim) {
          print("\n\nFINAL PARTIDA\n\n");
          NuevaPartida();
        } else {
          historico.add(Tirada.clone(t));
          t.clean();
        }
      } else if (args.length == 3 &&
          isNumeric(args[0]) &&
          isNumeric(args[1]) &&
          isNumeric(args[2])) {
        int l = int.parse(args[0]);
        int m = int.parse(args[1]);
        int h = int.parse(args[2]);

        historico[l].m = m;
        historico[l].h = h;

        T.Reset();
        t = GeneraTirada();
      } else {
        switch (args[0]) {
          case 'n':
            {
              NuevaPartida();
            }
            break;

          case 'q':
            {
              R.cancel();
            }
            break;

          case 'h':
            {
              PrintHistorico();
            }
            break;
        }
      }
    }
    Menu();
  }
}

void main(List<String> arguments) {
  int? n = null;
  if (arguments.length > 0) n = int.parse(arguments[0]);
  var M = MasterMind(n);
}
