import db from "../../config/database.js";

class ConsumUseCases {
    constructor() {
    }
    getAllConsums(callback) {
        db.query('SELECT * FROM consumo', callback);
    }

    getConsumoByDispatchId(dispatchId, callback) {
        db.query('SELECT * FROM consumo WHERE idDespacho = ? ', [dispatchId], callback);
    }

    processConsum(consum, callback) {
        db.query('CALL procesarConsumos(?, ?, ?, ?, ?)', 
        [consum.placa, consum.horometraje, consum.kilometraje, consum.galones, consum.operador], 
        (err, results) => {
            if (err) {
                return callback(err);
            }
            // Devuelve el primer resultado
            callback(null, results[0]); 
        });
    }

    addConsum(consum, callback) {
        db.query('CALL agregarConsumo(?, ?, ?, ?, ?, ?, ?)', 
        [consum.placa, consum.operador, consum.despachador, consum.fechaDespacho, consum.horometraje, consum.kilometraje, consum.galones], 
        (err, results) => {
            if (err) {
                return callback(err);
            }
            // Devuelve el primer resultado
            callback(null, results[0]); 
        });
    }


    
    createConsum(consumos, callback) {
        const query = "INSERT INTO `consumo`(`idDespacho`, `placa`, `idEstadoConsum`, `inHorometraje`, `horometraje`, `inKilometraje`, `kilometraje`, `galones`, `nombreOperador`,`rendimiento`) VALUES ?";
        const values = consumos.map(consum => [
            consum.idDespacho,
            consum.placa,
            consum.estadoCodigo,
            consum.currentHorometraje,
            consum.horometraje,
            consum.currentKilometraje,
            consum.kilometraje,
            consum.galones,
            consum.operador,
            consum.rendimiento,
        ]);

        db.query(query, [values], (err, results) => {
            if (err) {
                return callback(err);
            }
            callback(null, results);
        });
    }


}

export default ConsumUseCases;