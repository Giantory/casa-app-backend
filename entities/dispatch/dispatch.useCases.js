import db from "../../config/database.js";

class DispatchUseCases {
    constructor() {
    }

    getAllDispatches(callback) {
        db.query("SELECT * FROM despacho de " +
            "INNER JOIN consumo co ON de.idDespacho = co.idDespacho " +
            "INNER JOIN operador op ON de.idOperador = op.idOperador", callback);
    }

    createDispatch(dispatch, callback) {
        db.query("INSERT INTO despacho (idOperador, fechaDespacho) VALUES (?, ?)",
            [dispatch.idOperador, dispatch.fechaDespacho],
            (err, result) => {
                if (err) {
                    return callback(err);
                }

                // Recuperar el ID del despacho recién insertado
                const insertId = result.insertId;

                // Realizar una consulta adicional para obtener el despacho completo
                db.query("SELECT * FROM despacho WHERE idDespacho = ?", [insertId], (err, rows) => {
                    if (err) {
                        return callback(err);
                    }
                    // Retornar el primer (y único) despacho encontrado
                    callback(null, rows[0]);
                });
            }
        );
    }
}

export default DispatchUseCases;
