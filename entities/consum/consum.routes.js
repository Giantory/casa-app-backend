import { Router } from 'express';

//controllers
import { getAllConsums, processConsum, processManyConsums } from './consum.controller.js';

const router = new Router();

router.get(`/api/consums`, getAllConsums);
router.post(`/api/consums/processConsum`, processConsum);
router.post(`/api/consums/processManyConsums`, processManyConsums);

export default router;