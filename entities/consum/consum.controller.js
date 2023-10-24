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

export const processConsums = async (req, res) => {

    const consums = req.body;

    try {
        const results = await Promise.all(consums.map(consum => {
            return new Promise((resolve, reject) => {
                consumUseCases.processConsums(consum, (err, result) => {
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
        console.error('Error al crear los consumos', error);
        res.status(500).json({ error: 'Error al crear los consumos' });
    }
}