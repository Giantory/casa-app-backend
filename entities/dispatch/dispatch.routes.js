import { Router } from 'express';

//controllers
import { getAllDispatches, createDispatch } from './dispatch.controller.js';

const router = new Router();

router.get(`/api/dispatches`, getAllDispatches);
router.post(`/api/dispatches/`, createDispatch);

export default router;