import ConsumUseCases from "./consum.useCases.js";
import readXlsxFile from 'read-excel-file/node'


const consumUseCases = new ConsumUseCases();

const schema = {
    'placa': {
        prop: 'placa',
        type: String,
    },
    'descripcion': {
        prop: 'descripcion',
        type: String,
    },
    'horometraje': {
        prop: 'horometraje',
        type: Number,
    },
    'kilometraje': {
        prop: 'kilometraje',
        type: Number,
    },
    'galones': {
        prop: 'galones',
        type: Number,
    },
    'operador': {
        prop: 'operador',
        type: String,
    },
};



export const getAllConsums = (req, res) => {
    consumUseCases.getAllConsums((err, results) => {
        if (err) {
            console.error('Error al obtener los consumos', err);
            res.status(500).json({ error: 'Error al obtener los consumos' });
        }
        else if (results.length === 0) {
            res.status(404).json({ error: 'No se encontró ningún registro' });
        } else {
            res.json(results);
        }
    })
};

export const getConsumoByDispatchId = (req, res) => {
    const dispatchId = req.params.id;
    consumUseCases.getConsumoByDispatchId(dispatchId, (err, results) => {
        if (err) {
            console.error('Error al obtener los consumos', err);
            res.status(500).json({ error: 'Error al obtener los consumos' });
        }
        else if (results.length === 0) {
            res.status(404).json({ error: 'No se encontró ningún registro' });
        } else {
            res.json(results);
        }
    })
};


export const processManyConsums = async (req, res) => {
    const consumsFile = req.file.path;

    function arraysAreEqual(array1, array2) {
        console.log(array1, array2);
        if (array1.length !== array2.length) {
            return false;
        }
        for (let i = 0; i < array1.length; i++) {
            if (array1[i] !== array2[i]) {
                return false;
            }
        }
        return true;
    }

    try {
        const expectedHeader = Object.keys(schema);
        const { rows, errors } = await readXlsxFile(consumsFile, { schema, trim: false });
        const consums = rows.filter((row) => row.galones != null);
        const actualHeader = Object.keys(consums[0]);

        if (!arraysAreEqual(expectedHeader, actualHeader)) {
            return res.status(400).json({ error: 'La cabecera del archivo no es correcta.' });
        }

        const results = await Promise.all(consums.map(consum => {
            return new Promise((resolve, reject) => {
                consumUseCases.processConsum(consum, async (err, result) => {
                    if (err) {
                        reject(err);
                    } else {
                        if (!result || result.length === 0) {
                            // No se encontró el vehículo, agregar uno nuevo
                            const newVehicle = {
                                equipo: 'Nuevo',
                                marca: 'Desconocida',
                                galones: consum.galones,
                                modelo: 'Desconocido',
                                placa: consum.placa,
                                horometraje: consum.horometraje,
                                kilometraje: consum.kilometraje,
                                rendimiento: 0,
                                estadoCodigo: 6,
                                estadoDescripcion: 'Nuevo',
                                currentHorometraje: consum.horometraje,
                                operador: consum.operador,
                                currentKilometraje: consum.kilometraje,
                                mensaje: 'Vehículo nuevo'
                            };
                            resolve(newVehicle);
                        } else {
                            resolve(result[0]); // Devolver el resultado completo
                        }
                    }
                });
            });
        }));

        const flatResults = results.map(result => result);

        res.status(200).json(flatResults);

    } catch (error) {
        console.log(error);
        res.status(500).json({ error: 'Error al procesar el archivo excel' });
    }
}

export const processConsum = async (req, res) => {

    const consum = req.body;

    console.log(consum)

    try {
        consumUseCases.processConsum(consum, (err, results) => {
            if (err) {
                res.status(500).json({ error: 'No se pudo procesar el consumo' })
            } else {
                res.status(200).json(results[0])
            }
        });
    } catch (error) {
        console.error('Error al procesar el consumo', error);
        res.status(500).json({ error: 'Error al procesar el consumo' });
    }
}

export const addConsum = async (req, res) => {

    const consum = req.body;

    console.log(consum)

    try {
        consumUseCases.addConsum(consum, (err, results) => {
            if (err) {
                if (err.code == 'ER_SIGNAL_EXCEPTION') {
                    console.log(err)
                    return res.status(500).json({ error: 'Horómetro o kilometraje actual es igual al ingresado' })
                }
                console.log(err)
                res.status(500).json({ error: 'No se pudo procesar el consumo' })
            } else {
                res.status(200).json(results[0])
            }
        });
    } catch (error) {
        console.error('Error al procesar el consumo', error);
        res.status(500).json({ error: 'Error al procesar el consumo' });
    }
}


export const createConsum = async (req, res) => {

    const consum = req.body;

    try {
        consumUseCases.processConsum(consum, (err, results) => {
            if (err) {
                res.status(500).json({ error: 'No se pudo procesar el consumo' })
            } else {
                res.status(200).json(results[0])
            }
        });
    } catch (error) {
        console.error('Error al procesar el consumo', error);
        res.status(500).json({ error: 'Error al procesar el consumo' });
    }

}

