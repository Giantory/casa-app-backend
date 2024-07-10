import ModelUseCases from "./model.useCases.js";

const modelUseCases = new ModelUseCases();

export const getAllModels = (req, res) => {
    modelUseCases.getAllModels((err, results) => {
        if (err) {
            console.error("Error al obtener los vehículos", err);
            res.status(500).json({ error: 'Error al obtener los vehículos' });
        } else {
            res.json(results);
        }
    });
};

export const getModelByMarcaId = (req, res) => {
    const marcaId = req.params.marcaId;
    modelUseCases.getModelByMarcaId(marcaId, (err, results) => {
        if (err) {
            console.error('Error al obtener el modelo:', err);
            res.status(500).json({ error: 'Error al obtener el modelo' });
        } else if (results.length == 0) {
            res.status(400).json({ error: 'No se encontró el modelo' });
        } else {    
            res.json(results);
        }
    });
}

