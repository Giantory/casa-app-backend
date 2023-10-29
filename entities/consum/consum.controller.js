import ConsumUseCases from "./consum.useCases.js";

const consumUseCases = new ConsumUseCases();

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

    const consums = req.body;

    try {
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
        const flatResults = results.map(result => {
            return result[0]; //
        });

        res.status(200).json(flatResults);
    } catch (error) {
        console.error('Error al procesar los consumos', error);
        res.status(500).json({ error: 'Error al procesar los consumos' });
    }
}

export const processConsum = async (req, res) => {

    const consum = req.body;
    console.log(consum);
    try {
        consumUseCases.processConsum(consum, (err, results) => {
            if(err){
                res.status(500).json({error: 'No se pudo procesar el consumo'})
            }else {            
                res.status(200).json(results[0])
            }
        });
    } catch (error) {
        console.error('Error al procesar el consumo', error);
        res.status(500).json({ error: 'Error al procesar el consumo' });
    }
}

