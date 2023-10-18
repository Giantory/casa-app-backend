import db from "../../config/database.js";

class DispatchUseCases {
    constructor() {
    }

    getAllDispatches(callback) {
        db.query("SELECT * FROM despacho", callback);
    }
    createDispatch(dispatch, callback) {
        db.query("INSERT INTO despacho (idOperador, fechaDespacho) VALUES (?, ?)",
            [dispatch.idOperador, dispatch.fechaDespacho],
            callback);
    }
}


export default DispatchUseCases;