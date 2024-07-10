import BrandUseCases from "./brand.useCases.js";

const brandUseCases = new BrandUseCases();

export const getAllBrands = (req, res) => {
    brandUseCases.getAllBrands((err, results) => {
        if (err) {
            console.error("Error al obtener las marcas", err);
            res.status(500).json({ error: 'Error al obtener las marcas' });
        } else {
            res.json(results);
        }
    });
};

export const getBrandById = (req, res) => {
    const id = req.params.id;
    brandUseCases.getBrandMyId(id, (err, results) => {
        if (err) {
            console.error('Error al obtener la marca:', err);
            res.status(500).json({ error: 'Error al obtener la marca' });
        } else if (results.length == 0) {
            res.status(400).json({ error: 'No se encontró la marca' });
        } else {
            res.json(results);
        }
    });
}

