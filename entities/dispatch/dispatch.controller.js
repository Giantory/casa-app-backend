import DispatchUseCases from "./dispatch.useCases.js";

const dispatchUseCases = new DispatchUseCases();

export const getAllDispatches = (req, res) => {
    dispatchUseCases.getAllDispatches((err, results) => {
        if (err) {
            console.error('Error al obtener los despachos', err);
            res.status(500).json({ error: 'Error al obtener los depachos' });
        } else if (results.length === 0) {
            console.error('No se encontró ningún registro');
            res.status(404).json({ error: 'No se encontró ningún registro' });

        } else {
            res.json(results);
        }
    });
}