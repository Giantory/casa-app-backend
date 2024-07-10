import { Router } from 'express';

//controllers
import { getAllModels, getModelByMarcaId } from './model.controller.js';

const router = new Router();

router.get(`/api/models`, getAllModels);
router.get(`/api/models/:marcaId/`, getModelByMarcaId);


export default router;