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
        const { rows, errors } = await readXlsxFile(consumsFile, { schema, trim: false },);
        const consums = rows.filter((row) => {
            if (row.galones != null) {
                return row;
            }
        });
        const actualHeader = Object.keys(consums[0]);
        if (arraysAreEqual(expectedHeader, actualHeader)) {
            rows.slice(1); // Excluye la fila de cabecera
        } else {
            res.status(400).json({ error: 'La cabecera del archivo no es correcta.' });
        }
        const results = await Promise.all(consums.map(consum => {
            return new Promise((resolve, reject) => {
                consumUseCases.processConsum(consum, (err, result) => {
                    if (err) {
                        reject(err);
                    } else {
                        resolve(result);
                    }
                });
            });
        }));
        const flatResults = (results.map(result => {
            return result[0]; //
        })).map(result => {
            return result[0]; //
        });

        res.status(200).json(flatResults);




        // Ahora `cleanedRows` contiene solo las filas que no tienen valores vacíos en las columnas requeridas

    } catch (error) {
        console.log(error);
        res.status(500).json({ error: 'Error al procesar el archivo excel' })
    }

}



export const processConsum = async (req, res) => {

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

