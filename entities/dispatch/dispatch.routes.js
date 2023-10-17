import { Router } from 'express';

//controllers
import { getAllDispatches } from './dispatch.controller.js';

const router = new Router();

router.get(`/api/dispatches`, getAllDispatches);

export default router;