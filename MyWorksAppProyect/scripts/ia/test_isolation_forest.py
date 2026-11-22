import os
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from isolation_forest import MIN_FILAS, decidir, main, puntajes


def fila(user: str, resenas: float, disputas: float, cuentas: float) -> dict:
    return {
        "user_id": user,
        "resenas": resenas,
        "disputas": disputas,
        "cuentas": cuentas,
    }


class IsolationForestTest(unittest.TestCase):
    def test_pocos_datos_no_alertan(self):
        informe = decidir([fila("a", 1, 0, 1)], ["resenas", "disputas", "cuentas"], True)
        self.assertEqual(informe["modo"], "solo_reglas")
        self.assertEqual(informe["alertas"], [])

    def test_un_outlier_puntua_mas_alto(self):
        filas = [fila(f"u{i}", 1, 0, 1) for i in range(MIN_FILAS)]
        filas.append(fila("raro", 40, 12, 15))
        columnas = ["resenas", "disputas", "cuentas"]
        scores = puntajes(filas, columnas, arboles=30, semilla=3)
        self.assertGreater(scores[-1], max(scores[:-1]))

    def test_bandera_apagada_no_escribe_alertas(self):
        filas = [fila(f"u{i}", 1, 0, 1) for i in range(MIN_FILAS + 2)]
        informe = decidir(filas, ["resenas", "disputas", "cuentas"], False)
        self.assertEqual(informe["modo"], "solo_reglas")

    def test_cli_rechaza_produccion(self):
        with tempfile.TemporaryDirectory() as tmp:
            entrada = Path(tmp) / "e.csv"
            entrada.write_text("user_id,resenas\na,1\n", encoding="utf-8")
            os.environ["SUPABASE_URL"] = "https://wxqrfcqifkfgawrnqmnj.supabase.co"
            with self.assertRaises(SystemExit):
                main_con(entrada, Path(tmp) / "out.json")
            os.environ.pop("SUPABASE_URL", None)


def main_con(entrada: Path, salida: Path) -> None:
    import sys

    sys.argv = ["isolation_forest.py", "--entrada", str(entrada), "--salida", str(salida)]
    main()


if __name__ == "__main__":
    unittest.main()
