import AnalyticUseCases from "./analytic.useCases.js";


const analyticUseCases = new AnalyticUseCases();




export const getGallonsPerMonth = (req, res) => {
    analyticUseCases.getGallonsPerMonth((err, results) => {
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
