import db from "../../config/database.js";

class DispatchUseCases{
    constructor(){
    }

    getAllDispatches(callback){
        db.query("SELECT * FROM despacho", callback);
    }
}


export default DispatchUseCases;